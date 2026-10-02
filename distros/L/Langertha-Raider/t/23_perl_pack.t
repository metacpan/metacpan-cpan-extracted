use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Packs;

# The bundled perl pack (ADR 0012): detected in a Perl workspace, it requests
# the PerlTools server; perl: true / --perl keep their meaning. Offline.

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY
  GROQ_API_KEY MISTRAL_API_KEY GEMINI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

sub workspace {
  my ( %files ) = @_;
  my $root = path(tempdir(CLEANUP => 1));
  for my $rel (sort keys %files) {
    my $content = $files{$rel};
    $content = YAML::PP->new->dump_string($content) if ref $content;
    $root->child($rel)->parent->mkpath;
    $root->child($rel)->spew_utf8($content);
  }
  return $root;
}

sub app {
  my ( $root, %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => "$root",
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    %args,
  );
}

sub perl_tools_on { scalar(@{ $_[0]->_mcps }) == 4 }   # files, bash, web + perl

subtest 'the bundled pack' => sub {
  my $packs = Langertha::Raider::Packs::build_packs(root => workspace());
  my $pack = $packs->packs_by_name->{perl} or return fail('perl pack bundled');
  is($pack->exclusive_group, 'power', 'stacks on any persona');
  ok(!$pack->enabled_by_default, 'not on by default');
  is($pack->tools, ['perl'], 'requests the perl tools');
  is($pack->detect, { may => [ map { { file => $_ } } qw( cpanfile dist.ini Makefile.PL lib/**/*.pm ) ] },
    'default rule: any of cpanfile, dist.ini, Makefile.PL, lib/**/*.pm');
  ok(!$packs->is_active('perl'), 'build_packs itself detects nothing');
};

subtest 'a Perl workspace gets the Perl tools without a flag' => sub {
  for my $file ('cpanfile', 'dist.ini', 'Makefile.PL', 'lib/Foo.pm', 'lib/Foo/Bar.pm') {
    my $app = app(workspace($file => "1;\n"));
    ok($app->packs->is_active('perl'), $file.': perl pack detected');
    ok(perl_tools_on($app), $file.': PerlTools on');
  }
  my $app = app(workspace('cpanfile' => ''));
  like($app->mission, qr/### Pack: perl\n.*perl_eval/s, 'the pack tells the model about its tools');
  like([ grep { $_->{name} eq 'perl' } @{ $app->packs->activation_report } ],
    [ { source => 'detected', reason => 'may file=cpanfile (cpanfile)',
        detection => { rule_from => 'pack default' } } ], 'explained');
};

subtest 'no Perl, no Perl tools' => sub {
  my $app = app(workspace('README.md' => "# hi\n", 'lib/x.py' => ''));
  ok(!$app->packs->is_active('perl'), 'not detected');
  ok(!perl_tools_on($app), 'PerlTools off');
};

subtest 'switched off by no_detect, --no-pack, --no-detect, detect: false' => sub {
  my %perl = ( 'cpanfile' => '' );
  my %off = (
    'no_detect: [perl]'   => [ workspace(%perl, '.raider.yml' => { no_detect => ['perl'] }) ],
    'detect: perl: false' => [ workspace(%perl, '.raider.yml' => { detect => { perl => 0 } }) ],
    'detect: false'       => [ workspace(%perl, '.raider.yml' => "detect: false\n") ],
    '--no-pack perl'      => [ workspace(%perl), no_pack_names => ['perl'] ],
    '--no-detect'         => [ workspace(%perl), detect => 0 ],
  );
  for my $what (sort keys %off) {
    my ( $root, %args ) = @{ $off{$what} };
    my $app = app($root, %args);
    ok(!$app->packs->is_active('perl'), $what.': pack off');
    ok(!perl_tools_on($app), $what.': PerlTools off');
  }
};

subtest 'perl: true and --perl keep their meaning' => sub {
  my $yml = app(workspace('.raider.yml' => { perl => 1 }));
  ok(perl_tools_on($yml), 'perl: true: PerlTools on outside a Perl workspace');
  ok(!$yml->packs->is_active('perl'), 'without switching the pack on');
  ok(perl_tools_on(app(workspace(), perl => 1)), '--perl');
  ok(perl_tools_on(app(workspace(), engine_options => { perl => 1 })), '-o perl=1');
  ok(perl_tools_on(app(workspace('cpanfile' => ''), perl => 1, no_pack_names => ['perl'])),
    '--perl is its own switch, --no-pack perl only drops the pack');
};

subtest 'explicit perl: false denies the detected request' => sub {
  my $app = app(workspace('cpanfile' => '', '.raider.yml' => { perl => 0 }));
  ok($app->packs->is_active('perl'), 'pack detected');
  ok(!perl_tools_on($app), 'perl: false keeps PerlTools off');
  ok(!perl_tools_on(app(workspace('cpanfile' => ''), engine_options => { perl => 0 })), '-o perl=0 too');
};

subtest '--pack perl requests the tools as well' => sub {
  my $app = app(workspace(), pack_names => ['perl']);
  ok($app->packs->is_active('perl'), 'pack on');
  ok(perl_tools_on($app), 'PerlTools on');
  is($app->packs->requested_tools, ['perl'], 'collected from the active packs');
  is(app(workspace())->packs->requested_tools, [], 'nothing requested otherwise');
};

subtest 'explain says whether the Perl tools are on, and why' => sub {
  my %case = (
    'detected pack' => [ [ workspace('cpanfile' => '') ],                          1, 'pack perl (detected)' ],
    '--pack perl'   => [ [ workspace(), pack_names => ['perl'] ],                  1, 'pack perl (flag)' ],
    '--perl'        => [ [ workspace(), perl => 1 ],                               1, '--perl' ],
    'perl: true'    => [ [ workspace('.raider.yml' => { perl => 1 }) ],            1, 'perl: true (.raider.yml)' ],
    'perl: false'   => [ [ workspace('cpanfile' => '', '.raider.yml' => { perl => 0 }) ], 0, 'perl: false (.raider.yml)' ],
    '-o perl=0'     => [ [ workspace('cpanfile' => ''), engine_options => { perl => 0 } ], 0, 'perl: false (-o)' ],
    'nothing'       => [ [ workspace() ],                                          0, 'not requested' ],
  );
  for my $what (sort keys %case) {
    my ( $args, $enabled, $reason ) = @{ $case{$what} };
    my $app = app(@$args);
    is($app->explain_config->{perl_tools}, { enabled => $enabled, reason => $reason }, $what);
    is($app->perl_tools_enabled, $enabled, $what.': matches perl_tools_enabled');
  }

  my $buf = '';
  open my $fh, '>', \$buf or die $!;
  Langertha::Raider::CLI::Output->new(out => $fh, color => 0)
    ->config_report(app(workspace('dist.ini' => ''))->explain_config);
  close $fh;
  like($buf, qr/^perl tools: on  \(pack perl \(detected\)\)$/m, 'printed by config explain');
};

done_testing;

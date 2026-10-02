use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Config;

# ADR 0012 wiring: detection rules from pack defaults and .raider.yml,
# --no-pack / --no-detect, precedence flag > config > detected, exclusive
# groups, /reload, `raider config explain` and /packs. No live API calls.

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY
  GROQ_API_KEY MISTRAL_API_KEY GEMINI_API_KEY ANSI_COLORS_DISABLED RAIDER_HALL_SOCKET )};

# Test packs next to the bundled ones: a power pack detecting Cargo.toml and
# a persona pack detecting FORMAL.
my $pack_dir = path(tempdir(CLEANUP => 1));
my %PACKS = (
  'det-rust'   => "detect:\n  must: [ { file: Cargo.toml } ]\n",
  'det-formal' => "exclusive_group: persona\ndetect:\n  must: [ { file: FORMAL } ]\n",
  'det-plain'  => "exclusive_group: power\n",
);
for my $name (sort keys %PACKS) {
  $pack_dir->child($name)->mkpath;
  $pack_dir->child($name, 'pack.yml')->spew_utf8($PACKS{$name});
  $pack_dir->child($name, 'SKILL.md')->spew_utf8('Skill of '.$name."\n");
}
$ENV{RAIDER_PACK_DIRS} = "$pack_dir";

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

sub entry {
  my ( $packs, $name ) = @_;
  my ( $hit ) = grep { $_->{name} eq $name } @$packs;
  return $hit;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t } );
}

subtest 'Config: detect and no_detect' => sub {
  my $c = Langertha::Raider::Config->new(root => "".workspace('.raider.yml' => {
    detect    => { 'det-rust' => { must => [ { file => 'x' } ] }, 'git-guru' => 0 },
    no_detect => ['det-formal'],
    temperature => 0.2,
  }));
  is($c->detect_settings('openai'), {
    enabled => 1,
    rules   => { 'det-rust' => { must => [ { file => 'x' } ] } },
    off     => { 'git-guru' => 'detect: git-guru: false', 'det-formal' => 'no_detect' },
  }, 'rules, per-pack false and no_detect');
  is($c->engine_options('openai'), { temperature => 0.2 }, 'detect keys never reach the engine');
  is($c->explain('openai')->{ignored}, [], 'detect: is not taken for an engine section');
  ok($c->is_app_key($_), $_.' is raider\'s own key') for qw( detect no_detect );

  is(Langertha::Raider::Config->new(root => "".workspace())->detect_settings('openai'),
    { enabled => 1, rules => {}, off => {} }, 'nothing configured');
  is(Langertha::Raider::Config->new(root => "".workspace('.raider.yml' => "detect: false\n"))
    ->detect_settings('openai')->{enabled}, 0, 'detect: false turns detection off');
  is(Langertha::Raider::Config->new(root => "".workspace('.raider.yml' => { default => { no_detect => 'a,b' } }))
    ->detect_settings('openai')->{off}, { a => 'no_detect', b => 'no_detect' }, 'no_detect in default:, comma list');

  my @bad = (
    [ { detect => [ 'x' ] },                            qr/detect: must be a map of pack name to rule, or false/ ],
    [ { detect => { perl => 'yes' } },                  qr/detect\.perl: must be a rule or false/ ],
    [ { detect => { perl => { must => [ { fiel => 'x' } ] } } }, qr/Invalid detect rule detect\.perl\.must\[0\]: unknown key 'fiel'/ ],
    [ { no_detect => [ [ 'a' ] ] },                     qr/no_detect: must be a list of pack names/ ],
  );
  for my $case (@bad) {
    my ( $yml, $re ) = @$case;
    like(dies { Langertha::Raider::Config->new(root => "".workspace('.raider.yml' => $yml))->detect_settings('openai') },
      $re, 'error: '.$re);
  }
  like(dies { $c->normalize_detect(undef, { a => 1 }) }, qr/no_detect: must be a list of pack names/,
    'no_detect as a map');
};

subtest 'a pack default rule activates the pack' => sub {
  my $hit = app(workspace('Cargo.toml' => ''));
  ok($hit->packs->is_active('det-rust'), 'detected');
  ok($hit->packs->is_active('caveman'), 'detected packs add up with the defaults');
  like(entry($hit->packs->activation_report, 'det-rust'), {
    active => 1, source => 'detected', reason => 'must file=Cargo.toml (Cargo.toml)',
    detection => { rule_from => 'pack default', result => 'matched' },
  }, 'source and matching clause');
  like($hit->mission, qr/Skill of det-rust/, 'its skill text reaches the mission');

  my $miss = app(workspace());
  ok(!$miss->packs->is_active('det-rust'), 'not detected without Cargo.toml');
  like(entry($miss->packs->activation_report, 'det-rust'), {
    active => 0, detection => { result => 'not matched', reason => 'must file=Cargo.toml: no match' },
  }, 'the failing clause is reported');
  is(entry($miss->packs->activation_report, 'det-plain'), undef, 'a pack without rule and inactive is not listed');
};

subtest '.raider.yml detect: overrides and adds rules' => sub {
  my $ws = workspace('Cargo.toml' => '', 'GUIDE' => '', '.raider.yml' => {
    detect => {
      'det-rust' => { must => [ { file => 'Nope.toml' } ] },
      'git-guru' => { must => [ { file => 'GUIDE' } ] },
      'no-such'  => { must => [ { file => 'GUIDE' } ] },
    },
  });
  my $app = app($ws);
  ok(!$app->packs->is_active('det-rust'), 'the project rule replaces the pack default');
  like(entry($app->packs->activation_report, 'det-rust'), { detection => { rule_from => '.raider.yml detect:' } },
    'rule origin');
  ok($app->packs->is_active('git-guru'), 'a rule for a pack without default');
  like(entry($app->packs->activation_report, 'no-such'), { active => 0,
    detection => { result => 'skipped', reason => 'unknown pack' } }, 'rule for an unknown pack is reported');
};

subtest 'switching detection off' => sub {
  my %cargo = ( 'Cargo.toml' => '' );
  ok(!app(workspace(%cargo), detect => 0)->packs->is_active('det-rust'), '--no-detect');
  ok(!app(workspace(%cargo, '.raider.yml' => "detect: false\n"))->packs->is_active('det-rust'), 'detect: false');
  ok(app(workspace(%cargo, '.raider.yml' => "detect: false\n"), detect => 1)->packs->is_active('det-rust'),
    '--detect beats detect: false');
  ok(!app(workspace(%cargo), engine_options => { detect => 0 })->packs->is_active('det-rust'), '-o detect=false');

  my $no = app(workspace(%cargo, '.raider.yml' => { no_detect => ['det-rust'] }));
  ok(!$no->packs->is_active('det-rust'), 'no_detect');
  like(entry($no->packs->activation_report, 'det-rust'),
    { active => 0, detection => { result => 'skipped', reason => 'no_detect' } }, 'reported as skipped');
  ok(!app(workspace(%cargo, '.raider.yml' => { detect => { 'det-rust' => 0 } }))->packs->is_active('det-rust'),
    'detect: { NAME: false }');
  ok(!app(workspace(%cargo), engine_options => { no_detect => 'det-rust' })->packs->is_active('det-rust'),
    '-o no_detect=NAME');
};

subtest '--no-pack wins over everything' => sub {
  my $app = app(workspace('Cargo.toml' => '', '.raider.yml' => { packs => ['git-guru'] }),
    no_pack_names => [ 'det-rust', 'git-guru', 'caveman' ]);
  ok(!$app->packs->is_active($_), $_.' off') for qw( det-rust git-guru caveman );
  like(entry($app->packs->activation_report, 'det-rust'), { active => 0, source => 'flag', reason => '--no-pack' },
    'reported');
  ok(!app(workspace(), pack_names => ['polite'], no_pack_names => ['polite'])->packs->is_active('polite'),
    '--no-pack beats --pack');
};

subtest 'explicit packs and detection' => sub {
  my $ws = workspace('Cargo.toml' => '', 'FORMAL' => '');
  my $flag = app($ws, pack_names => ['polite']);
  ok($flag->packs->is_active('polite'), '--pack stays');
  ok(!$flag->packs->is_active('det-formal'), 'an explicit pack wins over a detected one in its group');
  like(entry($flag->packs->activation_report, 'det-formal'), { active => 0,
    detection => { result => 'skipped', reason => 'explicit polite holds exclusive group persona' } }, 'why');
  ok($flag->packs->is_active('det-rust'), 'power packs still add up');
  like(entry($flag->packs->activation_report, 'polite'), { source => 'flag', reason => '--pack' }, 'flag source');

  my $config = app(workspace('FORMAL' => '', '.raider.yml' => { packs => ['teacher'] }));
  ok($config->packs->is_active('teacher') && !$config->packs->is_active('det-formal'), 'packs: in the config wins too');
  like(entry($config->packs->activation_report, 'teacher'), { source => 'config', reason => '.raider.yml packs:' },
    'config source');

  my $default = app(workspace('FORMAL' => ''));
  ok($default->packs->is_active('det-formal'), 'a detected persona replaces the bundled default one');
  ok(!$default->packs->is_active('caveman'), 'caveman made way');

  my $opt = app($ws, engine_options => { packs => 'polite' });
  like(entry($opt->packs->activation_report, 'polite'), { source => 'flag', reason => '-o packs' }, '-o packs=');
};

subtest 'invalid rules stop the start' => sub {
  my $bad = path(tempdir(CLEANUP => 1));
  $bad->child('det-broken')->mkpath;
  $bad->child('det-broken', 'pack.yml')->spew_utf8("detect:\n  must: [ { dir: '../x' } ]\n");
  local $ENV{RAIDER_PACK_DIRS} = "$pack_dir:$bad";
  like(dies { app(workspace())->packs }, qr/Invalid detect rule .*det-broken\/pack\.yml detect\.must\[0\]: dir must not contain '\.\.'/,
    'a broken pack default names the pack file');

  my $ws = workspace('.raider.yml' => { detect => { x => { must => {} } } });
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  my $exit = Langertha::Raider::CLI::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0), err => $err,
  )->run('config', 'explain', '-r', "$ws", '-e', 'openai');
  is($exit, 3, 'a broken detect: in .raider.yml is a configuration error');
  like($read_err->(), qr/Invalid detect rule detect\.x\.must: must be a list of conditions/, 'with location');
};

subtest '/reload re-runs detection' => sub {
  my $ws = workspace();
  my $app = app($ws);
  my ( $fh, $read ) = buffer();
  my $cmds = Langertha::Raider::CLI::Commands->new(app => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0));
  $app->raider;
  $cmds->dispatch('/pack on git-guru');
  ok(!$app->packs->is_active('det-rust'), 'nothing detected at start');
  $read->();

  $ws->child('Cargo.toml')->spew_utf8('');
  $cmds->dispatch('/reload');
  ok($app->packs->is_active('det-rust'), 'detected after /reload');
  like($app->raider->mission, qr/Skill of det-rust/, 'mission follows');
  like($read->(), qr/^detected packs: det-rust$/m, '/reload says what it detected');
  ok($app->packs->is_active('git-guru'), 'a pack switched on by hand stays');

  $ws->child('Cargo.toml')->remove;
  $cmds->dispatch('/reload');
  ok(!$app->packs->is_active('det-rust'), 'gone after the file went');
  ok($app->packs->is_active('git-guru'), 'manual pack still there');
};

subtest 'raider config explain and /packs show source and clause' => sub {
  my $ws = workspace('Cargo.toml' => '', '.raider.yml' => { packs => ['caveman', 'git-guru'] });
  my $app = app($ws, no_pack_names => ['testing-fu'], detect => 1);
  my $report = $app->explain_config;
  is($report->{detection}, 'on', 'detection state');
  like(entry($report->{packs}, 'det-rust'), { source => 'detected', reason => 'must file=Cargo.toml (Cargo.toml)' },
    'detected pack in the report');
  like(entry($report->{packs}, 'git-guru'), { source => 'config' }, 'config pack in the report');
  like([ grep { $_->{key} eq 'detect' } @{ $report->{values} } ], [ { source => '--detect', value => 1 } ],
    'the flag is a source');

  my ( $fh, $read ) = buffer();
  my $out = Langertha::Raider::CLI::Output->new(out => $fh, color => 0);
  $out->config_report($report);
  my $text = $read->();
  like($text, qr/^packs:  \(detection on\)$/m, 'packs section');
  like($text, qr/^  det-rust\s+active\s+env\s+detected: must file=Cargo\.toml \(Cargo\.toml\) \[rule: pack default\]$/m,
    'detected line');
  like($text, qr/^  git-guru\s+active\s+shipped\s+config: \.raider\.yml packs:$/m, 'config line');
  like($text, qr/^  det-formal\s+inactive\s+env\s+not matched: must file=FORMAL: no match \[rule: pack default\]$/m,
    'not detected line');

  like(app($ws, detect => 0)->explain_config->{detection}, 'off (--no-detect)', 'off by flag');
  like(app(workspace('.raider.yml' => "detect: false\n"))->explain_config->{detection}, 'off (detect: false)',
    'off by config');

  my $cmds = Langertha::Raider::CLI::Commands->new(app => $app, output => $out);
  $cmds->dispatch('/packs');
  my $packs = $read->();
  like($packs, qr/^  \* det-rust \(power\) detected: must file=Cargo\.toml \(Cargo\.toml\)$/m, '/packs detected');
  like($packs, qr/^  \* git-guru \(power\) config: \.raider\.yml packs:$/m, '/packs config');
  like($packs, qr/^    det-formal \(persona\) not matched: must file=FORMAL: no match$/m, '/packs not matched');
  like($packs, qr/^    testing-fu \(power\) flag: --no-pack$/m, '/packs --no-pack');
};

subtest 'command line: --no-pack and --no-detect' => sub {
  my $main = Langertha::Raider::CLI::Main->new;
  my ( $opt ) = $main->parse_options('--no-pack', 'a', '--no-pack', 'b', '--no-detect');
  my %args = $main->app_args($opt);
  is($args{no_pack_names}, [ 'a', 'b' ], '--no-pack repeatable');
  is($args{detect}, 0, '--no-detect');
  ( $opt ) = $main->parse_options();
  %args = $main->app_args($opt);
  ok(!exists $args{no_pack_names} && !exists $args{detect}, 'nothing when not given');
  like($main->usage, qr/--no-pack NAME/, 'usage names --no-pack');
  like($main->usage, qr/--no-detect/, 'usage names --no-detect');
};

done_testing;

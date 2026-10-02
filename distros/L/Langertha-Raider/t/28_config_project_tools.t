#!/usr/bin/env perl
# ABSTRACT: project_tools in ~/.raider/config.yml, parsed and shown in config explain only (ADR 0011, k129)

use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::Config;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;

clear_engine_env();

# project_tools maps a workspace selector ("*", a path glob, a workspace
# name) to tool names. Only the top level of the home file grants; the
# selectors are matched against the real path of the root; explain shows
# what is granted and requested. Nothing is mounted from it.

sub yaml { ref $_[0] ? YAML::PP->new->dump_string($_[0]) : $_[0] }

# A fresh home with ~/.raider/config.yml (unless undef); HOME points at it.
sub home {
  my ( $content ) = @_;
  my $home = path(tempdir(CLEANUP => 1))->realpath;
  if (defined $content) {
    $home->child('.raider')->mkpath;
    $home->child('.raider', 'config.yml')->spew_utf8(yaml($content));
  }
  $ENV{HOME} = "$home";
  return $home;
}

# A project directory under $parent (default: a fresh temp dir).
sub project {
  my ( %arg ) = @_;
  my $root = defined $arg{in}
    ? $arg{in}->child($arg{name} // 'proj')
    : path(tempdir(CLEANUP => 1))->realpath->child('proj');
  $root->mkpath;
  if (defined $arg{config}) {
    $root->child('.raider')->mkpath;
    $root->child('.raider', 'config.yml')->spew_utf8(yaml($arg{config}));
  }
  $root->child($_)->spew_utf8("x\n") for @{ $arg{touch} // [] };
  return $root;
}

sub config { Langertha::Raider::Config->new(root => "$_[0]") }

sub app { Langertha::Raider::CLI->new(root => "$_[0]", engine => 'openai', api_key => 'test', @_[1 .. $#_]) }

sub matches {
  my ( $root ) = @_;
  return { map { $_->{selector} => $_ } @{ config($root)->project_tools_matches } };
}

sub tool_entry {
  my ( $report, $name ) = @_;
  my ( $hit ) = grep { $_->{name} eq $name } @{ $report->{project_tools}{tools} };
  return $hit;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

sub run_cli {
  my ( @args ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = Langertha::Raider::CLI::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
  )->run(@args);
  return ( $exit, $read_out->(), $read_err->() );
}

subtest 'no project_tools: nothing to report' => sub {
  home({ model => 'm' });
  my $root = project();
  my $config = config($root);
  is($config->project_tools, [], 'no entries');
  ok(!exists $config->explain('openai')->{project_tools}, 'config explain has no project_tools');
  ok(!exists app($root)->explain_config->{project_tools}, 'explain_config neither');
};

subtest '"*" matches every project' => sub {
  home({ project_tools => { '*' => [ 'telegram' ] } });
  my $m = matches(project());
  is($m->{'*'}, { selector => '*', kind => 'all', tools => [ 'telegram' ], matched => 1,
    reason => '* matches every project' }, '* matched');
};

subtest 'path globs against the real path of the root' => sub {
  my $home = home({});
  my $dev  = $home->child('dev');
  my $root = project(in => $dev, name => 'app');
  $home->child('.raider', 'config.yml')->spew_utf8(yaml({ project_tools => {
    '~/dev/*'            => [ 'a' ],
    '~/dev/**'           => [ 'b' ],
    '~/dev'              => [ 'c' ],
    '~/dev/app/'         => [ 'd' ],
    '~/dev/a?p'          => [ 'e' ],
    '~/*'                => [ 'f' ],
    '~/other/**'         => [ 'g' ],
    "$dev/*"             => [ 'h' ],
    '/**'                => [ 'i' ],
    '~/dev/[a]pp'        => [ 'j' ],
  } }));
  my $m = matches($root);
  is($m->{'~/dev/*'}{kind}, 'path', 'a path glob');
  ok($m->{$_}{matched}, $_.' matches') for '~/dev/*', '~/dev/**', '~/dev/app/', '~/dev/a?p', "$dev/*", '/**';
  ok(!$m->{$_}{matched}, $_.' does not match') for '~/dev', '~/*', '~/other/**', '~/dev/[a]pp';
  is($m->{'~/dev/*'}{reason}, 'matches '.$root, 'reason names the root');
  like($m->{'~/other/**'}{reason}, qr/^\Q$home\E\/other\/\*\* does not match \Q$root\E$/, 'non-match names the expanded glob');

  my $deep = project(in => $dev->child('app'), name => 'sub');
  my $d = matches($deep);
  ok(!$d->{'~/dev/*'}{matched}, '* does not cross /');
  ok($d->{'~/dev/**'}{matched}, '** does');

  # A symlink on the way: the root and the glob's literal part are both
  # compared by real path.
  my $link = $home->child('link');
  ok(symlink("$dev", "$link"), 'symlink');
  my $via = matches($link->child('app'));
  ok($via->{'~/dev/*'}{matched}, 'root through a symlink still matches ~/dev/*');
  $home->child('.raider', 'config.yml')->spew_utf8(yaml({ project_tools => { '~/link/*' => [ 'k' ] } }));
  ok(matches($root)->{'~/link/*'}{matched}, 'a glob through a symlink matches the real root');
};

subtest 'workspace names are accepted but not matched yet' => sub {
  home({ project_tools => { mybox => [ 'hall_status' ], '*' => [] } });
  my $m = matches(project());
  is($m->{mybox}, { selector => 'mybox', kind => 'workspace', tools => [ 'hall_status' ], matched => 0,
    reason => 'workspace names are not supported yet' }, 'shown unsupported');
  my $t = tool_entry(app(project())->explain_config, 'hall_status');
  is($t->{granted_by}, [], 'not granted');
};

subtest 'matching entries add up' => sub {
  my $home = home({});
  my $root = project(in => $home->child('dev'));
  $home->child('.raider', 'config.yml')->spew_utf8(yaml({ project_tools => {
    '*'          => [ 'telegram' ],
    '~/dev/*'    => [ 'telegram', 'web_fetch' ],
    '~/dev/**'   => 'bash, web_fetch',
    '~/nope/*'   => [ 'perl' ],
  } }));
  my $report = app($root)->explain_config;
  is(tool_entry($report, 'telegram')->{granted_by}, [ '*', '~/dev/*' ], 'telegram by both');
  is(tool_entry($report, 'web_fetch')->{granted_by}, [ '~/dev/*', '~/dev/**' ], 'comma string counts');
  is(tool_entry($report, 'bash')->{granted_by}, [ '~/dev/**' ], 'bash');
  is(tool_entry($report, 'perl')->{granted_by}, [], 'a non-matching selector grants nothing');
  is([ map { $_->{name} } @{ $report->{project_tools}{tools} } ], [qw( bash perl telegram web_fetch )], 'one entry per name');
  is($report->{project_tools}{label}, 'home', 'read from the home file');
  is($report->{project_tools}{file}, $home->child('.raider', 'config.yml')->stringify, 'its path');
};

subtest 'requested by packs, and whether raider knows the name' => sub {
  home({ project_tools => { '*' => [ 'telegram', 'bash', 'frobnicate' ] } });
  my $root = project(touch => [ 'cpanfile' ]);
  my $report = app($root)->explain_config;
  is(tool_entry($report, 'perl'), { name => 'perl', granted_by => [], requested_by => [ 'pack perl' ], known => 'tool group' },
    'the perl pack requests perl, project_tools does not grant it');
  is(tool_entry($report, 'bash'), { name => 'bash', granted_by => [ '*' ], requested_by => [], known => 'tool' }, 'bash');
  is(tool_entry($report, 'frobnicate')->{known}, undef, 'an unknown name is shown, not an error');
  is(tool_entry($report, 'telegram')->{known}, undef, 'telegram is no tool name raider knows (yet)');
};

subtest 'a project file cannot grant' => sub {
  home({ model => 'm' });
  my $root = project(config => { project_tools => { '*' => [ 'bash' ] }, default => { project_tools => { '*' => [ 'x' ] } } });
  my $config = config($root);
  is($config->project_tools, [], 'not read');
  my $report = $config->explain('openai');
  ok(!exists $report->{project_tools}, 'no project_tools report');
  is([ grep { $_->{key} =~ /project_tools/ } @{ $report->{ignored} } ], [
    { key => 'project_tools', reason => 'only ~/.raider/config.yml grants tools to projects; a project file cannot' },
    { key => 'default.project_tools', reason => 'read only at the top level of ~/.raider/config.yml' },
  ], 'reported as ignored');
  ok(!grep({ $_->{key} eq 'project_tools' } @{ $report->{values} }), 'not a value');
  ok(!exists $config->engine_options('openai')->{project_tools}, 'never reaches the engine');

  home({ project_tools => { '*' => [ 'a' ] }, default => { project_tools => { '*' => [ 'b' ] } } });
  my $both = config($root)->explain('openai');
  is($both->{project_tools}{selectors}[0]{tools}, [ 'a' ], 'the home grant is read');
  ok(grep({ $_->{key} eq 'home default.project_tools' } @{ $both->{ignored} }), 'a home section is ignored');
  ok(grep({ $_->{key} eq 'project_tools' } @{ $both->{ignored} }), 'the project one still is');

  my ( $exit, $out ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace',
    '-o', 'project_tools=bash', 'config', 'explain');
  is($exit, 0, 'exit 0');
  like($out, qr/^  ignored project_tools: only ~\/\.raider\/config\.yml grants tools to projects; a project file cannot$/m,
    'the project file is reported');
  like($out, qr/^  ignored -o project_tools: only ~\/\.raider\/config\.yml grants tools to projects$/m, '-o is reported');
  unlike($out, qr/^  project_tools\s/m, 'no value line');
};

subtest 'run in the home itself: the home file grants' => sub {
  my $home = home({ project_tools => { '*' => [ 'bash' ] } });
  my $config = config($home);
  ok(!$config->uses_home, 'the one file is the project file');
  is($config->project_tools, [ { selector => '*', kind => 'all', tools => [ 'bash' ] } ], 'and it grants');
  my $report = $config->explain('openai');
  is($report->{project_tools}{label}, '.raider/config.yml', 'labelled as the file in use');
  ok(!grep({ $_->{key} =~ /project_tools/ } @{ $report->{ignored} }), 'not ignored');
};

subtest 'an invalid project_tools fails loud' => sub {
  my $root = project();
  for my $case (
    [ [ 'bash' ],                   qr/^Invalid project_tools setting project_tools: must be a map/, 'not a map' ],
    [ 'bash',                       qr/^Invalid project_tools setting project_tools: must be a map/, 'a string' ],
    [ { '*' => { a => 1 } },        qr/^Invalid project_tools setting project_tools\.\*: must be a list of tool names/, 'a map of names' ],
    [ { '*' => [ [ 'a' ] ] },       qr/^Invalid project_tools setting project_tools\.\*: must be a list of tool names/, 'a nested list' ],
    [ { '*' => [ '' ] },            qr/^Invalid project_tools setting project_tools\.\*: must be a list of tool names/, 'an empty name' ],
    [ { '~bob/x' => [ 'a' ] },      qr/^Invalid project_tools setting project_tools\.~bob\/x: ~user is not supported/, '~user' ],
    [ { 'dev/*' => [ 'a' ] },       qr/^Invalid project_tools setting project_tools\.dev\/\*: a path glob must be absolute/, 'relative path' ],
    [ { 'app*' => [ 'a' ] },        qr/^Invalid project_tools setting project_tools\.app\*: a workspace name cannot hold/, 'wildcard name' ],
  ) {
    my ( $value, $re, $what ) = @$case;
    home({ project_tools => $value });
    like(dies { config($root)->project_tools }, $re, $what);
  }

  home({ project_tools => { '*' => { a => 1 } } });
  my ( $exit, $out, $err ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 3, 'raider stops with exit 3');
  is($err, "Invalid project_tools setting project_tools.*: must be a list of tool names\n", 'one clean line');

  my $proj = project(config => { project_tools => 'nonsense' });
  home({});
  ok(lives { config($proj)->explain('openai') }, 'an ignored project value is not validated');
};

subtest 'mounting is unchanged' => sub {
  my %cases = (
    'Perl workspace'     => [ 'cpanfile' ],
    'non-Perl workspace' => [],
  );
  for my $what (sort keys %cases) {
    home({});
    my $root = project(touch => $cases{$what});
    my $without = app($root);
    my @tools   = map { $_->{name} } @{ $without->explain_config->{tools} };
    my $grant   = $without->perl_tools_grant;

    home({ project_tools => { '*' => [ qw( perl telegram hall_status bash ) ] } });
    my $with = app($root);
    is([ map { $_->{name} } @{ $with->explain_config->{tools} } ], \@tools, $what.': same tools mounted');
    is($with->perl_tools_grant, $grant, $what.': same perl grant');
    ok(exists $with->explain_config->{project_tools}, $what.': while project_tools is reported');
  }
};

subtest 'config explain prints the section' => sub {
  my $home = home({ project_tools => { '*' => [ 'bash' ], mybox => [ 'telegram' ] } });
  my $root = project();
  my ( $exit, $out ) = run_cli('-r', "$root", '-e', 'openai', '-k', 'test', '--no-trace', 'config', 'explain');
  is($exit, 0, 'exit 0');
  like($out, qr/^project tools: home  \(granted by project_tools: information only, nothing is mounted by it\)$/m, 'heading');
  like($out, qr/^    \*\s+matched\s+\* matches every project; bash$/m, '* line');
  like($out, qr/^    mybox\s+not matched\s+workspace names are not supported yet; telegram$/m, 'workspace line');
  like($out, qr/^    bash\s+granted by \*  \(not requested; tool\)$/m, 'granted tool');
  like($out, qr/^    telegram\s+not granted  \(not requested; unknown\)$/m, 'unknown, not granted');
};

done_testing;

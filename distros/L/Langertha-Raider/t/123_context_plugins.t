#!/usr/bin/env perl
# ABSTRACT: Installed and enabled Claude Code plugins and their skill dirs (ADR 0019 §4, k151)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Context::Plugins;

# The briefing-preload logic: installed_plugins.json is the index, a plugin
# counts only when enabled, project installs only inside their projectPath
# (deeper first), name from the manifest else the key before '@', skill dirs
# from skills/ plus the manifest's skills paths, never outside the root.
# HOME and CLAUDE_CONFIG_DIR point at temp dirs.

my $home = path(tempdir(CLEANUP => 1));
local $ENV{HOME} = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = '';
my $claude = $home->child('.claude');

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }

sub skill { my ( $dir ) = @_; path($dir)->mkpath; path($dir)->child('SKILL.md')->spew_utf8("---\nname: x\n---\nbody\n") }

my $cache = $claude->child('plugins/cache');
my $work  = path(tempdir(CLEANUP => 1));
my $proj  = $work->child('proj');
my $deep  = $proj->child('sub/deeper');
$deep->mkpath;
my $other = $work->child('other');
$other->mkpath;

# user-scoped, manifest with a name and extra skills paths (one escaping)
my $alpha = $cache->child('m/alpha/1.0');
skill($alpha->child('skills/one'));
skill($alpha->child('skills/two'));
$alpha->child('skills/not-a-skill')->mkpath;
skill($alpha->child('extra/three'));
skill($alpha->child('single'));
skill($alpha->parent->child(q(outside/evil)));
spew_json($alpha->child('.claude-plugin/plugin.json'), {
  name   => 'alpha-renamed',
  skills => [ './extra', 'single', '../outside', '../outside/evil', "$alpha/../outside/evil", './skills', { odd => 1 } ],
});

# user-scoped, no manifest, a string skills path is irrelevant here
my $beta = $cache->child('m/beta/abc123');
skill($beta->child('skills/b1'));

# project-scoped for $proj, and one for $proj/sub/deeper, one for $other
my $gamma = $cache->child('m/gamma/2.0');
skill($gamma->child('skills/g1'));
spew_json($gamma->child('.claude-plugin/plugin.json'), { name => 'gamma', skills => 'single-only' });
skill($gamma->child('single-only'));
my $delta = $cache->child('m/delta/1.0');
skill($delta->child('skills/d1'));
my $eps = $cache->child('m/eps/1.0');
skill($eps->child('skills/e1'));

# installed but disabled / not mentioned
my $off = $cache->child('m/off/1.0');
skill($off->child('skills/o1'));
my $silent = $cache->child('m/silent/1.0');
skill($silent->child('skills/s1'));

spew_json($claude->child('plugins/installed_plugins.json'), {
  version => 2,
  plugins => {
    'alpha@m'  => [ { scope => 'user', installPath => "$alpha", version => '1.0' } ],
    'beta@m'   => [ { scope => 'user', installPath => "$beta",  version => 'abc123' } ],
    'gamma@m'  => [ { scope => 'project', installPath => "$gamma", projectPath => "$proj" } ],
    'delta@m'  => [ { scope => 'local',   installPath => "$delta", projectPath => "$deep/" } ],
    'eps@m'    => [ { scope => 'project', installPath => "$eps",   projectPath => "$other" } ],
    'off@m'    => [ { scope => 'user', installPath => "$off" } ],
    'silent@m' => [ { scope => 'user', installPath => "$silent" } ],
    'broken@m' => [ 'nope', { scope => 'user' }, { installPath => [ 'x' ] } ],
  },
});

my %enabled = (
  'alpha@m' => 1, 'beta@m' => 1, 'gamma@m' => 1, 'delta@m' => 1, 'eps@m' => 1,
  'off@m' => 0, 'broken@m' => 1,
);

sub plugins { Langertha::Raider::Context::Plugins->new(enabled => \%enabled, @_) }

subtest 'claude_home default' => sub {
  is(plugins(cwd => "$proj")->claude_home, "$claude", '~/.claude');
  local $ENV{CLAUDE_CONFIG_DIR} = "$work/cfg";
  is(plugins(cwd => "$proj")->claude_home, "$work/cfg", 'CLAUDE_CONFIG_DIR');
  is(plugins(cwd => "$proj")->plugins, [], 'no index there: no plugins');
};

subtest 'in the deep project dir: both project installs, deeper first, users last' => sub {
  my $list = plugins(cwd => "$deep")->plugins;
  is([ map { $_->{key} } @$list ], [qw( delta@m gamma@m alpha@m beta@m )], 'order');
  is([ map { $_->{scope} } @$list ], [qw( project project user user )], 'scope from projectPath');
  is([ map { $_->{name} } @$list ], [qw( delta gamma alpha-renamed beta )], 'manifest name, else key before @');
  is($list->[2]{root}, "$alpha", 'root is the install path');
  is($list->[2]{manifest}{name}, 'alpha-renamed', 'manifest kept');
  is($list->[0]{manifest}, {}, 'no manifest: {}');
};

subtest 'in the project root: deeper projectPath does not count' => sub {
  is([ map { $_->{key} } @{ plugins(cwd => "$proj")->plugins } ], [qw( gamma@m alpha@m beta@m )], 'delta and eps out');
};

subtest 'a sibling with a common prefix is not within' => sub {
  my $sib = $work->child('proj-other');
  $sib->mkpath;
  is([ map { $_->{key} } @{ plugins(cwd => "$sib")->plugins } ], [qw( alpha@m beta@m )], 'proj is no prefix of proj-other');
  is([ map { $_->{key} } @{ plugins(cwd => "$proj/sub/../../other")->plugins } ], [qw( eps@m alpha@m beta@m )],
    '.. in cwd resolved lexically');
};

subtest 'a key installed at user and project scope: one install, the first' => sub {
  # Claude Code loads one install per plugin; the project install inside
  # its projectPath comes first, the user install only elsewhere.
  my $h = $work->child('twice-home');
  my $user_root = $h->child('plugins/cache/m/twice/1.0');
  my $proj_root = $h->child('plugins/cache/m/twice/2.0');
  skill($_->child('skills/t1')) for $user_root, $proj_root;
  spew_json($h->child('plugins/installed_plugins.json'), { version => 2, plugins => {
    'twice@m' => [
      { scope => 'user',    installPath => "$user_root" },
      { scope => 'project', installPath => "$proj_root", projectPath => "$proj" },
      { scope => 'local',   installPath => "$user_root", projectPath => "$deep" },
    ],
  } });
  my %on = ( 'twice@m' => 1 );
  my $in = Langertha::Raider::Context::Plugins->new(cwd => "$deep", claude_home => "$h", enabled => \%on)->plugins;
  is([ map { [ $_->{key}, $_->{scope}, $_->{root} ] } @$in ], [ [ 'twice@m', 'project', "$user_root" ] ],
    'in the deepest project: only its install');
  my $mid = Langertha::Raider::Context::Plugins->new(cwd => "$proj", claude_home => "$h", enabled => \%on)->plugins;
  is([ map { [ $_->{scope}, $_->{root} ] } @$mid ], [ [ 'project', "$proj_root" ] ], 'in the project: its install');
  my $out = Langertha::Raider::Context::Plugins->new(cwd => "$other", claude_home => "$h", enabled => \%on)->plugins;
  is([ map { [ $_->{scope}, $_->{root} ] } @$out ], [ [ 'user', "$user_root" ] ], 'elsewhere: the user install');
};

subtest 'enabled decides' => sub {
  my $list = Langertha::Raider::Context::Plugins->new(cwd => "$proj", enabled => { 'beta@m' => 1 })->plugins;
  is([ map { $_->{key} } @$list ], [qw( beta@m )], 'only enabled keys; absent = off');
  is(Langertha::Raider::Context::Plugins->new(cwd => "$proj", enabled => {})->plugins, [], 'nothing enabled');
};

subtest 'skill_dirs: skills/ plus manifest paths, never outside the root' => sub {
  my $p = plugins(cwd => "$proj");
  my ($a) = grep { $_->{key} eq 'alpha@m' } @{ $p->plugins };
  is([ $p->skill_dirs($a) ], [
    "$alpha/skills/one",
    "$alpha/skills/two",
    "$alpha/extra/three",
    "$alpha/single",
  ], 'dir of skills, single skill dir; escaping paths and duplicates dropped');
  my ($g) = grep { $_->{key} eq 'gamma@m' } @{ $p->plugins };
  is([ $p->skill_dirs($g) ], [ "$gamma/skills/g1", "$gamma/single-only" ], 'skills as a string');
  is([ $p->skill_dirs({ root => "$work/nowhere", manifest => {} }) ], [], 'missing root: none');
};

subtest 'missing or broken index: no plugins' => sub {
  my $h = path(tempdir(CLEANUP => 1));
  is(plugins(cwd => "$proj", claude_home => "$h")->plugins, [], 'missing');
  spew_json($h->child('plugins/installed_plugins.json'), [ 1, 2 ]);
  is(plugins(cwd => "$proj", claude_home => "$h")->plugins, [], 'not an object');
  $h->child('plugins/installed_plugins.json')->spew_raw('{ broken');
  is(plugins(cwd => "$proj", claude_home => "$h")->plugins, [], 'invalid JSON');
  spew_json($h->child('plugins/installed_plugins.json'), { plugins => [] });
  is(plugins(cwd => "$proj", claude_home => "$h")->plugins, [], 'plugins not a map');
  is(plugins(cwd => "$proj", claude_home => undef)->plugins, [], 'no claude home');
};

done_testing;

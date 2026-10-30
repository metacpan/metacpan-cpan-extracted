#!/usr/bin/env perl
# ABSTRACT: Claude Code settings files merged with sources (ADR 0019 §3, k151)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Context::Settings;

# ~/.claude/settings.json < .claude/settings.json < .claude/settings.local.json,
# later wins. Lists concatenate, maps merge per key, every entry keeps its
# file as source, broken files are reported and never fatal. Never touches
# the real ~/.claude: HOME and CLAUDE_CONFIG_DIR point at temp dirs.

my $home = path(tempdir(CLEANUP => 1));
local $ENV{HOME} = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = '';

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }

sub project { path(tempdir(CLEANUP => 1)) }

sub settings { Langertha::Raider::Context::Settings->new(project_dir => "$_[0]", @_[1 .. $#_]) }

my $T = JSON::MaybeXS->true;
my $F = JSON::MaybeXS->false;

subtest 'claude_home: CLAUDE_CONFIG_DIR, else ~/.claude' => sub {
  my $p = project();
  is(settings($p)->claude_home, $home->child('.claude')->stringify, 'empty CLAUDE_CONFIG_DIR: ~/.claude');
  local $ENV{CLAUDE_CONFIG_DIR} = '/somewhere/else';
  is(settings($p)->claude_home, '/somewhere/else', 'CLAUDE_CONFIG_DIR wins');
  is(Langertha::Raider::Home->claude_home->stringify, '/somewhere/else', 'Home->claude_home agrees');
};

subtest 'no files: empty, no errors' => sub {
  my $s = settings(project());
  my @files = @{ $s->files };
  is([ map { $_->{scope} } @files ], [qw( user project local )], 'three files in read order');
  is([ map { $_->{label} } @files ],
    [ '~/.claude/settings.json', '.claude/settings.json', '.claude/settings.local.json' ], 'labels');
  is([ map { $_->{exists} } @files ], [ 0, 0, 0 ], 'none exists');
  is([ grep { defined $_->{error} } @files ], [], 'no errors');
  is($s->permissions, { allow => [], ask => [], deny => [], default_mode => undef, additional_directories => [] },
    'empty permissions');
  is($s->hooks, {}, 'no hooks');
  is($s->env, {}, 'no env');
  is($s->enabled_plugin_map, {}, 'no plugins');
  is($s->ignored, [], 'nothing ignored');
};

# A full three-layer setup.
my $p = project();
spew_json($home->child('.claude/settings.json'), {
  model       => 'opus',
  permissions => {
    allow                 => [ 'Read', 'Bash(ls:*)', { not => 'a string' }, '' ],
    deny                  => [ 'WebFetch' ],
    defaultMode           => 'default',
    additionalDirectories => [ '/u/docs' ],
  },
  hooks => {
    PreToolUse => [ { matcher => 'Bash', hooks => [ { type => 'command', command => 'u.sh' } ] } ],
    Stop       => [ { hooks => [ { type => 'command', command => 'stop.sh' } ] } ],
  },
  env            => { SHARED => 'user', ONLY_USER => 'u', NUM => 7, FLAG => $T, LIST => [1] },
  enabledPlugins => { 'a@m' => $T, 'b@m' => $T, 'c@m' => 'yes' },
});
spew_json($p->child('.claude/settings.json'), {
  '$schema'   => 'https://json.schemastore.org/claude-code-settings.json',
  permissions => {
    allow       => [ 'Edit' ],
    ask         => [ 'Bash(git push:*)' ],
    defaultMode => 'acceptEdits',
  },
  hooks => {
    PreToolUse => [
      { matcher => 'Edit|Write', hooks => [ { type => 'command', command => 'p.sh' } ] },
      'not a group',
      { matcher => [ 'odd' ], hooks => 'not a list' },
    ],
  },
  env            => { SHARED => 'project' },
  enabledPlugins => { 'b@m' => $F },
  statusLine     => { type => 'command' },
});
spew_json($p->child('.claude/settings.local.json'), {
  permissions => { deny => [ 'Bash(rm:*)' ], additionalDirectories => [ '../local' ] },
  env         => { SHARED => 'local' },
  enabledPlugins => { 'd@m' => $T },
  extraKnownMarketplaces => {},
});

subtest 'files are read and labelled' => sub {
  my $s = settings($p);
  is([ map { $_->{exists} } @{ $s->files } ], [ 1, 1, 1 ], 'all three exist');
  is([ grep { defined $_->{error} } @{ $s->files } ], [], 'no errors');
  ok(!exists $s->files->[0]{data}, 'files carries no raw data');
  is($s->files->[1]{file}, $p->child('.claude/settings.json')->stringify, 'absolute file path');
};

subtest 'permissions: lists concatenated in file order, defaultMode last wins' => sub {
  my $perm = settings($p)->permissions;
  is($perm->{allow}, [
    { rule => 'Read',       source => '~/.claude/settings.json' },
    { rule => 'Bash(ls:*)', source => '~/.claude/settings.json' },
    { rule => 'Edit',       source => '.claude/settings.json' },
  ], 'allow: user then project, non-strings and empty skipped');
  is($perm->{ask}, [ { rule => 'Bash(git push:*)', source => '.claude/settings.json' } ], 'ask');
  is($perm->{deny}, [
    { rule => 'WebFetch',   source => '~/.claude/settings.json' },
    { rule => 'Bash(rm:*)', source => '.claude/settings.local.json' },
  ], 'deny: user then local');
  is($perm->{default_mode}, { value => 'acceptEdits', source => '.claude/settings.json' },
    'defaultMode: the last file that sets one');
  is($perm->{additional_directories}, [
    { path => '/u/docs',  source => '~/.claude/settings.json' },
    { path => '../local', source => '.claude/settings.local.json' },
  ], 'additionalDirectories concatenated');
};

subtest 'hooks: matcher groups per event, concatenated' => sub {
  my $hooks = settings($p)->hooks;
  is([ sort keys %$hooks ], [qw( PreToolUse Stop )], 'events');
  is($hooks->{PreToolUse}, [
    { matcher => 'Bash',       hooks => [ { type => 'command', command => 'u.sh' } ], source => '~/.claude/settings.json' },
    { matcher => 'Edit|Write', hooks => [ { type => 'command', command => 'p.sh' } ], source => '.claude/settings.json' },
    { matcher => undef,        hooks => [],                                           source => '.claude/settings.json' },
  ], 'user group first; non-object group skipped; odd matcher/hooks normalised');
  is($hooks->{Stop}, [ { matcher => undef, hooks => [ { type => 'command', command => 'stop.sh' } ], source => '~/.claude/settings.json' } ],
    'group without matcher');
};

subtest 'env: merged per key, later wins, strings and numbers only' => sub {
  my $s = settings($p);
  is($s->env, {
    SHARED    => { value => 'local', source => '.claude/settings.local.json' },
    ONLY_USER => { value => 'u',     source => '~/.claude/settings.json' },
    NUM       => { value => '7',     source => '~/.claude/settings.json' },
  }, 'booleans and lists skipped, number stringified');
  is($s->env_values, { SHARED => 'local', ONLY_USER => 'u', NUM => '7' }, 'env_values');
};

subtest 'enabledPlugins: merged per key, booleans only' => sub {
  my $s = settings($p);
  is($s->enabled_plugins, {
    'a@m' => { value => 1, source => '~/.claude/settings.json' },
    'b@m' => { value => 0, source => '.claude/settings.json' },
    'd@m' => { value => 1, source => '.claude/settings.local.json' },
  }, 'project disables b, string "yes" is no boolean');
  is($s->enabled_plugin_map, { 'a@m' => 1, 'b@m' => 0, 'd@m' => 1 }, 'enabled_plugin_map');
};

subtest 'ignored: every other top-level key, with source' => sub {
  is(settings($p)->ignored, [
    { key => 'model',                  source => '~/.claude/settings.json',     reason => 'not used by raider' },
    { key => '$schema',                source => '.claude/settings.json',       reason => 'not used by raider' },
    { key => 'statusLine',             source => '.claude/settings.json',       reason => 'not used by raider' },
    { key => 'extraKnownMarketplaces', source => '.claude/settings.local.json', reason => 'not used by raider' },
  ], 'in file order, sorted inside a file');
};

subtest 'broken files are reported, never fatal' => sub {
  my $q = project();
  $q->child('.claude')->mkpath;
  $q->child('.claude/settings.json')->spew_raw('{ "env": { "A": "1" }, oops }');
  $q->child('.claude/settings.local.json')->spew_raw('[ "an", "array" ]');
  spew_json($home->child('.claude/settings.json'), { env => { USER_OK => 'yes' } });
  my $s = settings($q);
  my @files = @{ $s->files };
  is($files[0]{error}, undef, 'user file fine');
  like($files[1]{error}, qr/\Ainvalid JSON: /, 'invalid JSON reported');
  unlike($files[1]{error}, qr/ line \d+\.\z/, 'without the Perl source location');
  is($files[2]{error}, 'not a JSON object', 'non-object reported');
  is($s->env_values, { USER_OK => 'yes' }, 'broken files contribute nothing');

  my $r = project();
  $r->child('.claude/settings.json')->mkpath;   # a directory, not a file
  my $f = settings($r)->files->[1];
  is($f->{exists}, 1, 'exists');
  like($f->{error}, qr/\Aunreadable: /, 'unreadable reported');
};

subtest 'CLAUDE_CONFIG_DIR outside the home: absolute label' => sub {
  my $cfg = path(tempdir(CLEANUP => 1));
  spew_json($cfg->child('settings.json'), { env => { FROM_CFG => '1' } });
  local $ENV{CLAUDE_CONFIG_DIR} = "$cfg";
  my $s = settings(project());
  is($s->files->[0]{label}, $cfg->child('settings.json')->stringify, 'absolute label');
  is($s->env, { FROM_CFG => { value => '1', source => $cfg->child('settings.json')->stringify } }, 'read from there');
};

subtest 'disableAllHooks: the last file that sets a boolean wins' => sub {
  my $q = project();
  is(settings($q)->disable_all_hooks, 0, 'unset: hooks on');
  spew_json($home->child('.claude/settings.json'), { disableAllHooks => $T });
  is(settings($q)->disable_all_hooks, 1, 'user turns them off');
  spew_json($q->child('.claude/settings.json'), { disableAllHooks => $F });
  is(settings($q)->disable_all_hooks, 0, 'project false overrides user true');
  spew_json($q->child('.claude/settings.local.json'), { disableAllHooks => 'yes' });
  is(settings($q)->disable_all_hooks, 0, 'a string is no boolean');
  is([ grep { $_->{key} eq 'disableAllHooks' } @{ settings($q)->ignored } ], [], 'not listed as ignored');
  $home->child('.claude/settings.json')->remove;
};

subtest 'claude_home undef: no user file' => sub {
  my $s = settings(project(), claude_home => undef);
  is([ map { $_->{scope} } @{ $s->files } ], [qw( project local )], 'only project and local');
};

subtest 'computed values cannot be passed in' => sub {
  my $s = settings($p, env => { X => { value => 'y', source => 'z' } });
  ok(!exists $s->env->{X}, 'env is built, not taken from new()');
};

done_testing;

#!/usr/bin/env perl
# ABSTRACT: MCP server sources per layout mode, precedence and shadowing (ADR 0029 §2, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Langertha::Raider::Config;
use Langertha::Raider::Context;
use Langertha::Raider::Context::Plugins;
use Langertha::Raider::Context::Settings;
use Langertha::Raider::MCP::Config;

# Raider's own files first (project, home), then Claude Code's sources in
# Claude Code's order (local, project, user, plugin), the latter only in the
# Claude layout; the first entry of a name wins whole, the rest is
# "shadowed"; --bare has none. Never touches the real ~/.claude*: HOME is a
# temp dir, CLAUDE_CONFIG_DIR unset.

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }
sub spew_yaml { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_utf8(YAML::PP->new->dump_string($data)) }

sub project { path(tempdir(CLEANUP => 1))->realpath }

sub reset_home {
  $home->child($_)->remove_tree for qw( .claude .raider );
  $home->child('.claude.json')->remove;
}

sub model {
  my ( $root, %args ) = @_;
  my $claude = delete $args{claude} // 1;
  my %claude_parts;
  if ($claude) {
    my $settings = Langertha::Raider::Context::Settings->new( project_dir => "$root" );
    %claude_parts = (
      settings => $settings,
      plugins  => Langertha::Raider::Context::Plugins->new( cwd => "$root", enabled => $settings->enabled_plugin_map ),
    );
  }
  return Langertha::Raider::MCP::Config->new(
    root          => "$root",
    claude_layout => $claude,
    config        => Langertha::Raider::Config->new( root => "$root" ),
    env           => {},
    %claude_parts,
    %args,
  );
}

sub names { [ map { $_->{name} } @{ $_[0]->servers } ] }
sub by_name { my ( $m ) = @_; return { map { $_->{name} => $_ } @{ $m->servers } } }

my $stdio = sub { { command => 'srv-'.$_[0] } };

# Every source names "shared" and one server of its own.
sub write_all_sources {
  my ( $root ) = @_;
  spew_yaml($root->child('.raider/config.yml'), { mcp => { shared => $stdio->('raider-project'), rp => $stdio->('rp') } });
  spew_yaml($home->child('.raider/config.yml'), { mcp => { shared => $stdio->('raider-home'), rh => $stdio->('rh') } });
  spew_json($home->child('.claude.json'), {
    mcpServers => { shared => $stdio->('user'), us => $stdio->('us') },
    projects   => { "$root" => { mcpServers => { shared => $stdio->('local'), lo => $stdio->('lo') } } },
  });
  spew_json($root->child('.mcp.json'), { mcpServers => { shared => $stdio->('project'), pr => $stdio->('pr') } });
}

subtest 'precedence: raider-project, raider-home, local, project, user' => sub {
  reset_home();
  my $root = project();
  write_all_sources($root);
  my $m = model($root);
  is(names($m), [qw( rp shared rh lo pr us )], 'servers in precedence order, first name wins');
  my $s = by_name($m);
  is($s->{shared}{scope}, 'raider-project', 'shared comes from the raider project file');
  is($s->{shared}{command}, 'srv-raider-project', 'its whole entry');
  is($s->{shared}{source}, '.raider/config.yml', 'source label');
  is($s->{shared}{shadowed}, [
    { scope => 'raider-home', source => '~/.raider/config.yml' },
    { scope => 'local',       source => '~/.claude.json projects["'.$root.'"]' },
    { scope => 'project',     source => '.mcp.json' },
    { scope => 'user',        source => '~/.claude.json' },
  ], 'the other entries are shadowed, in precedence order');
  is([ map { $s->{$_}{scope} } qw( rp rh lo pr us ) ],
    [qw( raider-project raider-home local project user )], 'each own server keeps its scope');
  is($m->errors, [], 'no file errors');
};

subtest 'no field merge across scopes' => sub {
  reset_home();
  my $root = project();
  spew_json($home->child('.claude.json'), {
    mcpServers => { db => { command => 'user-db', args => ['--user'], env => { A => 1 } } },
    projects   => { "$root" => { mcpServers => { db => { command => 'local-db' } } } },
  });
  my $db = model($root)->server('db');
  is($db->{command}, 'local-db', 'local wins');
  is($db->{args}, [], 'args not taken from the user entry');
  is($db->{env}, {}, 'env not taken from the user entry');
};

subtest 'native layout: only raider files' => sub {
  reset_home();
  my $root = project();
  write_all_sources($root);
  my $m = model($root, claude => 0);
  is(names($m), [qw( rp shared rh )], 'only raider-project and raider-home');
  is(by_name($m)->{shared}{shadowed}, [ { scope => 'raider-home', source => '~/.raider/config.yml' } ],
    'Claude sources are not even shadowing');
};

subtest 'bare: nothing' => sub {
  reset_home();
  my $root = project();
  write_all_sources($root);
  my $m = model($root, bare => 1);
  is($m->servers, [], 'no servers under --bare');
  is($m->approvals->{enabled}, {}, 'no approvals either');
};

subtest 'home directory: the home file is the project file, scope raider-home' => sub {
  reset_home();
  spew_yaml($home->child('.raider/config.yml'), { mcp => { mine => $stdio->('mine') } });
  my $m = model($home, claude => 0);
  my $s = $m->server('mine');
  is($s->{scope}, 'raider-home', 'scope raider-home');
  is($s->{source}, '~/.raider/config.yml', 'labelled as the home file');
  is($s->{approval}{required}, 0, 'needs no approval');
};

subtest 'CLAUDE_CONFIG_DIR moves the global config' => sub {
  reset_home();
  my $root = project();
  my $ccd = path(tempdir(CLEANUP => 1))->realpath;
  spew_json($ccd->child('.claude.json'), { mcpServers => { moved => $stdio->('moved') } });
  spew_json($home->child('.claude.json'), { mcpServers => { stay => $stdio->('stay') } });
  local $ENV{CLAUDE_CONFIG_DIR} = "$ccd";
  my $m = model($root);
  is($m->claude_config_file, $ccd->child('.claude.json')->stringify, 'file in CLAUDE_CONFIG_DIR');
  is(names($m), ['moved'], 'read from there, not ~/.claude.json');
  is($m->server('moved')->{source}, $ccd->child('.claude.json')->stringify, 'absolute label outside the home');
};

subtest 'local scope found by the real path of the project dir' => sub {
  reset_home();
  my $root = project();
  my $link = path(tempdir(CLEANUP => 1))->child('link');
  symlink "$root", "$link" or skip_all 'no symlinks';
  spew_json($home->child('.claude.json'), { projects => { "$root" => { mcpServers => { lo => $stdio->('lo') } } } });
  my $m = model($link);
  is(names($m), ['lo'], 'projects entry of the real path');
};

subtest 'broken files are reported, never fatal' => sub {
  reset_home();
  my $root = project();
  $home->child('.claude.json')->spew_raw('{ nope');
  $root->child('.mcp.json')->spew_raw('[1,2]');
  my $m = model($root);
  is($m->servers, [], 'no servers');
  is($m->errors, [
    { source => '~/.claude.json', error => 'invalid JSON' },
    { source => '.mcp.json',      error => 'not a JSON object' },
  ], 'both reported');

  reset_home();
  spew_json($root->child('.mcp.json'), { mcpServers => [ 'x' ] });
  is(model($root)->errors, [ { source => '.mcp.json', error => 'mcpServers is not an object' } ],
    'mcpServers that is not an object');
};

# A plugin installed and enabled for the project.
sub install_plugin {
  my ( %p ) = @_;
  my $dir = path(tempdir(CLEANUP => 1))->realpath;
  spew_json($dir->child('.claude-plugin/plugin.json'), { name => $p{name}, %{ $p{manifest} // {} } });
  spew_json($dir->child($_), $p{files}{$_}) for keys %{ $p{files} // {} };
  my $index = $home->child('.claude/plugins/installed_plugins.json');
  my $data = -f $index ? $json->decode($index->slurp_raw) : { version => 2, plugins => {} };
  $data->{plugins}{ $p{name}.'@market' } = [ { scope => 'user', installPath => "$dir" } ];
  spew_json($index, $data);
  my $settings = $home->child('.claude/settings.json');
  my $s = -f $settings ? $json->decode($settings->slurp_raw) : {};
  $s->{enabledPlugins}{ $p{name}.'@market' } = JSON::MaybeXS->true unless $p{disabled};
  spew_json($settings, $s);
  return $dir;
}

subtest 'plugin servers: names, .mcp.json and manifest, last declaration wins' => sub {
  reset_home();
  my $root = project();
  my $dir = install_plugin(
    name     => 'my-plugin',
    files    => {
      '.mcp.json'    => { mcpServers => { 'database-tools' => { command => 'db-default' }, other => { command => 'o' } } },
      'extra.json'   => { 'database-tools' => { command => 'db-extra' } },
    },
    manifest => { mcpServers => [ './.mcp.json', 'extra.json', { inline => { type => 'http', url => 'https://x/mcp' } } ] },
  );
  install_plugin(name => 'off', disabled => 1, files => { '.mcp.json' => { mcpServers => { never => { command => 'n' } } } });
  my $m = model($root);
  is(names($m), [ 'plugin:my-plugin:database-tools', 'plugin:my-plugin:inline', 'plugin:my-plugin:other' ],
    'enabled plugin only, named plugin:PLUGIN:SERVER, sorted');
  my $db = $m->server('plugin:my-plugin:database-tools');
  is($db->{command}, 'db-extra', 'the later declaration (manifest file) wins');
  is($db->{source}, 'plugin:my-plugin (extra.json)', 'source names the file');
  is($db->{scope}, 'plugin', 'scope plugin');
  is($db->{key}, 'plugin_my-plugin_database-tools', 'tool name part');
  is($m->tool_name($db, 'query'), 'mcp__plugin_my-plugin_database-tools__query', "Claude Code's plugin tool name");
  is($db->{plugin}{root}, "$dir", 'plugin info kept');
  is($m->server('plugin:my-plugin:inline')->{source}, 'plugin:my-plugin (plugin.json)', 'inline map');
  is($m->errors, [], './.mcp.json named twice counts once, no error');
};

subtest 'plugin files: top-level map, broken and escaping files' => sub {
  reset_home();
  my $root = project();
  install_plugin(name => 'flat', files => { '.mcp.json' => { srv => { command => 'flat' } } },
    manifest => { mcpServers => [ '../outside.json', 'missing.json', [ 'nested' ] ] });
  my $m = model($root);
  is(names($m), ['plugin:flat:srv'], 'a .mcp.json without mcpServers is the map itself');
  is([ map { $_->{error} } @{ $m->errors } ], [
    'plugin:flat: ../outside.json is outside the plugin',
    'plugin:flat: missing.json does not exist',
    'plugin:flat: plugin.json mcpServers holds neither a path nor an object',
  ], 'reported, never fatal');
};

subtest 'plugin variables' => sub {
  reset_home();
  my $root = project();
  my $dir = install_plugin(name => 'tg', files => { '.mcp.json' => { mcpServers => { tg => {
    command => '${CLAUDE_PLUGIN_ROOT}/bin/srv',
    args    => [ '--data=${CLAUDE_PLUGIN_DATA}', '--project=${CLAUDE_PROJECT_DIR}' ],
    env     => { ROOT => '${CLAUDE_PLUGIN_ROOT}' },
  } } } });
  spew_json($home->child('.claude.json'), { mcpServers => { u => { command => '${CLAUDE_PLUGIN_ROOT}/x', args => ['${CLAUDE_PROJECT_DIR}'] } } });
  my $m = model($root, env => { CLAUDE_PLUGIN_ROOT => '/env/root' });
  my $tg = $m->server('plugin:tg:tg');
  is($tg->{command}, "$dir/bin/srv", 'CLAUDE_PLUGIN_ROOT: the install path, over the environment');
  is($tg->{args}, [ '--data='.$home->child('.claude/plugins/data/tg-market'), '--project='.$root ],
    'CLAUDE_PLUGIN_DATA (the hooks data dir), CLAUDE_PROJECT_DIR (the project dir)');
  is($tg->{env}, { ROOT => "$dir" }, 'in env values too');
  is($tg->{warnings}, [], 'no warnings');
  my $u = $m->server('u');
  is($u->{command}, '/env/root/x', 'a user server gets CLAUDE_PLUGIN_ROOT only from the environment');
  is($u->{args}, ['${CLAUDE_PROJECT_DIR}'], 'and no CLAUDE_PROJECT_DIR (needs ${CLAUDE_PROJECT_DIR:-.})');
  is($u->{warnings}, ['${CLAUDE_PROJECT_DIR} is not set'], 'warned');
};

subtest 'plugin servers come last' => sub {
  reset_home();
  my $root = project();
  install_plugin(name => 'p', files => { '.mcp.json' => { mcpServers => { s => { command => 'p' } } } });
  spew_json($home->child('.claude.json'), { mcpServers => { 'plugin:p:s' => { command => 'user' } } });
  my $m = model($root);
  is(names($m), ['plugin:p:s'], 'one server of that name');
  is($m->server('plugin:p:s')->{scope}, 'user', 'the user entry wins over the plugin');
};

subtest 'from_context: per layout mode' => sub {
  reset_home();
  my $root = project();
  $root->child('CLAUDE.md')->spew_utf8("# project\n");
  spew_json($root->child('.mcp.json'), { mcpServers => { pr => $stdio->('pr') } });
  spew_yaml($home->child('.raider/config.yml'), { mcp => { rh => $stdio->('rh') } });

  my $config = Langertha::Raider::Config->new( root => "$root" );
  my $claude = Langertha::Raider::MCP::Config->from_context(
    Langertha::Raider::Context->new( root => "$root" ), config => $config, env => {} );
  ok($claude->claude_layout, 'claude mode reads the Claude layout');
  is(names($claude), [qw( rh pr )], 'raider-home and .mcp.json');
  is($claude->project_dir, "$root", 'project dir from the layout');

  my $bare = Langertha::Raider::MCP::Config->from_context(
    Langertha::Raider::Context->new( root => "$root", bare => 1 ), config => $config, env => {} );
  is($bare->servers, [], 'bare: none');

  my $native = project();
  my $nconfig = Langertha::Raider::Config->new( root => "$native" );
  my $n = Langertha::Raider::MCP::Config->from_context(
    Langertha::Raider::Context->new( root => "$native" ), config => $nconfig, env => {} );
  ok(!$n->claude_layout, 'native mode');
  is(names($n), ['rh'], 'only the home server');
};

done_testing;

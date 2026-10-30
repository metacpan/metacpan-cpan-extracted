#!/usr/bin/env perl
# ABSTRACT: approval of project MCP servers, workspace trust, disabled servers (ADR 0029 §7-8, k164)
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
use Langertha::Raider::Context::Settings;
use Langertha::Raider::MCP::Config;

# Project servers (.mcp.json, mcp: of the project config) start only when
# approved. Approvals from a repository's .claude/settings.json (and from
# .claude/settings.local.json outside the configuration home) count only in
# a folder Claude Code's record trusts; a disabled entry counts from every
# file; the home config's mcp_approvals approves for one project dir.

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $T = JSON::MaybeXS->true;
my $F = JSON::MaybeXS->false;
sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }
sub spew_yaml { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_utf8(YAML::PP->new->dump_string($data)) }

sub reset_home {
  $home->child($_)->remove_tree for qw( .claude .raider );
  $home->child('.claude.json')->remove;
}

# A project below a parent dir (so trust can be inherited) with .mcp.json
# servers a, b and c.
sub project {
  my $parent = path(tempdir(CLEANUP => 1))->realpath;
  my $root = $parent->child('proj');
  $root->mkpath;
  spew_json($root->child('.mcp.json'), { mcpServers => { map { $_ => { command => 'srv-'.$_ } } qw( a b c ) } });
  return $root;
}

sub trust { my ( $dir, $value ) = @_; spew_json($home->child('.claude.json'), { projects => { "$dir" => { hasTrustDialogAccepted => $value // $T } } }) }

sub model {
  my ( $root, %args ) = @_;
  my $claude = delete $args{claude} // 1;
  return Langertha::Raider::MCP::Config->new(
    root          => "$root",
    claude_layout => $claude,
    config        => Langertha::Raider::Config->new( root => "$root" ),
    ( $claude ? ( settings => Langertha::Raider::Context::Settings->new( project_dir => "$root" ) ) : () ),
    env           => {},
    %args,
  );
}

sub states { my ( $m ) = @_; return { map { $_->{name} => $_->{approval}{state} } @{ $m->servers } } }
sub statuses { my ( $m ) = @_; return { map { $_->{name} => $_->{status} } @{ $m->servers } } }

subtest 'Settings: the approval keys with their file and scope' => sub {
  reset_home();
  my $root = project();
  spew_json($home->child('.claude/settings.json'), { enableAllProjectMcpServers => $F, enabledMcpjsonServers => [ 'a', '', {} ] });
  spew_json($root->child('.claude/settings.json'), { disabledMcpjsonServers => ['b'], enableAllProjectMcpServers => 'yes' });
  spew_json($root->child('.claude/settings.local.json'), { enableAllProjectMcpServers => $T, enabledMcpjsonServers => ['c'] });
  my $s = Langertha::Raider::Context::Settings->new( project_dir => "$root" );
  is($s->mcpjson_approvals, {
    enable_all => [
      { value => 0, source => '~/.claude/settings.json',     scope => 'user' },
      { value => 1, source => '.claude/settings.local.json', scope => 'local' },
    ],
    enabled  => [
      { name => 'a', source => '~/.claude/settings.json',     scope => 'user' },
      { name => 'c', source => '.claude/settings.local.json', scope => 'local' },
    ],
    disabled => [ { name => 'b', source => '.claude/settings.json', scope => 'project' } ],
  }, 'booleans only, strings only, in read order');
  is($s->ignored, [], 'the three keys are used, not ignored');
};

subtest 'nothing decided: pending, not startable' => sub {
  reset_home();
  my $root = project();
  my $m = model($root);
  is(states($m), { a => 'pending', b => 'pending', c => 'pending' }, 'pending');
  is($m->server('a')->{status}, 'pending', 'status pending');
  is($m->server('a')->{reason}, 'pending approval', 'reason');
  is([ $m->startable ], [], 'nothing to start');
  ok(!$m->trust->{trusted}, 'not trusted');
};

subtest 'untrusted folder: only user settings approve, disabled from anywhere' => sub {
  reset_home();
  my $root = project();
  spew_json($home->child('.claude/settings.json'), { enabledMcpjsonServers => [ 'a', 'b' ] });
  spew_json($root->child('.claude/settings.json'), { enabledMcpjsonServers => ['c'], disabledMcpjsonServers => ['b'] });
  spew_json($root->child('.claude/settings.local.json'), { enableAllProjectMcpServers => $T });
  my $m = model($root);
  is(states($m), { a => 'approved', b => 'rejected', c => 'pending' },
    'a by the user file; b rejected by the untrusted project file; c not approved by it');
  is($m->server('a')->{approval}, { required => 1, state => 'approved', source => '~/.claude/settings.json', by => 'enabledMcpjsonServers' },
    'approval record');
  is($m->server('a')->{status}, 'configured', 'approved: configured');
  is($m->server('b')->{status}, 'rejected', 'status rejected');
  is($m->server('b')->{reason}, 'rejected by disabledMcpjsonServers in .claude/settings.json', 'reason');
  is($m->approvals->{ignored}, [
    { name => 'c', by => 'enabledMcpjsonServers', source => '.claude/settings.json', reason => 'the folder is not trusted' },
    { name => undef, by => 'enableAllProjectMcpServers', source => '.claude/settings.local.json', reason => 'the folder is not trusted' },
  ], 'what did not count is reported');
  is([ map { $_->{name} } $m->startable ], ['a'], 'only a starts');
};

subtest 'trusted folder (Claude Code record, inherited from a parent)' => sub {
  reset_home();
  my $root = project();
  trust($root->parent);
  spew_json($root->child('.claude/settings.json'), { enabledMcpjsonServers => ['a'] });
  spew_json($root->child('.claude/settings.local.json'), { enabledMcpjsonServers => ['b'] });
  my $m = model($root);
  is($m->trust, { trusted => 1, dir => $root->parent->stringify,
    source => '~/.claude.json projects["'.$root->parent.'"]' }, 'trusted by the parent entry');
  is(states($m), { a => 'approved', b => 'approved', c => 'pending' }, 'project and local files count');
  is($m->approvals->{ignored}, [], 'nothing ignored');

  trust($root, 'true');
  ok(!model($root)->trust->{trusted}, 'only a JSON true trusts');
  trust($root, $F);
  ok(!model($root)->trust->{trusted}, 'false does not');
  trust($root);
  ok(!model($root, claude => 0)->trust->{trusted}, 'outside the Claude layout nothing is trusted');
};

subtest 'enableAllProjectMcpServers: last counted file wins' => sub {
  reset_home();
  my $root = project();
  spew_json($home->child('.claude/settings.json'), { enableAllProjectMcpServers => $T });
  spew_json($root->child('.claude/settings.local.json'), { enableAllProjectMcpServers => $F, disabledMcpjsonServers => ['c'] });
  my $m = model($root);
  is(states($m), { a => 'approved', b => 'approved', c => 'rejected' }, 'untrusted: the local false does not count');
  is($m->server('a')->{approval}{by}, 'enableAllProjectMcpServers', 'approved by enable-all');
  trust($root);
  is(states(model($root)), { a => 'pending', b => 'pending', c => 'rejected' }, 'trusted: the local false wins');
};

subtest 'configuration home: the local file counts without trust' => sub {
  reset_home();
  spew_json($home->child('.mcp.json'), { mcpServers => { h => { command => 'x' } } });
  spew_json($home->child('.claude/settings.local.json'), { enabledMcpjsonServers => ['h'] });
  is(states(model($home)), { h => 'approved' }, 'the home directory is the configuration home');
  $home->child('.mcp.json')->remove;
};

subtest 'home config mcp_approvals' => sub {
  reset_home();
  my $root = project();
  spew_yaml($root->child('.raider/config.yml'), {
    mcp           => { r => { command => 'raider-srv' } },
    mcp_approvals => { "$root" => { enable_all => 1 } },   # a project file cannot approve
  });
  my $m = model($root, claude => 0);
  is(states($m), { r => 'pending' }, 'native: the raider-project server waits; its own mcp_approvals does not count');
  ok((grep { $_->{key} eq 'mcp_approvals' } @{ Langertha::Raider::Config->new( root => "$root" )->explain->{ignored} }),
    'and is reported by config explain');

  spew_yaml($home->child('.raider/config.yml'), { mcp_approvals => {
    "$root"           => { enabled => ['r', 'a'], disabled => 'b' },
    '/somewhere/else' => { enable_all => 1 },
  } });
  $m = model($root);
  is(states($m), { r => 'approved', a => 'approved', b => 'rejected', c => 'pending' },
    'approves raider-project and .mcp.json servers of this project; another path does not count');
  is($m->server('b')->{reason}, 'rejected by mcp_approvals["'.$root.'"].disabled in ~/.raider/config.yml', 'reason');

  spew_yaml($home->child('.raider/config.yml'), { mcp_approvals => { $root->parent->stringify.'/proj' => { enable_all => 'yes' } } });
  is(states(model($root)), { r => 'approved', a => 'approved', b => 'approved', c => 'approved' }, 'enable_all');
};

subtest 'disabledMcpServers: local, user and plugin servers off for the project' => sub {
  reset_home();
  my $root = project();
  spew_json($home->child('.claude.json'), {
    mcpServers => { u => { command => 'x' }, keep => { command => 'x' } },
    projects   => { "$root" => { mcpServers => { l => { command => 'x' } }, disabledMcpServers => [ 'u', 'l', 'a' ] } },
  });
  my $m = model($root);
  is(statuses($m), { u => 'disabled', l => 'disabled', keep => 'configured', a => 'pending', b => 'pending', c => 'pending' },
    'user and local disabled; a project server is not affected');
  is($m->server('u')->{reason}, 'disabled for this project by ~/.claude.json projects["'.$root.'"].disabledMcpServers', 'reason');
};

subtest 'the decision holds over a broken entry' => sub {
  reset_home();
  my $root = project();
  spew_json($root->child('.mcp.json'), { mcpServers => { bad => { url => 'https://x' } } });
  spew_json($home->child('.claude/settings.json'), { disabledMcpjsonServers => ['bad'] });
  is(model($root)->server('bad')->{status}, 'rejected', 'rejected before invalid');
  spew_json($home->child('.claude/settings.json'), {});
  is(model($root)->server('bad')->{status}, 'invalid', 'invalid before pending');
};

subtest 'approval_target' => sub {
  reset_home();
  my $root = project();
  is(model($root)->approval_target, {
    kind => 'raider-home', file => $home->child('.raider/config.yml')->stringify,
    label => '~/.raider/config.yml', path => "$root",
  }, 'untrusted Claude layout: the home config');
  is(model($root, claude => 0)->approval_target->{kind}, 'raider-home', 'native: the home config');
  trust($root);
  is(model($root)->approval_target, {
    kind => 'claude-settings', file => $root->child('.claude/settings.local.json')->stringify,
    label => '.claude/settings.local.json',
  }, 'trusted: settings.local.json, where Claude Code writes it');
  is(Langertha::Raider::MCP::Config->new( root => "$root" )->approval_target, undef, 'no config, no Claude layout: nowhere');
};

done_testing;

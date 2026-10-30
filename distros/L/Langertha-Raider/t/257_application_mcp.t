#!/usr/bin/env perl
# ABSTRACT: the application mounts configured MCP servers: engine order, gate, events, remount, shutdown (ADR 0029, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use Path::Tiny;
use lib "$FindBin::Bin/lib";
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::Permissions;
use Langertha::Raider::Permissions::Rule;

clear_engine_env();
my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;

sub home_mcp {
  my ( %servers ) = @_;
  my $yaml = "mcp:\n";
  for my $name (sort keys %servers) {
    my ( $command, @args ) = @{ $servers{$name} };
    $yaml .= "  $name:\n    command: \"$command\"\n    args: [ ".join(', ', map { '"'.$_.'"' } @args)." ]\n";
  }
  $home->child('.raider')->mkpath;
  $home->child('.raider', 'config.yml')->spew_utf8($yaml);
}

sub app {
  my ( %args ) = @_;
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  my @events;
  my $app = mock_app( root => "$root", on_event => sub { push @events, [ @_ ] }, %args );
  return ( $app, \@events, $root );
}

subtest 'engine order, gate, events' => sub {
  home_mcp( good => [ $^X, $script, 'normal' ], broken => [ $^X, $script, 'exit' ],
    missing => [ 'raider-t257-no-such-program' ] );
  my ( $app, $events ) = app( script => [ { text => 'done' } ] );
  my @clients = @{ $app->configured_mcp->clients };
  is([ map { $_->name } @clients ], [qw( broken good missing )], 'raider-home servers, sorted by name');
  is([ map { 0 + $_ } @{ $app->_mcps }[0 .. 2] ], [ map { 0 + $_ } @clients ], 'they lead the engine mcp_servers');
  ok(@{ $app->_mcps } > 3, "raider's own servers follow");
  is($app->permissions->source_servers, { 'engine:1' => 'broken', 'engine:2' => 'good', 'engine:3' => 'missing' },
    'the gate knows them as foreign servers');

  is($app->run('hi')->text, 'done', 'the run is not stopped by failing servers');
  my %by = map { my %p = @{$_}[1 .. $#$_]; ( $p{name} => \%p ) } grep { $_->[0] eq 'mcp.server' } @$events;
  is($by{good}{status}, 'connected', 'good connected');
  is($by{good}{tools}, 6, 'with its tools');
  is($by{broken}{status}, 'failed', 'broken failed');
  is($by{broken}{reason}, 'exited with code 3 (stderr: test server: fatal: no configuration)', 'with exit code and stderr');
  is($by{missing}{reason}, 'exited with code 127 (stderr: cannot run raider-t257-no-such-program: No such file or directory)',
    'a missing program');
  is($by{good}{scope}, 'raider-home', 'scope');

  # Entering plan mode remounts raider's own servers (exit_plan_mode): the
  # configured ones stay in front.
  my $before = scalar @{ $app->_mcps };
  $app->set_permission_mode('plan', 'test');
  is(scalar @{ $app->_mcps }, $before + 1, 'one more server after the remount');
  is([ map { 0 + $_ } @{ $app->_mcps }[0 .. 2] ], [ map { 0 + $_ } @clients ], 'the configured servers still lead');

  my $pid = $app->configured_mcp->client('good')->_transport->pid;
  ok(kill(0, $pid), 'the server process runs');
  $app->shutdown_mcp;
  ok(!kill(0, $pid), 'shutdown_mcp stops it');
  is($app->configured_mcp->client('good')->status, 'stopped', 'status stopped');
};

subtest 'bare: no configured servers' => sub {
  home_mcp( good => [ $^X, $script, 'normal' ] );
  my ( $app ) = app( bare => 1 );
  is($app->configured_mcp->clients, [], 'none');
  is($app->permissions->source_servers, {}, 'no foreign sources');
};

subtest 'rules and suggestions on prefixed names' => sub {
  my $policy = Langertha::Raider::Permissions->from_sources(
    root => "$home", sources => [ { allow => [ { rule => 'mcp__t__echo_env', source => 'test' } ],
      deny => [ { rule => 'mcp__gone', source => 'test' } ], ask => [] } ],
    source_servers => { 'engine:1' => 't', 'engine:2' => 'gone' },
  );
  my $call = sub { { name => $_[0], source => $_[1], arguments => {} } };
  is($policy->decide($call->('mcp__t__echo_env', 'engine:1'))->{verdict}, 'allow', 'tool rule allows the prefixed name');
  is($policy->decide($call->('mcp__t__fail', 'engine:1'))->{verdict}, 'ask', 'another tool of the server asks');
  is($policy->decide($call->('mcp__gone__x', 'engine:2'))->{verdict}, 'deny', 'server rule denies every tool');
  is($policy->suggest_rule($call->('mcp__t__fail', 'engine:1')), 'mcp__t__fail', 'suggestion keeps the prefixed name');
  is($policy->suggest_rule($call->('fail', 'catalog:t')), 'mcp__t__fail', 'a catalog tool gets the prefix');
};

done_testing;

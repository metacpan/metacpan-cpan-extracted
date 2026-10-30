#!/usr/bin/env perl
# ABSTRACT: configured stdio MCP servers: handshake, revisions, tools, calls, failures, timeouts, stop (ADR 0029 §10, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use FindBin;
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Langertha::Raider::MCP;
use Langertha::Raider::MCP::Config;
use Langertha::Raider::MCP::Server;

# A real child process speaks JSON-RPC on stdio (t/lib/mcp-test-server.pl);
# the servers come from ~/.claude.json (user scope: no approval in the way).

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $script = path($FindBin::Bin)->child('lib', 'mcp-test-server.pl')->realpath->stringify;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $loop = IO::Async::Loop->new;
my $root = path(tempdir(CLEANUP => 1))->realpath;
my $project = $root->child('proj');
$project->mkpath;

sub config {
  my ( $servers, %env ) = @_;
  $home->child('.claude.json')->spew_raw($json->encode({ mcpServers => $servers }));
  return Langertha::Raider::MCP::Config->new( root => "$root", project_dir => "$project", claude_layout => 1, env => { %ENV, %env } );
}

sub entry { my ( @args ) = @_; return { command => $^X, args => [ $script, @args ] } }

sub server {
  my ( $entry, %args ) = @_;
  my $config = config({ t => $entry });
  my $spec = $config->server('t');
  return Langertha::Raider::MCP::Server->new( spec => $spec, loop => $loop, base_env => { %ENV }, kill_grace => 0.2, %args );
}

sub wait_for { my ( $f ) = @_; $loop->await($f); return $f }

subtest 'normal server: handshake, tools, calls' => sub {
  my $log = $root->child('normal.log');
  my $s = server({ %{ entry('normal', '--log', "$log") }, env => { RAIDER_T254 => 'from-entry' } });
  my @seen;
  $s = Langertha::Raider::MCP::Server->new( spec => $s->spec, loop => $loop, base_env => { %ENV, CLAUDE_PLUGIN_ROOT => '/leak' },
    kill_grace => 0.2, on_status => sub { push @seen, $_[0]->status } );
  is($s->status, 'configured', 'configured before the start');
  wait_for($s->initialize);
  is($s->status, 'connected', 'connected') or diag $s->reason;
  is(\@seen, [qw( starting connected )], 'status changes reported');
  is($s->protocol_version, '2025-11-25', 'asked revision accepted');
  is($s->server_info, { name => 'raider-test', version => '1.0' }, 'serverInfo');
  is($s->instructions, 'test server', 'instructions');
  is([ $s->tool_names ], [ map { 'mcp__t__'.$_ } qw( boom echo_env fail meta sleep with_dot ) ], 'tools prefixed, names normalised');
  is($s->original_name('mcp__t__with_dot'), 'with.dot', 'original name kept');
  my $tools = wait_for($s->list_tools)->get;
  is($tools->[1]{inputSchema}{required}, ['name'], 'definition kept');
  ok(( grep { /test server: starting/ } $s->stderr_tail ), 'stderr captured, not printed');

  my $r = wait_for($s->call_tool('mcp__t__echo_env', { name => 'RAIDER_T254' }))->get;
  is($r->{content}[0]{text}, 'RAIDER_T254=from-entry cwd='.$root, 'entry env reaches the process, which runs in the root');
  $r = wait_for($s->call_tool('mcp__t__echo_env', { name => 'CLAUDE_PROJECT_DIR' }))->get;
  is($r->{content}[0]{text}, 'CLAUDE_PROJECT_DIR='.$project.' cwd='.$root, 'CLAUDE_PROJECT_DIR is the project dir');
  $r = wait_for($s->call_tool('mcp__t__echo_env', { name => 'CLAUDE_PLUGIN_ROOT' }))->get;
  like($r->{content}[0]{text}, qr/\ACLAUDE_PLUGIN_ROOT=\(unset\)/, 'an inherited CLAUDE_PLUGIN_ROOT is removed');

  $r = wait_for($s->call_tool('mcp__t__fail', {}))->get;
  ok($r->{isError}, 'an error result stays a result');
  my $f = wait_for($s->call_tool('mcp__t__boom', {}));
  is(($f->failure)[0], 'MCP error -32000: boom on purpose', 'a JSON-RPC error fails the call');
  $r = wait_for($s->call_tool('mcp__t__meta', {}))->get;
  is($r->{_meta}, { 'other/key' => 1 }, 'raider/ keys of _meta are taken out');
  $f = wait_for($s->call_tool('mcp__t__nope', {}));
  like(($f->failure)[0], qr/has no tool mcp__t__nope/, 'unknown tool');

  my @log = map { $json->decode($_) } $log->lines_utf8({ chomp => 1 });
  is([ map { $_->{method} } @log[0, 1, 2] ], [ 'initialize', 'notifications/initialized', 'tools/list' ], 'handshake order');
  is($log[0]{params}{clientInfo}{name}, 'raider', 'clientInfo');
  is($log[3]{params}, { name => 'echo_env', arguments => { name => 'RAIDER_T254' } }, 'tools/call with the original name');

  my $pid = $s->_transport->pid;
  my $t0 = Time::HiRes::time;
  wait_for($s->stop_f);
  ok(!kill(0, $pid), 'process gone after stop_f');
  ok(Time::HiRes::time - $t0 < 1, 'closing stdin was enough');
  is($s->status, 'stopped', 'status stopped');
  $f = wait_for($s->call_tool('mcp__t__fail', {}));
  like(($f->failure)[0], qr/is not connected \(stopped/, 'no calls after stop');
};

subtest 'older and unknown revisions' => sub {
  my $s = server(entry('normal', '--version', '2025-03-26'));
  wait_for($s->start_f);
  is([ $s->status, $s->protocol_version ], [ 'connected', '2025-03-26' ], 'a 2025-03-26 server is accepted');
  wait_for($s->stop_f);

  $s = server(entry('normal', '--version', '2024-11-05'));
  wait_for($s->start_f);
  is([ $s->status, $s->protocol_version ], [ 'connected', '2024-11-05' ], 'a 2024-11-05 server is accepted');
  wait_for($s->stop_f);

  $s = server(entry('normal', '--version', '2099-01-01'));
  wait_for($s->start_f);
  is($s->status, 'failed', 'an unknown revision fails');
  like($s->reason, qr/answered with MCP revision 2099-01-01; raider speaks 2025-11-25, 2025-06-18/, 'reason');

  $s = server(entry('noinit'));
  wait_for($s->start_f);
  is($s->status, 'failed', 'no initialize: failed');
  like($s->reason, qr/does not answer initialize.*2026-07-28/, 'reason names the revision');
};

subtest "the installed MCP::Server (its legacy handshake)" => sub {
  my $s = server(entry('mcp-server'));
  wait_for($s->start_f);
  is($s->status, 'connected', 'connected') or diag $s->reason;
  is([ $s->tool_names ], [qw( mcp__t__echo_env mcp__t__fail )], 'tools');
  my $r = wait_for($s->call_tool('mcp__t__echo_env', { name => 'CLAUDE_PROJECT_DIR' }))->get;
  is($r->{content}[0]{text}, 'CLAUDE_PROJECT_DIR='.$project.' cwd='.$root, 'call works');
  wait_for($s->stop_f);
};

subtest 'failures: exit, missing program, hang' => sub {
  my $s = server(entry('exit'));
  wait_for($s->start_f);
  is($s->status, 'failed', 'exits at once: failed');
  is($s->reason, 'exited with code 3 (stderr: test server: fatal: no configuration)', 'exit code and stderr');

  $s = server({ command => 'raider-t254-no-such-program' });
  wait_for($s->start_f);
  is($s->status, 'failed', 'missing program: failed');
  like($s->reason, qr/\Aexited with code 127 \(stderr: cannot run raider-t254-no-such-program: No such file or directory\)/, 'like a shell');

  $s = server(entry('hang'), startup_timeout_ms => 400);
  my $t0 = Time::HiRes::time;
  wait_for($s->start_f);
  my $took = Time::HiRes::time - $t0;
  is($s->status, 'failed', 'hangs: failed');
  like($s->reason, qr/\Adid not start within 0\.4 s \(MCP_TIMEOUT\)/, 'reason');
  ok($took < 1.5, 'the start ends at the timeout, not after the kill grace');
  my $pid = $s->_transport->pid;
  wait_for($s->_transport->stop_f);
  ok(!kill(0, $pid), 'the hanging process is stopped');

  my $calls = wait_for($s->list_tools)->get;
  is($calls, [], 'a failed server lists no tools');
};

subtest 'per-call timeout cancels the call' => sub {
  my $log = $root->child('timeout.log');
  my $s = server({ %{ entry('normal', '--log', "$log") }, timeout => 1000 });
  wait_for($s->start_f);
  my $t0 = Time::HiRes::time;
  my $f = wait_for($s->call_tool('mcp__t__sleep', { seconds => 3 }));
  is(($f->failure)[0], 'MCP tool call timed out after 1 s', 'timed out');
  ok(Time::HiRes::time - $t0 < 2.5, 'after about the timeout');
  wait_for($loop->delay_future( after => 2.5 ));
  my @log = map { $json->decode($_) } $log->lines_utf8({ chomp => 1 });
  ok(( grep { ( $_->{method} // '' ) eq 'notifications/cancelled' } @log ), 'notifications/cancelled sent');
  wait_for($s->stop_f);
};

subtest 'the set: parallel start, source servers, report, stop' => sub {
  my $config = config({
    a    => entry('normal'),
    b    => entry('hang'),
    c    => entry('exit'),
    off  => { type => 'sse', url => 'https://x' },
  }, MCP_TIMEOUT => 600);
  my $set2 = Langertha::Raider::MCP->new( config => $config, loop => $loop, kill_grace => 0.2 );
  is([ map { $_->name } @{ $set2->clients } ], [qw( a b c )], 'one client per startable server');
  is($set2->source_servers, { 'engine:1' => 'a', 'engine:2' => 'b', 'engine:3' => 'c' }, 'engine:N for the gate');
  is($set2->clients->[0]->startup_timeout_ms, 600, 'MCP_TIMEOUT reaches the clients');
  my $t0 = Time::HiRes::time;
  wait_for($set2->start_f);
  ok(Time::HiRes::time - $t0 < 1.5, 'started in parallel: one timeout, not three');
  my %row = map { $_->{name} => $_ } @{ $set2->report };
  is([ map { $row{$_}{status} } qw( a b c off ) ], [qw( connected failed failed unsupported )], 'statuses');
  is($row{a}{tools}[0], 'mcp__a__boom', 'tools in the report');
  is($row{a}{protocol_version}, '2025-11-25', 'revision in the report');
  ok(( grep { /fatal/ } @{ $row{c}{stderr} } ), 'stderr in the report');
  is($row{off}{tools}, [], 'no tools for a server that does not start');
  my $pid = $set2->client('a')->_transport->pid;
  wait_for($set2->stop_f);
  ok(!kill(0, $pid), 'stop_f stops every process');
  is([ map { $_->status } @{ $set2->clients } ], [qw( stopped stopped stopped )], 'all stopped');
};

subtest 'plugin server: data directory created when named' => sub {
  my $data = $root->child('plugin-data');
  my $spec = config({ t => entry('normal') })->server('t');
  $spec = { %$spec, entry => { args => ['${CLAUDE_PLUGIN_DATA}'] }, plugin => { name => 'p', root => "$root", data_dir => "$data" } };
  my $s = Langertha::Raider::MCP::Server->new( spec => $spec, loop => $loop, base_env => { %ENV }, kill_grace => 0.2 );
  is($s->child_env->{CLAUDE_PLUGIN_DATA}, "$data", 'CLAUDE_PLUGIN_DATA in the environment');
  is($s->child_env->{CLAUDE_PLUGIN_ROOT}, "$root", 'CLAUDE_PLUGIN_ROOT in the environment');
  wait_for($s->start_f);
  ok(-d $data, 'data directory created');
  wait_for($s->stop_f);
};

done_testing;

#!/usr/bin/env perl
# ABSTRACT: configured streamable-HTTP MCP servers: session id, protocol header, JSON and SSE answers (ADR 0029 §10, k164)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Test::Raider::MCPHTTP;
use Langertha::Raider::MCP::Config;
use Langertha::Raider::MCP::Server;

# A local server of the revision 2025-06-18 refuses every request after
# initialize that lacks its Mcp-Session-Id or MCP-Protocol-Version header --
# what the installed Net::Async::MCP never sends.

my $home = path(isolate_home())->realpath;
$ENV{HOME} = "$home";
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $loop = IO::Async::Loop->new;
my $root = path(tempdir(CLEANUP => 1))->realpath;

sub wait_for { my ( $f ) = @_; $loop->await($f); return $f }

sub server {
  my ( $entry ) = @_;
  $home->child('.claude.json')->spew_raw($json->encode({ mcpServers => { web => $entry } }));
  my $config = Langertha::Raider::MCP::Config->new( root => "$root", claude_layout => 1, env => { TOKEN => 's3cret' } );
  return Langertha::Raider::MCP::Server->new( spec => $config->server('web'), loop => $loop, startup_timeout_ms => 5000 );
}

for my $sse (0, 1) {
  subtest( ( $sse ? 'event-stream' : 'JSON' ).' answers' => sub {
    my $srv = Test::Raider::MCPHTTP->new( loop => $loop, sse => $sse );
    my $s = server({ type => 'http', url => $srv->url, headers => { 'X-Token' => '${TOKEN}', 'Mcp-Session-Id' => 'forged' } });
    wait_for($s->start_f);
    is($s->status, 'connected', 'connected') or diag $s->reason;
    is($s->protocol_version, '2025-06-18', 'the server chose 2025-06-18');
    is([ $s->tool_names ], [qw( mcp__web__echo_header mcp__web__hello )], 'tools');
    my $r = wait_for($s->call_tool('mcp__web__hello', {}))->get;
    is($r->{content}[0]{text}, 'hello over http', 'call');
    $r = wait_for($s->call_tool('mcp__web__echo_header', { name => 'X-Token' }))->get;
    is($r->{content}[0]{text}, 's3cret', 'configured header, expanded');
    my @parallel = map { $s->call_tool('mcp__web__hello', {}) } 1 .. 3;
    wait_for(Future->wait_all(@parallel));
    is([ map { $_->get->{content}[0]{text} } @parallel ], [ ('hello over http') x 3 ], 'parallel calls');

    my @req = $srv->requests;
    my ( $init ) = grep { ( $_->{body}{method} // '' ) eq 'initialize' } @req;
    is($init->{headers}{accept}, 'application/json, text/event-stream', 'Accept both');
    ok(!exists $init->{headers}{'mcp-protocol-version'}, 'no protocol header on initialize');
    ok(!exists $init->{headers}{'mcp-session-id'}, 'a configured Mcp-Session-Id is not sent');
    my ( $note ) = grep { ( $_->{body}{method} // '' ) eq 'notifications/initialized' } @req;
    ok($note, 'notifications/initialized sent');
    my @later = grep { ( $_->{body}{method} // '' ) =~ m{\Atools/} } @req;
    is([ map { $_->{headers}{'mcp-session-id'} } @later ], [ ('sess-1') x @later ], 'session id on every later request');
    is([ map { $_->{headers}{'mcp-protocol-version'} } @later ], [ ('2025-06-18') x @later ], 'protocol header too');
    if ($sse) {
      wait_for($loop->delay_future( after => 0.2 ));
      ok(( grep { !defined $_->{body}{method} && ( $_->{body}{id} // '' ) eq 'srv-1' } $srv->requests ),
        "the server's ping in the stream was answered");
    }
    wait_for($s->stop_f);
    my ( $delete ) = grep { $_->{method} eq 'DELETE' } $srv->requests;
    is($delete->{headers}{'mcp-session-id'}, 'sess-1', 'stop_f ends the session with DELETE');
    is($s->status, 'stopped', 'stopped');
  } );
}

subtest 'failures' => sub {
  my $s = server({ type => 'http', url => 'http://127.0.0.1:1/mcp' });
  wait_for($s->start_f);
  is($s->status, 'failed', 'nothing listens: failed');
  like($s->reason, qr/\AHTTP request failed: /, 'reason');

  my $srv = Test::Raider::MCPHTTP->new( loop => $loop );
  $s = server({ type => 'http', url => $srv->url.'?x' });
  wait_for($s->start_f);
  is($s->status, 'connected', 'query in the url is fine');
  wait_for($s->stop_f);
};

done_testing;

use strict;
use warnings;
use Test::More;

use MCP::Run::Bash;
use MCP::Server::Context ();
# Mirrors the cpanfile pin. Prereqs are install-time metadata only, so a stale
# MCP in @INC reaches prove untouched — without this the run dies with three
# "not exported by MCP::Constants" errors instead of naming the real cause.
use MCP 0.15;
use MCP::Constants qw(INVALID_PARAMS META_CLIENT_CAPABILITIES META_PROTOCOL_VERSION META_SERVER_INFO),
  qw(PROTOCOL_VERSION);

my $server = MCP::Run::Bash->new(name => 'RunServer', version => '0.001');

# MCP::Server::handle() requires a blessed context — passing a raw
# hash triggers "Can't call method has_scope on unblessed reference".
sub ctx { MCP::Server::Context->new }

# Every request carries the protocol revision and client capabilities in
# params._meta; without them MCP::Server rejects the request before it ever
# reaches a tool (see the 'protocol contract' subtest below).
sub req {
  my ($id, $method, $params) = @_;
  return {
    jsonrpc => '2.0',
    id      => $id,
    method  => $method,
    params  => {
      %{ $params // {} },
      _meta => {
        META_PROTOCOL_VERSION()    => PROTOCOL_VERSION,
        META_CLIENT_CAPABILITIES() => {},
      },
    },
  };
}

# The handshake: 'server/discover' replaced 'initialize', and serverInfo moved
# from the result body into result._meta, where it now rides along on every
# response.
subtest 'server/discover' => sub {
  my $response = $server->handle(req(1, 'server/discover'), ctx());

  is $response->{jsonrpc}, '2.0', 'jsonrpc version';
  is $response->{id}, 1, 'response id';
  my $info = $response->{result}{_meta}{+META_SERVER_INFO};
  is $info->{name}, 'RunServer', 'server name';
  is $info->{version}, '0.001', 'server version';
  ok exists $response->{result}{capabilities}{tools}, 'tools capability';
};

subtest 'tools/list' => sub {
  my $response = $server->handle(req(2, 'tools/list'), ctx());

  is $response->{id}, 2, 'response id';
  my $tools = $response->{result}{tools};
  is scalar(@$tools), 1, 'one tool';
  is $tools->[0]{name}, 'run', 'tool name';
  ok exists $tools->[0]{inputSchema}{properties}{command}, 'command in schema';
};

subtest 'tools/call' => sub {
  my $response = $server->handle(
    req(3, 'tools/call', { name => 'run', arguments => { command => 'echo hello world' } }), ctx());

  is $response->{id}, 3, 'response id';
  my $content = $response->{result}{content}[0]{text};
  like $content, qr/Exit code: 0/, 'exit code in output';
  like $content, qr/hello world/, 'command output in result';
};

subtest 'tools/call unknown tool' => sub {
  my $response = $server->handle(
    req(4, 'tools/call', { name => 'nonexistent', arguments => {} }), ctx());

  ok exists $response->{error}, 'error returned';
  like $response->{error}{message}, qr/not found/i, 'error message';
};

# Regression guard for GH #2: a request without params._meta is rejected with
# 'Missing protocol version' before dispatch, which is what turned every
# subtest above into a confusing failure on the smokers. Pinning the signature
# here means a future protocol change fails loudly and legibly instead.
subtest 'protocol contract' => sub {
  my $response = $server->handle({ jsonrpc => '2.0', id => 5, method => 'tools/list' }, ctx());

  is $response->{error}{code}, INVALID_PARAMS, 'invalid params without _meta';
  like $response->{error}{message}, qr/missing protocol version/i, 'missing protocol version';

  my $stale = $server->handle({
    jsonrpc => '2.0',
    id      => 6,
    method  => 'tools/list',
    params  => { _meta => { META_PROTOCOL_VERSION() => '1999-01-01', META_CLIENT_CAPABILITIES() => {} } },
  }, ctx());

  like $stale->{error}{message}, qr/unsupported protocol version/i, 'unsupported version rejected';
  is_deeply $stale->{error}{data}{supported}, [PROTOCOL_VERSION], 'supported versions reported';
};

done_testing;

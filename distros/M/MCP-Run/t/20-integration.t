use strict;
use warnings;
use Test::More;

use MCP::Run::Bash;
use MCP::Server::Context ();

my $server = MCP::Run::Bash->new(name => 'RunServer', version => '0.001');

# MCP::Server::handle() requires a blessed context — passing a raw
# hash triggers "Can't call method has_scope on unblessed reference"
# inside _handle_tools_list.
sub ctx { MCP::Server::Context->new }

subtest 'initialize' => sub {
  my $response = $server->handle({
    jsonrpc => '2.0',
    id      => 1,
    method  => 'initialize',
    params  => { protocolVersion => '2025-11-25', capabilities => {}, clientInfo => { name => 'test' } },
  }, ctx());

  is $response->{jsonrpc}, '2.0', 'jsonrpc version';
  is $response->{id}, 1, 'response id';
  is $response->{result}{serverInfo}{name}, 'RunServer', 'server name';
  is $response->{result}{serverInfo}{version}, '0.001', 'server version';
  ok exists $response->{result}{capabilities}{tools}, 'tools capability';
};

subtest 'tools/list' => sub {
  my $response = $server->handle({
    jsonrpc => '2.0',
    id      => 2,
    method  => 'tools/list',
  }, ctx());

  is $response->{id}, 2, 'response id';
  my $tools = $response->{result}{tools};
  is scalar(@$tools), 1, 'one tool';
  is $tools->[0]{name}, 'run', 'tool name';
  ok exists $tools->[0]{inputSchema}{properties}{command}, 'command in schema';
};

subtest 'tools/call' => sub {
  my $response = $server->handle({
    jsonrpc => '2.0',
    id      => 3,
    method  => 'tools/call',
    params  => {
      name      => 'run',
      arguments => { command => 'echo hello world' },
    },
  }, ctx());

  is $response->{id}, 3, 'response id';
  my $content = $response->{result}{content}[0]{text};
  like $content, qr/Exit code: 0/, 'exit code in output';
  like $content, qr/hello world/, 'command output in result';
};

subtest 'tools/call unknown tool' => sub {
  my $response = $server->handle({
    jsonrpc => '2.0',
    id      => 4,
    method  => 'tools/call',
    params  => { name => 'nonexistent', arguments => {} },
  }, ctx());

  ok exists $response->{error}, 'error returned';
  like $response->{error}{message}, qr/not found/i, 'error message';
};

done_testing;

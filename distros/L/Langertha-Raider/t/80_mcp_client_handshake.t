#!/usr/bin/env perl
# ABSTRACT: Plain Net::Async::MCP speaks the current protocol to an in-process MCP::Server

use strict;
use warnings;

use Test2::Bundle::More;
use IO::Async::Loop;
use MCP::Server;
use Net::Async::MCP;

my $server = MCP::Server->new(name => 'handshake-test', version => '1.0');
$server->tool(
  name         => 'echo',
  description  => 'Echo the given text',
  input_schema => {
    type       => 'object',
    properties => { text => { type => 'string' } },
    required   => ['text'],
  },
  code => sub { $_[0]->text_result('echo: '.$_[1]->{text}) },
);

my $loop = IO::Async::Loop->new;
my $mcp  = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

my $init = $mcp->initialize->get;
ok($init, 'handshake completes');
is($mcp->server_info->{name}, 'handshake-test', 'server info stored from the handshake');

my $tools = $mcp->list_tools->get;
is_deeply([ map { $_->{name} } @$tools ], ['echo'], 'tools listed');

my $res = $mcp->call_tool('echo', { text => 'hi' })->get;
ok(!$res->{isError}, 'tool call succeeds');
is($res->{content}[0]{text}, 'echo: hi', 'tool result returned');

done_testing;

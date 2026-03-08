#!/usr/bin/env perl
# ABSTRACT: Hermes-native tool calling with NousResearch
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

$|=1;

use IO::Async::Loop;
use Future::AsyncAwait;
use Net::Async::MCP;
use MCP::Server;
use Langertha::Engine::NousResearch;

# --- Build a simple in-process MCP server ---

my $server = MCP::Server->new(name => 'demo', version => '1.0');

$server->tool(
  name        => 'add',
  description => 'Add two numbers together and return the result',
  input_schema => {
    type       => 'object',
    properties => {
      a => { type => 'number', description => 'First number' },
      b => { type => 'number', description => 'Second number' },
    },
    required => ['a', 'b'],
  },
  code => sub {
    my ($self, $args) = @_;
    my $result = $args->{a} + $args->{b};
    return $self->text_result("$result");
  },
);

$server->tool(
  name        => 'multiply',
  description => 'Multiply two numbers together and return the result',
  input_schema => {
    type       => 'object',
    properties => {
      a => { type => 'number', description => 'First number' },
      b => { type => 'number', description => 'Second number' },
    },
    required => ['a', 'b'],
  },
  code => sub {
    my ($self, $args) = @_;
    my $result = $args->{a} * $args->{b};
    return $self->text_result("$result");
  },
);

# --- Set up the MCP client ---

my $loop = IO::Async::Loop->new;

my $mcp = Net::Async::MCP->new(server => $server);
$loop->add($mcp);

async sub main {
  await $mcp->initialize;

  my $tools = await $mcp->list_tools;
  printf "Available tools: %s\n", join(', ', map { $_->{name} } @$tools);

  # --- NousResearch with Hermes-native tool calling ---
  # NousResearch composes HermesTools — tools are injected into the
  # system prompt as <tools> XML and <tool_call> tags are parsed from
  # the model's text output.

  my $engine = Langertha::Engine::NousResearch->new(
    api_key     => $ENV{NOUSRESEARCH_API_KEY} || die("Set NOUSRESEARCH_API_KEY"),
    model       => 'Hermes-3-Llama-3.1-70B',
    mcp_servers => [$mcp],
  );

  printf "\nAsking Hermes to use tools...\n\n";

  my $response = await $engine->chat_with_tools_f(
    'What is 7 plus 15? Then multiply the result by 3. Use the tools.'
  );

  printf "Final response:\n%s\n", $response;

  # --- Any engine can use Hermes tool calling by composing HermesTools ---
  # See Langertha::Role::HermesTools for details.
  # AKI and AKIOpenAI also compose HermesTools out of the box.
}

main()->get;

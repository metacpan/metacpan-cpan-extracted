#!/usr/bin/env perl
# ABSTRACT: Ollama->new_openai passes its tool and engine arguments on to OllamaOpenAI
use strict;
use warnings;
use Test2::Bundle::More;

use Langertha::Engine::Ollama;

# karr k335: new_openai built the native engine from all its arguments, then
# called openai(), which copies only url/model/api_key/embedding_model/
# chat_model/system_prompt/temperature. Everything else a caller handed to
# new_openai was silently dropped: the documented tools list (passed to an
# engine that has no tools attribute), mcp_servers, tool_max_iterations,
# response_format, reasoning_effort, ... The returned OllamaOpenAI engine is
# the only object the caller keeps, so its arguments must reach it.

{
  package My::FakeMCP;
  sub new { bless {}, shift }
  sub list_tools {}
  sub call_tool {}
}

my $mcp1 = My::FakeMCP->new;
my $mcp2 = My::FakeMCP->new;

{
  my $oai = Langertha::Engine::Ollama->new_openai(
    url   => 'http://h:11434',
    model => 'qwen3:8b',
    tools => [$mcp1],
  );
  isa_ok $oai, 'Langertha::Engine::OllamaOpenAI';
  is $oai->url, 'http://h:11434/v1', 'url gets the /v1 suffix';
  is $oai->model, 'qwen3:8b', 'model passed on';
  is_deeply $oai->mcp_servers, [$mcp1], 'tools become the MCP servers of the returned engine';
}

{
  my $oai = Langertha::Engine::Ollama->new_openai(
    url                 => 'http://h:11434',
    model               => 'qwen3:8b',
    mcp_servers         => [$mcp1],
    tools               => [$mcp2],
    tool_max_iterations => 3,
    response_format     => { type => 'json_object' },
    reasoning_effort    => 'low',
    response_size       => 256,
    embedding_dimensions => 512,
    user_agent_timeout  => 7,
  );
  is_deeply $oai->mcp_servers, [ $mcp1, $mcp2 ], 'mcp_servers passed on, tools appended';
  is $oai->tool_max_iterations, 3, 'tool_max_iterations passed on';
  is_deeply $oai->response_format, { type => 'json_object' }, 'response_format passed on';
  is $oai->reasoning_effort, 'low', 'reasoning_effort (OpenAI-side only) passed on';
  is $oai->response_size, 256, 'response_size passed on';
  is $oai->embedding_dimensions, 512, 'embedding_dimensions passed on';
  is $oai->user_agent_timeout, 7, 'user_agent_timeout passed on';
}

# Native-only arguments have no counterpart on /v1 and do not break the call.
{
  my $oai = Langertha::Engine::Ollama->new_openai(
    url => 'http://h:11434', model => 'm', keep_alive => '5m', seed => 1, context_size => 2048 );
  isa_ok $oai, 'Langertha::Engine::OllamaOpenAI';
  ok !$oai->can('keep_alive'), 'keep_alive stays native-only';
}

done_testing;

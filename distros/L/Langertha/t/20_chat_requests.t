#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Anthropic;
use Langertha::Engine::Groq;
use Langertha::Engine::Ollama;
use Langertha::Engine::OpenAI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(24);

my $ollama_testurl = 'http://test.url:12345';
my $ollama = Langertha::Engine::Ollama->new(
  url => $ollama_testurl,
  model => 'model',
  system_prompt => 'systemprompt',
  context_size => 4096,
  temperature => 0.5,
);
my $ollama_request = $ollama->chat('testprompt');
is($ollama_request->uri, $ollama_testurl.'/api/chat', 'Ollama request uri is correct');
is($ollama_request->method, 'POST', 'Ollama request method is correct');
is($ollama_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama request JSON Content Type is set');
my $ollama_data = $json->decode($ollama_request->content);
is_deeply($ollama_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "model",
  options => {
    temperature => 0.5,
    num_ctx => 4096,
  },
  stream => JSON->false,
}, 'Ollama request body is correct');

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'apikey',
  model => 'gpt-4o-mini',
  system_prompt => 'systemprompt',
  temperature => 0.5,
);
my $openai_request = $openai->chat('testprompt');
is($openai_request->uri, 'https://api.openai.com/v1/chat/completions', 'OpenAI request uri is correct');
is($openai_request->method, 'POST', 'OpenAI request method is correct');
is($openai_request->header('Authorization'), 'Bearer apikey', 'OpenAI request Authorization header is correct');
is($openai_request->header('Content-Type'), 'application/json; charset=utf-8', 'OpenAI request JSON Content Type is set');
my $openai_data = $json->decode($openai_request->content);
is_deeply($openai_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "gpt-4o-mini",
  stream => JSON->false,
  temperature => 0.5,
}, 'OpenAI request body is correct');

my $anthropic = Langertha::Engine::Anthropic->new(
  api_key => 'apikey',
  model => 'claude-3-5-sonnet-20240620',
  system_prompt => 'systemprompt',
  api_version => '2024-02-04',
  response_size => 2048,
  temperature => 0.5,
);
my $anthropic_request = $anthropic->chat('testprompt');
is($anthropic_request->uri, 'https://api.anthropic.com/v1/messages', 'Anthropic request uri is correct');
is($anthropic_request->method, 'POST', 'Anthropic request method is correct');
is($anthropic_request->header('X-Api-Key'), 'apikey', 'Anthropic request X-Api-Key header is correct');
is($anthropic_request->header('Anthropic-Version'), '2024-02-04', 'Anthropic request Anthropic Version header is correct');
my $anthropic_data = $json->decode($anthropic_request->content);
is_deeply($anthropic_data, {
  max_tokens => 2048,
  temperature => 0.5,
  messages => [{
    content => 'testprompt',
    role => 'user',
  }],
  system => 'systemprompt',
  model => 'claude-3-5-sonnet-20240620',
}, 'Anthropic request body is correct');

my $ollama_openai_testurl = 'http://test.openai.url:12345';
my $ollama_for_openai = Langertha::Engine::Ollama->new(
  url => $ollama_openai_testurl,
  model => 'model',
  system_prompt => 'systemprompt',
  temperature => 0.5,
);
my $ollama_openai = $ollama_for_openai->openai;
my $ollama_openai_request = $ollama_openai->chat('testprompt');
is($ollama_openai_request->uri, $ollama_openai_testurl.'/v1/chat/completions', 'Ollama OpenAI request uri is correct');
is($ollama_openai_request->method, 'POST', 'Ollama OpenAI request method is correct');
is($ollama_openai_request->header('Authorization'), 'Bearer ollama', 'Ollama OpenAI request Authorization header is correct');
is($ollama_openai_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama OpenAI request JSON Content Type is set');
my $ollama_openai_data = $json->decode($ollama_openai_request->content);
is_deeply($ollama_openai_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "model",
  stream => JSON->false,
  temperature => 0.5,
}, 'Ollama OpenAI request body is correct');

my $groq = Langertha::Engine::Groq->new(
  api_key => 'apikey',
  model => 'gemma2-9b-it',
  system_prompt => 'systemprompt',
);
my $groq_request = $groq->chat('testprompt');
is($groq_request->uri, 'https://api.groq.com/openai/v1/chat/completions', 'Groq request uri is correct');
is($groq_request->method, 'POST', 'OpenAI request method is correct');
is($groq_request->header('Authorization'), 'Bearer apikey', 'Groq request Authorization header is correct');
is($groq_request->header('Content-Type'), 'application/json; charset=utf-8', 'Groq request JSON Content Type is set');
my $groq_data = $json->decode($groq_request->content);
is_deeply($groq_data, {
  messages => [{
    content => "systemprompt", role => "system",
  },{
    content => "testprompt", role => "user",
  }],
  model => "gemma2-9b-it",
  stream => JSON->false,
}, 'Groq request body is correct');

done_testing;

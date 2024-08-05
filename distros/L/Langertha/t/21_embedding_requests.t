#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(9);

my $ollama_testurl = 'http://test.url:12345';
my $ollama = Langertha::Engine::Ollama->new(
  url => $ollama_testurl,
  embedding_model => 'model',
);
my $ollama_request = $ollama->embedding('testprompt');
is($ollama_request->uri, $ollama_testurl.'/api/embeddings', 'Ollama request uri is correct');
is($ollama_request->method, 'POST', 'Ollama request method is correct');
is($ollama_request->header('Content-Type'), 'application/json; charset=utf-8', 'Ollama request JSON Content Type is set');
my $ollama_data = $json->decode($ollama_request->content);
is_deeply($ollama_data, {
  model => 'model',
  prompt => 'testprompt',
}, 'Ollama request body is correct');

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'apikey',
  embedding_model => 'model',
);
my $openai_request = $openai->embedding('testprompt');
is($openai_request->uri, 'https://api.openai.com/v1/embeddings', 'OpenAI request uri is correct');
is($openai_request->method, 'POST', 'OpenAI request method is correct');
is($openai_request->header('Authorization'), 'Bearer apikey', 'OpenAI request Authorization header is correct');
is($openai_request->header('Content-Type'), 'application/json; charset=utf-8', 'OpenAI request JSON Content Type is set');
my $openai_data = $json->decode($openai_request->content);
is_deeply($openai_data, {
  input => 'testprompt',
  model => 'model',
}, 'OpenAI request body is correct');

done_testing;

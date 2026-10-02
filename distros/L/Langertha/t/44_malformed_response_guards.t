#!/usr/bin/env perl
# ABSTRACT: Defensive deref guards for content-less / data-less 200 payloads (karr k171)
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::Anthropic;
use Langertha::Engine::vLLM;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub mock_http {
  my ($body) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode($body));
  $http->header('Content-Type' => 'application/json');
  return $http;
}

# --- AnthropicCompatible::chat_response content-deref guard (k171) ------------
# A shim can answer a 200 whose JSON body lacks the `content` array (an error
# shape squeezed through the /anthropic shim). @{$data->{content}} used to crash
# on @{undef}; the // [] guard yields graceful empty content instead.
my $anthropic = Langertha::Engine::Anthropic->new(
  api_key => 'test',
  model   => 'claude-3-5-sonnet-20240620',
);

# Sanity: a well-formed body still parses.
{
  my $resp = $anthropic->chat_response(mock_http({
    id      => 'msg_1',
    model   => 'claude-3-5-sonnet-20240620',
    content => [ { type => 'text', text => 'hello' } ],
    stop_reason => 'end_turn',
  }));
  is("$resp", 'hello', 'Anthropic: well-formed content still parsed');
}

# A content-less 200 must not crash on @{undef} -- graceful empty content.
{
  my $resp = eval {
    $anthropic->chat_response(mock_http({
      id => 'msg_2', type => 'message', role => 'assistant', stop_reason => 'end_turn',
    }));
  };
  ok(!$@, 'Anthropic: content-less 200 does not crash on @{undef}') or diag($@);
  ok($resp, 'Anthropic: content-less 200 returns a Response');
  is("$resp", '', 'Anthropic: content-less 200 yields empty content');
}

# The error shape is no answer: since k338 it croaks with the error, as the
# OpenAI-compatible parser does (k301), rather than yielding empty content.
{
  my $resp = eval {
    $anthropic->chat_response(mock_http({
      type  => 'error',
      error => { type => 'invalid_request_error', message => 'bad' },
    }));
  };
  ok(!defined $resp, 'Anthropic: error-shaped 200 returns no Response');
  like($@, qr/response carried an error: bad/, 'Anthropic: it croaks with the error, not a deref crash');
}

# --- OpenAICompatible::embedding_response data-deref guard (k171) -------------
# A malformed/error payload that still parses as 200 JSON can lack the `data`
# array. @{$data->{data}} crashed with "Can't use an undefined value as an ARRAY
# reference"; the guard croaks with a readable message instead.
my $vllm = Langertha::Engine::vLLM->new( url => 'http://x' );

# Sanity: a well-formed embedding body still returns its vector.
{
  my $vec = $vllm->embedding_response(mock_http({
    object => 'list',
    data   => [ { object => 'embedding', index => 0, embedding => [ 0.1, 0.2, 0.3 ] } ],
  }));
  is_deeply($vec, [ 0.1, 0.2, 0.3 ], 'embedding: well-formed data still returns vector');
}

# A data-less error shape croaks with a speaking message, not a raw deref crash.
{
  my $vec = eval {
    $vllm->embedding_response(mock_http({
      error => { type => 'invalid_request_error', message => 'no input given' },
    }));
  };
  my $err = $@;
  ok(!defined $vec, 'embedding: data-less 200 does not return a value');
  like($err, qr/missing 'data' array/, 'embedding: croaks with a speaking message');
  like($err, qr/no input given/, 'embedding: croak surfaces the payload error message');
  unlike($err, qr/undefined value as an ARRAY reference/,
    'embedding: no raw deref crash');
}

# A non-array `data` (e.g. a string) also croaks rather than deref-crashing.
{
  my $vec = eval {
    $vllm->embedding_response(mock_http({ data => 'oops' }));
  };
  ok(!defined $vec, 'embedding: non-array data does not return a value');
  like($@, qr/missing 'data' array/, 'embedding: non-array data croaks cleanly');
}

# --- no vector / no image in a 200 (karr k290) --------------------------------
# An embedding call exists to return a vector. A 200 with an empty data array,
# an entry without an embedding, or an Ollama body without embeddings (older
# Ollama answers some load errors with 200 {"error":...}) used to return undef
# silently; Raider then stored undef vectors and its search degraded without a
# word. The same holds for an image call that yields no image. Each croaks,
# naming the engine and surfacing the payload's error when there is one.
use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;

{
  my $vec = eval { $vllm->embedding_response(mock_http({ object => 'list', data => [] })) };
  ok(!defined $vec, 'embedding: empty data returns no value');
  like($@, qr/\ALangertha::Engine::vLLM embedding response contained no vector/,
    'embedding: empty data croaks, naming the engine');

  $vec = eval { $vllm->embedding_response(mock_http({ data => [ { index => 0 } ] })) };
  like($@, qr/\ALangertha::Engine::vLLM embedding response contained no vector/,
    'embedding: an entry without an embedding croaks');
}

my $ollama = Langertha::Engine::Ollama->new( url => 'http://test.invalid:11434' );
{
  my $vec = eval { $ollama->embedding_response(mock_http({ error => 'model not found' })) };
  ok(!defined $vec, 'Ollama embedding: error body returns no value');
  like($@, qr/\ALangertha::Engine::Ollama embedding response contained no vector \(error: model not found\)/,
    'Ollama embedding: croaks with the engine and the payload error');

  eval { $ollama->embedding_response(mock_http({ model => 'm', embeddings => [] })) };
  like($@, qr/\ALangertha::Engine::Ollama embedding response contained no vector/,
    'Ollama embedding: empty embeddings croaks');

  eval { $ollama->embedding_response(mock_http({ embeddings => [ 'oops' ] })) };
  like($@, qr/\ALangertha::Engine::Ollama embedding response contained no vector/,
    'Ollama embedding: a non-array entry croaks');
}

my $openai = Langertha::Engine::OpenAI->new( api_key => 'k' );
{
  my $images = $openai->image_response(mock_http({ data => [ { url => 'https://x/1.png' } ] }));
  is_deeply($images, [ { url => 'https://x/1.png' } ], 'image: well-formed data still returned');

  $images = eval { $openai->image_response(mock_http({ created => 1, data => [] })) };
  ok(!defined $images, 'image: empty data returns no value');
  like($@, qr/\ALangertha::Engine::OpenAI image response contained no image/,
    'image: empty data croaks, naming the engine');

  eval { $openai->image_response(mock_http({ error => { message => 'content policy' } })) };
  like($@, qr/\ALangertha::Engine::OpenAI image response contained no image \(error: content policy\)/,
    'image: missing data croaks with the payload error');
}

# --- malformed JSON on a 200 names the engine (karr k290) ---------------------
# The decoder's own "malformed JSON string ... at Role/HTTP.pm line N" named no
# engine and no body, unlike the non-2xx path. Every response kind goes through
# parse_response, so the engine-named croak covers them all.
{
  my $http = HTTP::Response->new(200, 'OK');
  $http->header('Content-Type' => 'text/html');
  $http->content("<html>gateway\n  error</html>");
  my $vec = eval { $openai->embedding_response($http) };
  ok(!defined $vec, 'malformed JSON: no value');
  like($@, qr/\ALangertha::Engine::OpenAI response is not valid JSON: <html>gateway error<\/html>/,
    'malformed JSON: croak names the engine and shows the collapsed body');
  unlike($@, qr/malformed JSON string/, 'malformed JSON: not the raw decoder message');
}

done_testing;

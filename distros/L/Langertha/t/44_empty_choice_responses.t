#!/usr/bin/env perl
# ABSTRACT: A 200 chat body without a choice croaks or reports why; refusals surface on Response.refusal
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Gemini;

# karr k301. A 200 chat body with no choice used to come back as a Response
# with content '' and no finish_reason -- indistinguishable from a model that
# legitimately said nothing:
#  - gateways (OpenRouter and other proxies) put an `error` object into a 200
#    body; `choices: []` without one is no answer either. Both croak now, the
#    style of the k290 embedding/image croaks: naming the engine and the error.
#  - Gemini answers a blocked prompt with no candidates and
#    promptFeedback.blockReason. A block is an answer, not a transport error:
#    the Response carries content '' and the blockReason verbatim as
#    finish_reason, the way a candidate's finishReason is passed through.
#  - an OpenAI refusal (structured output) is message.refusal with content
#    null; it was only reachable via raw. ADR 0004: a new field is a Response
#    attribute, so it is Response.refusal (and delta.refusal on a stream
#    chunk; a Responses API `refusal` content part likewise).
# The bodies are shaped from the providers' API references (OpenAI chat
# completions + Responses, OpenRouter errors, Gemini generateContent); they
# are not verbatim live captures.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub mock_http {
  my ($body) = @_;
  my $http = HTTP::Response->new( 200, 'OK' );
  $http->content( $json->encode($body) );
  $http->header( 'Content-Type' => 'application/json' );
  return $http;
}

my $openai     = Langertha::Engine::OpenAI->new( api_key => 'k' );
my $openrouter = Langertha::Engine::OpenRouter->new( api_key => 'k', model => 'openai/gpt-4o' );

subtest 'OpenAI-compatible: error object in a 200 body croaks' => sub {
  my $resp = eval {
    $openrouter->chat_response( mock_http( { error => { message => 'upstream overloaded', code => 502 } } ) );
  };
  ok !defined $resp, 'no Response returned';
  like $@, qr/\ALangertha::Engine::OpenRouter response carried an error: upstream overloaded \(502\)/,
    'croak names the engine, the message and the code';

  eval { $openai->chat_response( mock_http( { error => { message => 'bad things' }, choices => [] } ) ) };
  like $@, qr/\ALangertha::Engine::OpenAI response carried an error: bad things at /,
    'no code -> no parenthesis; empty choices with an error still report the error';

  eval { $openai->chat_response( mock_http( { error => 'plain string error' } ) ) };
  like $@, qr/\ALangertha::Engine::OpenAI response carried an error: plain string error/,
    'a string error is reported as is';
};

subtest 'OpenAI-compatible: no choices without an error croaks' => sub {
  my $resp = eval { $openai->chat_response( mock_http( { id => 'x', choices => [] } ) ) };
  ok !defined $resp, 'no Response returned';
  like $@, qr/\ALangertha::Engine::OpenAI response contained no choices/, 'empty choices croak';

  eval { $openai->chat_response( mock_http( { id => 'x' } ) ) };
  like $@, qr/\ALangertha::Engine::OpenAI response contained no choices/, 'missing choices croak';
};

subtest 'OpenAI-compatible: a well-formed reply is unchanged' => sub {
  my $resp = $openai->chat_response( mock_http( {
    id => 'c1', model => 'gpt-4o',
    choices => [ { index => 0, message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' } ],
  } ) );
  is "$resp", 'hi', 'content';
  is $resp->finish_reason, 'stop', 'finish_reason';
  ok !$resp->has_refusal, 'no refusal';
};

subtest 'OpenAI-compatible: message.refusal lands on Response.refusal' => sub {
  my $resp = $openai->chat_response( mock_http( {
    id => 'c2', model => 'gpt-4o',
    choices => [ { index => 0,
      message => { role => 'assistant', content => undef, refusal => "I'm sorry, I cannot help with that." },
      finish_reason => 'stop' } ],
  } ) );
  ok defined $resp, 'a refusal is an answer, not an error';
  is "$resp", '', 'content stays empty';
  ok $resp->has_refusal, 'has_refusal';
  is $resp->refusal, "I'm sorry, I cannot help with that.", 'refusal text';
  is $resp->to_hash->{refusal}, $resp->refusal, 'to_hash carries it';
  is $resp->clone_with( content => 'x' )->refusal, $resp->refusal, 'clone_with keeps it';

  $resp = $openai->chat_response( mock_http( {
    choices => [ { message => { content => 'ok', refusal => undef }, finish_reason => 'stop' } ],
  } ) );
  ok !$resp->has_refusal, 'refusal null -> no refusal';
};

subtest 'OpenAI-compatible stream: delta.refusal and top-level error' => sub {
  my $chunk = $openai->parse_stream_chunk(
    { choices => [ { index => 0, delta => { refusal => "I'm sorry" } } ] }, undef, {} );
  ok $chunk && $chunk->has_refusal, 'refusal delta chunk carries refusal';
  is $chunk->refusal, "I'm sorry", 'refusal fragment';
  is $chunk->content, '', 'content empty';

  $chunk = $openai->parse_stream_chunk(
    { choices => [ { index => 0, delta => { content => 'hi' } } ] }, undef, {} );
  ok !$chunk->has_refusal, 'content chunk has no refusal';

  my $got = eval {
    $openrouter->parse_stream_chunk( { error => { message => 'Provider disconnected', code => 'server_error' } }, undef, {} );
  };
  ok !defined $got, 'error chunk returns nothing';
  like $@, qr/\ALangertha::Engine::OpenRouter stream carried an error: Provider disconnected \(server_error\)/,
    'a top-level error chunk croaks, failing the stream';

  is $openai->parse_stream_chunk( { choices => [] }, undef, {} ), undef,
    'an empty-choices frame without error or usage is still skipped';
};

subtest 'Responses API: refusal content part lands on Response.refusal' => sub {
  my $engine = Langertha::Engine::OpenAIResponses->new( api_key => 'k' );
  my $resp = $engine->chat_response( mock_http( {
    id => 'resp_1', model => 'gpt-5', created_at => 1_700_000_000,
    output => [ { type => 'message', status => 'completed', role => 'assistant',
      content => [ { type => 'refusal', refusal => 'I cannot help with that.' } ] } ],
    usage => { input_tokens => 5, output_tokens => 3, total_tokens => 8 },
  } ) );
  is "$resp", '', 'content empty';
  is $resp->refusal, 'I cannot help with that.', 'refusal read from the content part';

  $resp = $engine->chat_response( mock_http( {
    output => [ { type => 'message', status => 'completed',
      content => [ { type => 'output_text', text => 'fine', annotations => [] } ] } ],
  } ) );
  ok !$resp->has_refusal, 'no refusal part -> no refusal';
};

my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );

subtest 'Gemini: a blocked prompt reports its blockReason' => sub {
  my $resp = $gemini->chat_response( mock_http( {
    promptFeedback => { blockReason => 'SAFETY',
      safetyRatings => [ { category => 'HARM_CATEGORY_DANGEROUS_CONTENT', probability => 'HIGH' } ] },
    usageMetadata => { promptTokenCount => 8, totalTokenCount => 8 },
    modelVersion  => 'gemini-2.5-flash',
  } ) );
  ok defined $resp, 'a block is an answer, not an error';
  is "$resp", '', 'content empty';
  is $resp->finish_reason, 'SAFETY', 'finish_reason is the blockReason, verbatim like finishReason';
  is $resp->usage->input_tokens, 8, 'usage still read';
  is $resp->model, 'gemini-2.5-flash', 'model still read';
};

subtest 'Gemini: no candidates and no blockReason croaks' => sub {
  my $resp = eval { $gemini->chat_response( mock_http( { usageMetadata => { promptTokenCount => 1 } } ) ) };
  ok !defined $resp, 'no Response returned';
  like $@, qr/\ALangertha::Engine::Gemini response contained no candidates/, 'croaks naming the engine';

  eval { $gemini->chat_response( mock_http( { candidates => [], error => { message => 'quota', code => 429 } } ) ) };
  like $@, qr/\ALangertha::Engine::Gemini response carried an error: quota \(429\)/,
    'an error object is reported';
};

done_testing;

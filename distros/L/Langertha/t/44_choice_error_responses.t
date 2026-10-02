#!/usr/bin/env perl
# ABSTRACT: Errors inside a choice, a Responses error body and a Gemini stream block are reported, not dropped
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Gemini;

# karr k311, the gaps k301 left (t/44_empty_choice_responses.t):
#  - OpenRouter reports a provider failure inside the choice: the choice
#    carries `error` (NonStreamingChoice / StreamingChoice `error?:
#    ErrorResponse`, finish_reason 'error'), and its documented mid-stream
#    failure frame keeps a choice (delta content '', finish_reason 'error')
#    beside a top-level `error`. Both parsed to an empty success -- the k301
#    croak only fired when there was no choice at all. Shapes from
#    https://openrouter.ai/docs/api-reference/overview (response types) and
#    https://openrouter.ai/docs/api-reference/errors (mid-stream errors).
#  - a Responses API 200 body with an `error` object and no output came back
#    as an empty Response.
#  - a Gemini stream chunk with promptFeedback.blockReason and no candidates
#    was skipped, so a blocked streamed prompt ended with no finish_reason.
#    It is the final chunk now, like k301's non-stream Response.
# Error wording is k301's: "<class> response|stream carried an error:
# <message> (<code>)". Bodies are shaped from the API references, not live
# captures.

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

subtest 'OpenAI-compatible: choices[0].error croaks' => sub {
  my $resp = eval {
    $openrouter->chat_response( mock_http( {
      id => 'gen-1', model => 'openai/gpt-4o', object => 'chat.completion',
      choices => [ {
        finish_reason => 'error', native_finish_reason => undef,
        message => { role => 'assistant', content => '' },
        error => { code => 502, message => 'Provider returned error',
          metadata => { error_type => 'provider_unavailable' } },
      } ],
    } ) );
  };
  ok !defined $resp, 'no Response returned';
  like $@, qr/\ALangertha::Engine::OpenRouter response carried an error: Provider returned error \(502\)/,
    'croak names the engine, the choice error message and code';

  eval { $openai->chat_response( mock_http( {
    choices => [ { finish_reason => 'error', message => { content => undef },
      error => { error => { message => 'wrapped', code => 'server_error' } } } ],
  } ) ) };
  like $@, qr/\ALangertha::Engine::OpenAI response carried an error: wrapped \(server_error\)/,
    'an ErrorResponse wrapped once more under error is unwrapped';

  eval { $openai->chat_response( mock_http( {
    error => { message => 'top level', code => 500 },
    choices => [ { finish_reason => 'error', message => { content => '' } } ],
  } ) ) };
  like $@, qr/\ALangertha::Engine::OpenAI response carried an error: top level \(500\)/,
    'a top-level error beside a choice finishing with "error" croaks';

  my $ok = $openai->chat_response( mock_http( {
    choices => [ { finish_reason => 'stop', message => { content => 'fine' }, error => undef } ],
  } ) );
  is "$ok", 'fine', 'error null on the choice is no error';
};

subtest 'OpenAI-compatible stream: an error on or beside the choice croaks' => sub {
  my $got = eval {
    $openrouter->parse_stream_chunk( {
      id => 'gen-2', object => 'chat.completion.chunk', model => 'openai/gpt-4o', provider => 'OpenAI',
      error => { code => 502, message => 'Provider disconnected',
        metadata => { error_type => 'provider_unavailable' } },
      choices => [ { index => 0, delta => { content => '' }, finish_reason => 'error' } ],
    }, undef, {} );
  };
  ok !defined $got, 'documented mid-stream error frame returns nothing';
  like $@, qr/\ALangertha::Engine::OpenRouter stream carried an error: Provider disconnected \(502\)/,
    'the OpenRouter mid-stream error frame (top-level error, finish_reason error) croaks';

  eval {
    $openrouter->parse_stream_chunk( {
      choices => [ { index => 0, delta => { content => '' }, finish_reason => 'error',
        error => { code => 'overloaded', message => 'Try again' } } ],
    }, undef, {} );
  };
  like $@, qr/\ALangertha::Engine::OpenRouter stream carried an error: Try again \(overloaded\)/,
    'StreamingChoice.error croaks the stream';

  my $chunk = $openai->parse_stream_chunk(
    { choices => [ { index => 0, delta => { content => 'hi' }, finish_reason => undef } ] }, undef, {} );
  is $chunk->content, 'hi', 'an ordinary delta is unchanged';
};

subtest 'Responses API: an error body without output croaks' => sub {
  my $engine = Langertha::Engine::OpenAIResponses->new( api_key => 'k' );
  my $resp = eval {
    $engine->chat_response( mock_http( {
      id => 'resp_x', object => 'response', status => 'failed', model => 'gpt-5',
      error => { code => 'server_error', message => 'The model failed to respond' },
      output => [],
    } ) );
  };
  ok !defined $resp, 'no Response returned';
  like $@, qr/\ALangertha::Engine::OpenAIResponses response carried an error: The model failed to respond \(server_error\)/,
    'empty output with an error croaks, k301 wording';

  my $pplx = Langertha::Engine::Perplexity->new( api_key => 'k' );
  eval { $pplx->chat_response( mock_http( { error => { message => 'no output here' } } ) ) };
  like $@, qr/\ALangertha::Engine::Perplexity response carried an error: no output here at /,
    'missing output with an error croaks on the Agent API too';

  my $ok = $engine->chat_response( mock_http( {
    error => undef, status => 'completed',
    output => [ { type => 'message', content => [ { type => 'output_text', text => 'fine' } ] } ],
  } ) );
  is "$ok", 'fine', 'error null with output is an answer';
};

subtest 'Gemini stream: a blocked prompt ends the stream with its blockReason' => sub {
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
  my $chunk = $gemini->parse_stream_chunk( {
    promptFeedback => { blockReason => 'PROHIBITED_CONTENT' },
    usageMetadata  => { promptTokenCount => 8, totalTokenCount => 8 },
    modelVersion   => 'gemini-2.5-flash',
  } );
  ok defined $chunk, 'the block chunk is not skipped';
  is $chunk->content, '', 'content empty';
  ok $chunk->is_final, 'final chunk';
  is $chunk->finish_reason, 'PROHIBITED_CONTENT', 'finish_reason is the blockReason verbatim';

  is $gemini->parse_stream_chunk( { usageMetadata => { promptTokenCount => 1 } } ), undef,
    'a candidate-less chunk without a block is still skipped';
};

done_testing;

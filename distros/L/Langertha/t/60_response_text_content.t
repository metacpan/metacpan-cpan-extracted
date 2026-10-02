#!/usr/bin/env perl
# ABSTRACT: response_text_content answers chat_response's content; Anthropic croaks on an error in a 200

use strict;
use warnings;

use Test2::Bundle::More;

# karr k338, the two readers k321 left behind.
#
# (1) The Anthropic-compatible chat_response had no guard for an error in a
#     200 body: {"type":"error","error":{...}} (Anthropic's error envelope) or
#     an `error` object without content parsed to content '' -- a failed
#     request that looked like a model that said nothing, where the
#     OpenAI-compatible, Gemini and Responses parsers croak (k301, k311).
#
# (2) response_text_content -- the public raw-body reader the Langfuse
#     plugin's raw-hash path and langertha-raider call -- read the body on its
#     own and disagreed with chat_f: Gemini thought parts came back as answer
#     text, a Mistral content-chunk list as an ARRAY ref. It now answers the
#     content chat_response builds, and still never croaks: plugins call it.

use lib 't/lib';
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny;

use Langertha::Engine::Anthropic;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::AKI;
use Langertha::Engine::Gemini;
use Langertha::Engine::Groq;
use Langertha::Engine::Mistral;
use Langertha::Engine::NousResearch;
use Langertha::Engine::OpenAI;

sub http_for {
  my ( $body, @headers ) = @_;
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json', @headers ], encode_json($body) );
}

# --- (1) Anthropic: an error in a 200 body croaks ---------------------------

subtest 'Anthropic-compatible chat_response croaks on an error in a 200' => sub {
  my $claude = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x' );

  eval { $claude->chat_response( http_for( { type => 'error',
    error => { type => 'overloaded_error', message => 'Overloaded' } } ) ) };
  like( $@, qr/\ALangertha::Engine::Anthropic response carried an error: Overloaded at /,
    'the error envelope croaks with its message' );

  eval { $claude->chat_response( http_for( { error => { message => 'upstream down', code => 502 } } ) ) };
  like( $@, qr/response carried an error: upstream down \(502\)/,
    'an error object without content croaks, code in parentheses (k301 wording)' );

  eval { $claude->chat_response( http_for( { type => 'error' } ) ) };
  like( $@, qr/response carried an error: no error message/,
    'an error envelope without an error object still croaks' );

  my $shim = Langertha::Engine::AKIAnthropic->new( api_key => 'k', model => 'm' );
  eval { $shim->chat_response( http_for( { type => 'error', error => { message => 'nope' } } ) ) };
  like( $@, qr/\ALangertha::Engine::AKIAnthropic response carried an error: nope/,
    'the /anthropic shims share the guard' );

  my $ok = $claude->chat_response( http_for( { id => 'msg_1', type => 'message',
    role => 'assistant', stop_reason => 'end_turn',
    content => [ { type => 'text', text => 'fine' } ] } ) );
  is( $ok->content, 'fine', 'a normal message still parses' );
};

# --- (2) response_text_content answers chat_response's content --------------

my $gemini_body = { responseId => 'r1', modelVersion => 'gemini-x',
  candidates => [ { finishReason => 'STOP', content => { role => 'model', parts => [
    { text => '**Planning** I will just answer.', thought => JSON::MaybeXS::true() },
    { text => 'Answer: 4' },
  ] } } ] };

subtest 'Gemini thought parts stay out of the text' => sub {
  my $gemini = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x' );
  is( $gemini->response_text_content($gemini_body), 'Answer: 4', 'only the answer part' );
};

subtest 'a Mistral content-chunk list becomes its text' => sub {
  my $mistral = Langertha::Engine::Mistral->new( api_key => 'k', model => 'magistral-medium-latest' );
  my $data = decode_json( path('t/data/mistral_magistral_doc_response.json')->slurp_raw );
  my $text = $mistral->response_text_content($data);
  is( ref $text, '', 'a string, not a reference' );
  is( $text, '2 + 2 = **4**', 'the text chunk' );
};

subtest 'Anthropic thinking blocks stay out' => sub {
  my $claude = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x' );
  is( $claude->response_text_content( { type => 'message', role => 'assistant', content => [
    { type => 'thinking', thinking => 'Let me add.', signature => 'sig' },
    { type => 'text', text => 'Answer: 4' },
  ] } ), 'Answer: 4', 'text blocks only' );
};

subtest 'a hermes engine: think filtered, call tags stripped' => sub {
  my $nous = Langertha::Engine::NousResearch->new( api_key => 'k', think_tag_filter => 1 );
  my $data = { choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant',
    content => "<think>maybe <tool_call>{\"name\":\"x\",\"arguments\":{}}</tool_call></think>Before "
      . "<tool_call>{\"name\":\"echo\",\"arguments\":{}}</tool_call> after" } } ] };
  my $text = $nous->response_text_content($data);
  unlike( $text, qr/think|tool_call|maybe/, 'no thinking, no call markup' );
  like( $text, qr/\ABefore\s+after\z/, 'the answer text' );
};

subtest 'AKI native answers the text without recursing through chat_response' => sub {
  my $aki = Langertha::Engine::AKI->new( api_key => 'k', model => 'llama3_8b_chat' );
  my $data = { success => JSON::MaybeXS::true(),
    text => "Sure. <tool_call>{\"name\":\"echo\",\"arguments\":{\"x\":1}}</tool_call>" };
  is( $aki->response_text_content($data), 'Sure.', 'call tags stripped' );
  my $reply = $aki->chat_response( http_for($data) );
  is( $reply->content, 'Sure.', 'chat_response content' );
  is( scalar @{ $reply->tool_calls }, 1, 'and the call' );
};

subtest 'never croaks: a body chat_response rejects falls back' => sub {
  my $openai = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x' );
  my $text = eval { $openai->response_text_content( { error => { message => 'boom' } } ) };
  is( $@, '', 'an error body does not croak' );
  is( $text, '', 'and has no text' );
  is( eval { $openai->response_text_content( {} ) }, '', 'an empty body gives ""' );
  is( eval { $openai->response_text_content(undef) }, '', 'so does undef' );

  my $claude = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x' );
  is( eval { $claude->response_text_content( { type => 'error', error => { message => 'x' } } ) }, '',
    'an Anthropic error envelope gives "" instead of the croak' );
};

subtest 'the engine rate limit is left as it was' => sub {
  my $groq = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  my $body = { choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => 'hi' } } ] };
  $groq->chat_response( http_for( $body,
    'x-ratelimit-remaining-requests' => 7, 'x-ratelimit-limit-requests' => 10 ) );
  is( $groq->rate_limit->requests_remaining, 7, 'a real response set the rate limit' );
  is( $groq->response_text_content($body), 'hi', 'the reader answers' );
  ok( $groq->has_rate_limit, 'the rate limit is still there' );
  is( $groq->rate_limit->requests_remaining, 7, 'unchanged' );

  my $fresh = Langertha::Engine::Groq->new( api_key => 'k', model => 'm' );
  $fresh->response_text_content($body);
  ok( !$fresh->has_rate_limit, 'no rate limit invented where there was none' );
};

done_testing;

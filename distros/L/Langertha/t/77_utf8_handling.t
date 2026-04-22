#!/usr/bin/env perl
# ABSTRACT: Regression tests for non-ASCII JSON handling through the pipeline

use strict;
use warnings;
use utf8;

use Test2::Bundle::More;
use Encode qw( encode_utf8 is_utf8 );
use HTTP::Response;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::NousResearch;

# Build a raw HTTP::Response carrying a UTF-8 JSON body with non-ASCII text.
# Emulates what LWP::UserAgent hands back: bytes in $response->content,
# charset-decoded Perl-Unicode in $response->decoded_content.
sub mock_response {
  my ( $body_hashref ) = @_;
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
  my $bytes = $json->encode($body_hashref);
  my $res = HTTP::Response->new(200, 'OK',
    [ 'Content-Type' => 'application/json; charset=utf-8' ],
    $bytes,
  );
  return $res;
}

my $openai = Langertha::Engine::OpenAI->new(
  api_key       => 'test-key',
  model         => 'gpt-4o-mini',
  system_prompt => 'ok',
);

# 1. parse_response with non-ASCII body (Umlauts, em-dash, CJK).
{
  my $payload = {
    id      => 'chatcmpl-1',
    model   => 'gpt-4o-mini',
    choices => [{
      message       => { role => 'assistant', content => 'Grüße — 你好 😀' },
      finish_reason => 'stop',
    }],
  };
  my $data = $openai->parse_response(mock_response($payload));
  is( $data->{choices}[0]{message}{content}, 'Grüße — 你好 😀',
      'parse_response round-trips non-ASCII content' );
  ok( is_utf8($data->{choices}[0]{message}{content}),
      'decoded content is a Perl-Unicode string (utf8 flag set)' );
}

# 2. chat_response (full Langertha::Response) with non-ASCII.
{
  my $payload = {
    id      => 'chatcmpl-2',
    model   => 'gpt-4o-mini',
    choices => [{
      message       => { role => 'assistant', content => 'Größe: 42°C' },
      finish_reason => 'stop',
    }],
    usage   => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
  };
  my $response = $openai->chat_response(mock_response($payload));
  is( $response->content, 'Größe: 42°C', 'Langertha::Response content preserved' );
}

# 3. extract_tool_call with non-ASCII arguments (the original bug site).
{
  my $args_hash = { city => 'Düsseldorf', note => 'Grüße — 😀' };
  my $args_json = JSON::MaybeXS->new->canonical(1)->encode($args_hash); # unicode string
  my $tool_call = {
    id       => 'call_abc',
    type     => 'function',
    function => { name => 'lookup', arguments => $args_json },
  };
  my ( $name, $args ) = $openai->extract_tool_call($tool_call);
  is( $name, 'lookup', 'tool name extracted' );
  is_deeply( $args, $args_hash, 'non-ASCII tool arguments decoded correctly' );
}

# 4. response_tool_calls + extract_tool_call end-to-end via parse_response
#    so the tool-call arguments travel through the full bytes->perl pipeline.
{
  my $args_hash = { message => 'Schöne Grüße — 🚀' };
  my $args_json = JSON::MaybeXS->new->canonical(1)->encode($args_hash);
  my $payload = {
    id      => 'chatcmpl-3',
    model   => 'gpt-4o-mini',
    choices => [{
      message => {
        role       => 'assistant',
        content    => undef,
        tool_calls => [{
          id       => 'call_xyz',
          type     => 'function',
          function => { name => 'echo', arguments => $args_json },
        }],
      },
      finish_reason => 'tool_calls',
    }],
  };
  my $data  = $openai->parse_response(mock_response($payload));
  my $calls = $openai->response_tool_calls($data);
  is( scalar @$calls, 1, 'one tool call found' );
  my ( $name, $args ) = $openai->extract_tool_call($calls->[0]);
  is( $name, 'echo', 'tool name after full pipeline' );
  is_deeply( $args, $args_hash, 'tool arguments after full pipeline' );
}

# 5. Anthropic path: response_text_content with non-ASCII.
{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key       => 'test-key',
    model         => 'claude-sonnet-4-6',
    response_size => 1024,
  );
  my $payload = {
    id          => 'msg_1',
    model       => 'claude-sonnet-4-6',
    stop_reason => 'end_turn',
    content     => [
      { type => 'text', text => 'Hallo Welt — 🎉' },
    ],
  };
  my $data = $anthropic->parse_response(mock_response($payload));
  is( $anthropic->response_text_content($data), 'Hallo Welt — 🎉',
      'Anthropic content preserved through parse_response' );
}

# 6. HermesTools: XML-embedded tool call JSON with non-ASCII arguments.
{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key       => 'test-key',
    model         => 'Hermes-3-Llama-3.1-70B',
    system_prompt => 'ok',
  );
  my $args_hash = { place => 'Zürich', greet => 'Grüße' };
  my $inner_json = JSON::MaybeXS->new->canonical(1)->encode({
    name => 'lookup', arguments => $args_hash,
  });
  my $payload = {
    id      => 'chatcmpl-h1',
    model   => 'Hermes-3-Llama-3.1-70B',
    choices => [{
      message => {
        role    => 'assistant',
        content => "some prefix\n<tool_call>\n$inner_json\n</tool_call>\ntail",
      },
      finish_reason => 'stop',
    }],
  };
  my $data  = $nous->parse_response(mock_response($payload));
  my $calls = $nous->response_tool_calls($data);
  is( scalar @$calls, 1, 'hermes tool call parsed' );
  is( $calls->[0]{name}, 'lookup', 'hermes tool name' );
  is_deeply( $calls->[0]{arguments}, $args_hash,
             'hermes non-ASCII arguments preserved' );
}

# 7. decode_json_text helper directly with a Perl-Unicode string.
{
  my $unicode_str = '{"city":"Düsseldorf","emoji":"🚀"}';
  ok( is_utf8($unicode_str), 'input is Perl-Unicode' );
  my $data = $openai->decode_json_text($unicode_str);
  is( $data->{city},  'Düsseldorf', 'decode_json_text: Umlaut preserved' );
  is( $data->{emoji}, '🚀',           'decode_json_text: emoji preserved' );

  is( $openai->decode_json_text(undef), undef, 'decode_json_text: undef passthrough' );
}

done_testing;

#!/usr/bin/env perl
# ABSTRACT: JSON strings nested inside a JSON body carry characters, the transport encodes once

use strict;
use warnings;
use utf8;

use Test2::Bundle::More;
use Test2::Plugin::UTF8;
use HTTP::Response;
use JSON::MaybeXS;

use Langertha::ToolCall;
use Langertha::ToolResult;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::Anthropic;
use Langertha::Engine::AKIAnthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::NousResearch;
use Langertha::Engine::AKI;
use Langertha::Engine::VLLMHook;


# Why (karr k252, ADR 0010 encoding contract): several wires carry JSON as a
# *string* inside the JSON body (OpenAI function.arguments, tool-result
# content, Responses function_call_output.output, the hermes <tool_call> /
# <tool_response> payload, AKI native chat_context). Value objects and
# serializers must hand back CHARACTER strings; the request body is encoded to
# UTF-8 bytes exactly once, by Role::JSON at the transport. A serializer that
# emits bytes gets encoded a second time by the body encoder, and the provider
# (or knarr's client) reads "Köln" as "KÃ¶ln". Inbound, the wire bytes are
# decoded exactly once, so tool arguments arrive as characters.

my $bytes_json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );   # wire bytes
my $chars_json = JSON::MaybeXS->new( utf8 => 0, canonical => 1 );   # nested strings

my $city  = 'Köln';
my $tokyo = '東京 😀';
my $args  = { city => $city, note => $tokyo };
my $text  = "Wetter in $city: 12°C, $tokyo";

# Decode an HTTP::Request body once, the way a provider does.
sub body_of { $bytes_json->decode( $_[0]->content ) }

sub reply {
  my ($data) = @_;
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json; charset=utf-8' ],
    $bytes_json->encode($data) );
}

my $tc = Langertha::ToolCall->new( name => 'weather', arguments => $args, id => 'call_1' );
my $tr_args = sub {
  ( id => 'call_1', name => 'weather', content => [ { type => 'text', text => $text } ] )
};

# --- (1) value objects emit character strings that round-trip -------------

{
  my $s = $tc->to_openai->{function}{arguments};
  ok( index( $s, $city ) >= 0, 'ToolCall->to_openai arguments carry the characters "Köln"' );
  is_deeply( $chars_json->decode($s), $args, 'to_openai arguments round-trip as characters' );
}

for my $fmt (qw( openai ollama )) {
  my $s = Langertha::ToolResult->new( $tr_args->() )->to($fmt)->{content};
  ok( index( $s, $city ) >= 0, "ToolResult->to('$fmt') content carries characters" );
  is( $s, $text, "ToolResult->to('$fmt') content round-trips" );
}

{
  my $s = Langertha::ToolResult->new( $tr_args->() )->to('responses')->{output};
  ok( index( $s, $city ) >= 0, "ToolResult->to('responses') output carries characters" );
  is( $s, $text, "ToolResult->to('responses') output round-trips" );
}

{
  my $s = Langertha::ToolResult->new( $tr_args->() )->to('hermes');
  ok( index( $s, $city ) >= 0, "ToolResult->to('hermes') block carries characters" );
  my ($payload) = $s =~ m{<tool_response>\s*(.*?)\s*</tool_response>}s;
  is( $chars_json->decode($payload)->{content}, $text, 'hermes result payload round-trips' );
}

{
  my $s = '<tool_call>' . $chars_json->encode( { name => 'weather', arguments => $args } ) . '</tool_call>';
  my ( $clean, $calls ) = Langertha::ToolCall->extract_hermes_from_text($s);
  is( scalar @$calls, 1, 'extract_hermes_from_text lifts a call with non-ASCII arguments' );
  is_deeply( $calls->[0] && $calls->[0]->arguments, $args,
    'extract_hermes_from_text arguments are characters' );
}

# --- (2) request bodies decode back to the characters exactly once --------

{
  my $e = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
  my $raw = { choices => [ { message => {
    role => 'assistant', content => undef, tool_calls => [ $tc->to_openai ] } } ] };
  my @msgs = ( { role => 'user', content => $city },
    $e->format_tool_results( $raw, [ { tool_call => { id => 'call_1' },
      result => { content => [ { type => 'text', text => $text } ] } } ] ) );
  my $body = body_of( $e->chat_request( \@msgs ) );
  my ($assistant) = grep { $_->{role} eq 'assistant' } @{ $body->{messages} };
  my ($tool)      = grep { $_->{role} eq 'tool' } @{ $body->{messages} };
  is_deeply( $chars_json->decode( $assistant->{tool_calls}[0]{function}{arguments} ), $args,
    'OpenAI body: echoed tool_call arguments decode to the original characters' );
  is( $tool->{content}, $text,
    'OpenAI body: tool result content decodes to the original characters' );
}

{
  my $e = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro' );
  my $raw = { output => [ { type => 'function_call', call_id => 'call_1', name => 'weather',
    arguments => $chars_json->encode($args) } ] };
  my @items = ( { role => 'user', content => $city },
    $e->format_tool_results( $raw, [ { tool_call => { call_id => 'call_1' },
      result => { content => [ { type => 'text', text => $text } ] } } ] ) );
  my $body = body_of( $e->chat_request( \@items ) );
  my ($out) = grep { ( $_->{type} // '' ) eq 'function_call_output' } @{ $body->{input} };
  is( $out->{output}, $text,
    'Responses body: function_call_output decodes to the original characters' );
  my ($fc) = grep { ( $_->{type} // '' ) eq 'function_call' } @{ $body->{input} };
  is_deeply( $chars_json->decode( $fc->{arguments} ), $args,
    'Responses body: echoed function_call arguments decode to the original characters' );
}

{
  my $e = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6' );
  my $raw = { content => [ { type => 'tool_use', id => 'call_1', name => 'weather', input => $args } ] };
  my @msgs = ( { role => 'user', content => $city },
    $e->format_tool_results( $raw, [ { tool_call => { id => 'call_1' },
      result => { content => [ { type => 'text', text => $text } ] } } ] ) );
  my $body = body_of( $e->chat_request( \@msgs ) );
  is_deeply( $body->{messages}[1]{content}[0]{input}, $args,
    'Anthropic body: tool_use input decodes to the original characters' );
  is( $body->{messages}[2]{content}[0]{content}[0]{text}, $text,
    'Anthropic body: tool_result text decodes to the original characters' );
}

{
  my $e = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-flash' );
  my $raw = { candidates => [ { content => { role => 'model',
    parts => [ { functionCall => { name => 'weather', args => $args } } ] } } ] };
  my @msgs = ( { role => 'user', content => $city },
    $e->format_tool_results( $raw, [ { tool_call => { functionCall => { name => 'weather' } },
      result => { content => [ { type => 'text', text => $text } ] } } ] ) );
  my $body = body_of( $e->chat_request( \@msgs ) );
  my @parts = map { @{ $_->{parts} // [] } } @{ $body->{contents} };
  my ($call) = grep { $_->{functionCall} } @parts;
  my ($resp) = grep { $_->{functionResponse} } @parts;
  is_deeply( $call->{functionCall}{args}, $args, 'Gemini body: functionCall args decode to characters' );
  is( $resp->{functionResponse}{response}{result}, $text,
    'Gemini body: functionResponse decodes to the original characters' );
}

{
  my $e = Langertha::Engine::Ollama->new( url => 'http://localhost:11434', model => 'm' );
  my $raw = { message => { role => 'assistant', content => '', tool_calls => [ $tc->to_ollama ] } };
  my @msgs = ( { role => 'user', content => $city },
    $e->format_tool_results( $raw, [ { tool_call => {},
      result => { content => [ { type => 'text', text => $text } ] } } ] ) );
  my $body = body_of( $e->chat_request( \@msgs ) );
  my ($tool) = grep { $_->{role} eq 'tool' } @{ $body->{messages} };
  is( $tool->{content}, $text,
    'Ollama body: tool result content decodes to the original characters' );
}

{
  my $e = Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B' );
  my $tools = $e->format_tools( [ { name => 'weather', description => "Wetter in $city",
    inputSchema => { type => 'object', properties => { city => { type => 'string' } } } } ] );
  my $raw = { choices => [ { message => { role => 'assistant',
    content => '<tool_call>' . $chars_json->encode( { name => 'weather', arguments => $args } ) . '</tool_call>' } } ] };
  my @msgs = ( { role => 'user', content => $city },
    $e->format_tool_results( $raw, [ { tool_call => { name => 'weather' },
      result => { content => [ { type => 'text', text => $text } ] } } ] ) );
  my $body = body_of( $e->build_tool_chat_request( \@msgs, $tools ) );
  my ($system) = grep { $_->{role} eq 'system' } @{ $body->{messages} };
  ok( index( $system->{content}, "Wetter in $city" ) >= 0,
    'hermes body: the tool prompt carries the tool description as characters' );
  my ($tool) = grep { $_->{role} eq 'tool' } @{ $body->{messages} };
  my ($payload) = $tool->{content} =~ m{<tool_response>\s*(.*?)\s*</tool_response>}s;
  is( $chars_json->decode( $payload // 'null' )->{content}, $text,
    'hermes body: tool_response payload decodes to the original characters' );
}

{
  my $e = Langertha::Engine::AKI->new( api_key => 'k', model => 'llama3_8b_chat' );
  my $body = body_of( $e->chat_request( [ { role => 'user', content => $text } ] ) );
  my $context = $chars_json->decode( $body->{chat_context} );
  my ($user) = grep { $_->{role} eq 'user' } @$context;
  is( $user->{content}, $text, 'AKI native body: chat_context decodes to the original characters' );
}

{
  # vLLM's vllm_xargs takes scalars only, so nested values ride as JSON strings.
  my $e = Langertha::Engine::VLLMHook->new( url => 'http://test.invalid:8770/v1',
    vllm_xargs => { steer => { label => $city } } );
  my $body = body_of( $e->chat('Hello') );
  is( $chars_json->decode( $body->{vllm_xargs}{steer} )->{label}, $city,
    'VLLMHook body: nested vllm_xargs decode to the original characters' );
}

# --- (3) inbound: wire bytes decoded once, arguments are characters -------

{
  my $e = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' );
  my $r = $e->chat_response( reply( { choices => [ { finish_reason => 'tool_calls',
    message => { role => 'assistant', content => undef, tool_calls => [ { id => 'call_1',
      type => 'function', function => { name => 'weather', arguments => $chars_json->encode($args) } } ] } } ] } ) );
  is_deeply( $r->tool_calls->[0]->arguments, $args, 'OpenAI inbound: tool_calls arguments are characters' );
}

{
  my $e = Langertha::Engine::OpenAIResponses->new( api_key => 'k', model => 'gpt-5.5-pro' );
  my $r = $e->chat_response( reply( { output => [ { type => 'function_call', call_id => 'call_1',
    name => 'weather', arguments => $chars_json->encode($args) } ] } ) );
  is_deeply( $r->tool_calls->[0]->arguments, $args, 'Responses inbound: tool_calls arguments are characters' );
}

{
  my $e = Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-sonnet-4-6' );
  my $r = $e->chat_response( reply( { content => [
    { type => 'tool_use', id => 'call_1', name => 'weather', input => $args } ] } ) );
  is_deeply( $r->tool_calls->[0]->arguments, $args, 'Anthropic inbound: tool_calls arguments are characters' );
}

{
  # The /anthropic shims route response_format through a synthetic tool and lift
  # its input into content: that lifted JSON is text, so characters too.
  my $e = Langertha::Engine::AKIAnthropic->new( api_key => 'k' );
  my $r = $e->chat_response( reply( { content => [
    { type => 'tool_use', id => 'call_1', name => 'structured_output', input => $args } ] } ), 1 );
  ok( index( $r->content, $city ) >= 0, 'Anthropic-shim response_format lift: content is characters' );
  is_deeply( $chars_json->decode( $r->content ), $args, 'Anthropic-shim lifted content round-trips' );
}

{
  my $e = Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B' );
  my ( $clean, $calls ) = $e->_hermes_split_text(
    '<tool_call>' . $chars_json->encode( { name => 'weather', arguments => $args } ) . '</tool_call>' );
  is_deeply( $calls->[0]{arguments}, $args, 'hermes inbound: arguments are characters' );
}

done_testing;

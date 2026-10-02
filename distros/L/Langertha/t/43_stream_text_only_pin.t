#!/usr/bin/env perl
# ABSTRACT: text-only streams parse to the same chunks, field for field, on every dialect parser
use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Engine::OpenAI;
use Langertha::Engine::DeepSeek;
use Langertha::Engine::vLLM;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::Perplexity;

# karr k221 teaches the Chat-Completions, Anthropic, Gemini and Ollama-native
# stream parsers to assemble tool calls, which means giving two of them
# per-stream state and changing what content_block_stop / finish chunks
# return. A stream that carries no tool call must not notice: every chunk it
# yields keeps the same content, is_final, finish_reason, model, usage,
# cached_tokens, thinking, citations and raw payload, in the same order, and
# still carries no tool_calls. This file pins that against a golden snapshot
# taken from the parsers BEFORE k221 (t/data/stream_text_only_golden.json),
# over the text-only streams the existing streaming tests use plus the
# verbatim Perplexity Agent capture. Each stream is read three ways: the sync
# process_stream_data path, the chat_stream_realtime_f buffer path fed whole,
# and the same buffer path fed one byte at a time.
#
# Intended changes since: karr k222 added finish_reason 'stop' to the final
# chunk of the Perplexity capture (the Responses walker's value, as on
# chat_response); nothing else in the snapshot moved. karr k298 added the
# openai_usage include_usage frame (choices []) as a content-less, non-final
# usage chunk, and message_start's input_tokens and model onto the
# anthropic_text message_delta / message_stop chunks; additions only.
#
# Regenerate only for an intended change:
#   LANGERTHA_REGEN_STREAM_GOLDEN=1 prove -l t/43_stream_text_only_pin.t

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1, pretty => 1 );
my $golden_file = path('t/data/stream_text_only_golden.json');

my %engine = (
  openai     => Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-4o-mini' ),
  deepseek   => Langertha::Engine::DeepSeek->new( api_key => 'k', model => 'deepseek-reasoner' ),
  vllm       => Langertha::Engine::vLLM->new( url => 'http://x' ),
  anthropic  => Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-opus-4-8' ),
  gemini     => Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview' ),
  ollama     => Langertha::Engine::Ollama->new( url => 'http://test.invalid:11434', model => 'qwen3:8b' ),
  perplexity => Langertha::Engine::Perplexity->new( api_key => 'k' ),
);

my @streams = (
  [ openai_basic => openai => <<'SSE' ],
data: {"id":"1","choices":[{"delta":{"content":"Hello"}}]}

data: {"id":"2","choices":[{"delta":{"content":" World"}}]}

data: {"id":"3","choices":[{"delta":{},"finish_reason":"stop"}]}

data: [DONE]

SSE
  [ openai_usage => openai => <<'SSE' ],
data: {"id":"c","model":"gpt-4o-mini","choices":[{"index":0,"delta":{"role":"assistant","content":""},"finish_reason":null}]}

data: {"id":"c","model":"gpt-4o-mini","choices":[{"index":0,"delta":{"content":"Hi"},"finish_reason":null}]}

data: {"id":"c","model":"gpt-4o-mini","choices":[{"index":0,"delta":{},"finish_reason":"length"}]}

data: {"id":"c","model":"gpt-4o-mini","choices":[],"usage":{"prompt_tokens":9,"completion_tokens":1,"total_tokens":10,"prompt_tokens_details":{"cached_tokens":4}}}

data: {"id":"c","model":"gpt-4o-mini","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":9,"completion_tokens":1,"total_tokens":10,"prompt_tokens_details":{"cached_tokens":4}}}

data: [DONE]

SSE
  [ deepseek_reasoning => deepseek => <<'SSE' ],
data: {"choices":[{"delta":{"reasoning_content":"Let me "}}]}

data: {"choices":[{"delta":{"reasoning_content":"think."}}]}

data: {"choices":[{"delta":{"content":"The answer"}}]}

data: {"choices":[{"delta":{},"finish_reason":"stop"}]}

data: [DONE]

SSE
  [ vllm_bare_reasoning_unterminated => vllm =>
    qq{data: {"choices":[{"delta":{"reasoning":"bare "}}]}\n\n}
    . qq{data: {"choices":[{"delta":{"content":"done"},"finish_reason":"stop"}]}} ],
  [ anthropic_text => anthropic => <<'SSE' ],
event: message_start
data: {"type":"message_start","message":{"id":"msg_1","model":"claude-opus-4-8","usage":{"input_tokens":12}}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}

event: ping
data: {"type":"ping"}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":" World"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn","stop_sequence":null},"usage":{"output_tokens":15}}

event: message_stop
data: {"type":"message_stop"}

SSE
  [ anthropic_thinking => anthropic => <<'SSE' ],
event: message_start
data: {"type":"message_start","message":{"id":"msg_2"}}

event: content_block_start
data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"Let me "}}

event: content_block_delta
data: {"type":"content_block_delta","index":0,"delta":{"type":"signature_delta","signature":"sigabc"}}

event: content_block_stop
data: {"type":"content_block_stop","index":0}

event: content_block_start
data: {"type":"content_block_start","index":1,"content_block":{"type":"text","text":""}}

event: content_block_delta
data: {"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"Answer"}}

event: content_block_stop
data: {"type":"content_block_stop","index":1}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":7}}

event: message_stop
data: {"type":"message_stop"}

SSE
  [ gemini_thought => gemini => join( "\n",
    'data: {"candidates":[{"content":{"parts":[{"text":"plan ","thought":true}],"role":"model"}}]}',
    'data: {"candidates":[{"content":{"parts":[{"text":"the "}],"role":"model"}}],"modelVersion":"gemini-3-flash-preview"}',
    'data: {"candidates":[{"content":{"parts":[{"text":"answer"}],"role":"model"},"finishReason":"STOP"}],"usageMetadata":{"promptTokenCount":4,"candidatesTokenCount":2,"totalTokenCount":6}}',
  ) . "\n\n" ],
  [ ollama_thinking => ollama => <<'NDJSON' ],
{"model":"qwen3:8b","message":{"role":"assistant","thinking":"Let me ","content":""},"done":false}
{"model":"qwen3:8b","message":{"role":"assistant","content":"Hello!"},"done":false}
{"model":"qwen3:8b","message":{"role":"assistant","content":""},"done":true,"done_reason":"stop","eval_count":5,"prompt_eval_count":11}
NDJSON
  [ perplexity_capture => perplexity => path('t/data/perplexity_agent_stream.sse')->slurp_raw ],
);

sub snapshot {
  my ($chunks) = @_;
  return [ map { my $c = $_; +{
    content  => $c->content,
    is_final => $c->is_final ? 1 : 0,
    tool_calls => $c->has_tool_calls ? 1 : 0,
    map { my ( $attr, $pred ) = @$_; $c->$pred ? ( $attr => $c->$attr ) : () }
      [ finish_reason => 'has_finish_reason' ], [ model => 'has_model' ],
      [ usage => 'has_usage' ], [ cached_tokens => 'has_cached_tokens' ],
      [ thinking => 'has_thinking' ], [ citations => 'has_citations' ],
      [ raw => 'has_raw' ],
  } } @$chunks ];
}

my %got;
for my $stream (@streams) {
  my ( $name, $which, $body ) = @$stream;
  my $engine = $engine{$which};
  my $format = $engine->stream_format;

  my $sync = $engine->process_stream_data($body);

  my $buffer = $body;
  my $whole = [ @{ $engine->_process_stream_buffer( \$buffer, $format ) },
                @{ $engine->_process_stream_buffer( \$buffer, $format, 1 ) } ];

  my @bytes;
  $buffer = '';
  for my $byte ( split //, $body ) {
    $buffer .= $byte;
    push @bytes, @{ $engine->_process_stream_buffer( \$buffer, $format ) };
  }
  push @bytes, @{ $engine->_process_stream_buffer( \$buffer, $format, 1 ) };

  $got{$name} = {
    sync          => snapshot($sync),
    buffer_whole  => snapshot($whole),
    buffer_bytes  => snapshot( \@bytes ),
  };
}

if ( $ENV{LANGERTHA_REGEN_STREAM_GOLDEN} ) {
  $golden_file->spew_raw( $json->encode( \%got ) );
  pass('golden snapshot regenerated');
  done_testing;
  exit;
}

my $golden = $json->decode( $golden_file->slurp_raw );
is_deeply( [ sort keys %got ], [ sort keys %$golden ], 'same set of pinned streams' );
for my $stream (@streams) {
  my $name = $stream->[0];
  for my $path (qw( sync buffer_whole buffer_bytes )) {
    is_deeply( $got{$name}{$path}, $golden->{$name}{$path},
      "$name via $path: chunks unchanged, field for field" );
  }
}

done_testing;

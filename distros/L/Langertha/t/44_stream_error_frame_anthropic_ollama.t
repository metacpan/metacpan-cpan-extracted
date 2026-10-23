#!/usr/bin/env perl
# ABSTRACT: a mid-stream error frame croaks on the Anthropic and Ollama stream parsers (sync + async)
use strict;
use warnings;
use Test2::Bundle::More;

use Langertha::Engine::Anthropic;
use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Engine::Ollama;

# karr k378: k301/k311/k317 made an error frame fail the stream for the
# OpenAI-compatible, Gemini and Responses parsers. The Anthropic `event: error`
# and Ollama's NDJSON {"error":"..."} line were dropped, so the caller got the
# partial text as a complete answer. Bodies are shaped from the API references.

my $sse = join '', map {"$_\n\n"}
  qq{event: message_start\ndata: {"type":"message_start","message":{"model":"claude","usage":{"input_tokens":5}}}},
  qq{event: content_block_delta\ndata: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Half an ans"}}},
  qq{event: error\ndata: {"type":"error","error":{"type":"overloaded_error","message":"Overloaded"}}};

my $nd = qq{{"message":{"content":"Half an ans"},"done":false}\n}
       . qq{{"error":"model runner has unexpectedly stopped"}\n};

for my $case (
  [ 'Anthropic',        Langertha::Engine::Anthropic->new( api_key => 'x' ),        'sse',    $sse, qr/Overloaded/ ],
  [ 'MiniMaxAnthropic', Langertha::Engine::MiniMaxAnthropic->new( api_key => 'x' ), 'sse',    $sse, qr/Overloaded/ ],
  [ 'Ollama',           Langertha::Engine::Ollama->new( url => 'http://x', model => 'm' ), 'ndjson', $nd, qr/model runner has unexpectedly stopped/ ],
) {
  my ( $name, $engine, $format, $body, $text ) = @$case;
  my $class = ref $engine;

  eval { $engine->process_stream_data($body) };
  like $@, qr/\A\Q$class\E stream carried an error: $text/, "$name: sync parser croaks";

  my $buffer = $body;
  eval { $engine->_process_stream_buffer( \$buffer, $format, 1, $engine->_stream_parse_state ) };
  like $@, qr/\A\Q$class\E stream carried an error: $text/, "$name: async buffer parser croaks";
}

# Healthy streams are untouched.
my $ok = Langertha::Engine::Ollama->new( url => 'http://x', model => 'm' );
my $chunks = $ok->process_stream_data(qq{{"message":{"content":"hi"},"done":true,"done_reason":"stop"}\n});
is scalar @$chunks, 1, 'healthy Ollama stream still yields its chunk';
ok $chunks->[0]->is_final, 'and it is final';

done_testing;

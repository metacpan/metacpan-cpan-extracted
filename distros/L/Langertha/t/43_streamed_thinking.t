#!/usr/bin/env perl
# ABSTRACT: streamed thinking/reasoning deltas fill Stream::Chunk->thinking and aggregate (karr k129)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::DeepSeek;
use Langertha::Engine::vLLM;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::LMStudio;
use HTTP::Response;

# The streaming half of k129: each dialect stream parser must fill
# Stream::Chunk->thinking from ITS verified delta spelling (langertha-llm-advisor
# 2026-09-01 table), and Role::Chat::aggregate_thinking must reassemble the
# fragments the way content is reassembled. All fixtures are mocked SSE/NDJSON
# bodies -- no live API calls.

my $TRUE = JSON->true;
my $json_lms = JSON::MaybeXS->new( utf8 => 1 );

# --------------------------------------------------------------------------
# OpenAI-compatible: delta.reasoning_content (DeepSeek/SGLang/Moonshot/xAI)
# --------------------------------------------------------------------------
{
  my $deepseek = Langertha::Engine::DeepSeek->new(
    api_key => 'k', model => 'deepseek-reasoner',
  );

  my $sse = <<'SSE';
data: {"choices":[{"delta":{"reasoning_content":"Let me "}}]}

data: {"choices":[{"delta":{"reasoning_content":"think."}}]}

data: {"choices":[{"delta":{"content":"The answer"}}]}

data: {"choices":[{"delta":{"content":" is 4."}}]}

data: {"choices":[{"delta":{},"finish_reason":"stop"}]}

data: [DONE]

SSE

  my $chunks = $deepseek->process_stream_data($sse);
  is($chunks->[0]->thinking, 'Let me ', 'DeepSeek: first reasoning_content delta on ->thinking');
  ok($chunks->[0]->has_thinking, 'DeepSeek: has_thinking true on a reasoning delta');
  is($chunks->[1]->thinking, 'think.', 'DeepSeek: second reasoning_content delta');
  ok(!$chunks->[2]->has_thinking, 'DeepSeek: a content-only delta carries no thinking');
  is($deepseek->aggregate_thinking($chunks), 'Let me think.',
    'DeepSeek: aggregate_thinking reassembles the reasoning_content deltas');
  is(join('', map { $_->content } @$chunks), 'The answer is 4.',
    'DeepSeek: content aggregation unaffected');
}

# --------------------------------------------------------------------------
# OpenAI-compatible: bare delta.reasoning (vLLM renamed from reasoning_content)
# --------------------------------------------------------------------------
{
  my $vllm = Langertha::Engine::vLLM->new(url => 'http://x');

  my $sse = <<'SSE';
data: {"choices":[{"delta":{"reasoning":"bare "}}]}

data: {"choices":[{"delta":{"reasoning":"reasoning"}}]}

data: {"choices":[{"delta":{"content":"done"},"finish_reason":"stop"}]}

SSE

  my $chunks = $vllm->process_stream_data($sse);
  is($chunks->[0]->thinking, 'bare ', 'vLLM: bare reasoning delta on ->thinking');
  is($vllm->aggregate_thinking($chunks), 'bare reasoning',
    'vLLM: aggregate_thinking reassembles the bare reasoning deltas');
}

# --------------------------------------------------------------------------
# !ref guard: OpenRouter streams delta.reasoning_details (ARRAY), never a
# delta.reasoning string. The array must not crash the Str thinking field and
# must not be lifted -- mirrors the landed non-stream chat_response guard.
# --------------------------------------------------------------------------
{
  my $router = Langertha::Engine::OpenRouter->new(api_key => 'k', model => 'x/y');

  my $sse = <<'SSE';
data: {"choices":[{"delta":{"reasoning_details":[{"type":"reasoning.text","text":"block"}]}}]}

data: {"choices":[{"delta":{"content":"answer"},"finish_reason":"stop"}]}

SSE

  my $chunks = eval { $router->process_stream_data($sse) };
  ok(!$@, 'OpenRouter: a structured reasoning_details ARRAY delta does not die')
    or diag($@);
  ok($chunks && !$chunks->[0]->has_thinking,
    'OpenRouter: reasoning_details ARRAY is not lifted onto thinking (!ref guard)');
  is($router->aggregate_thinking($chunks), undef,
    'OpenRouter: no string reasoning delta -> aggregate_thinking is undef');
}

# An empty back-compat `reasoning_content` stub on the delta must not mask a
# filled bare `reasoning` -- the delta half of the k79 length-over-defined
# precedence, matching chat_response (t/47_openai_compatible_reasoning_parse.t).
{
  my $vllm = Langertha::Engine::vLLM->new(url => 'http://x');
  my $chunk = $vllm->parse_stream_chunk({
    choices => [{ delta => { reasoning_content => '', reasoning => 'real thought' } }],
  });
  is($chunk->thinking, 'real thought',
    'an empty reasoning_content delta does not mask a filled reasoning delta');
}

# A ref-valued bare `reasoning` on the delta must be ignored, not blow up.
{
  my $vllm = Langertha::Engine::vLLM->new(url => 'http://x');
  my $chunk = eval {
    $vllm->parse_stream_chunk({ choices => [{ delta => { reasoning => [ 'x' ] } }] });
  };
  ok(!$@, 'a ref-valued reasoning delta does not die on the Str thinking attribute')
    or diag($@);
  ok($chunk && !$chunk->has_thinking, 'a ref-valued reasoning delta is not lifted');
}

# --------------------------------------------------------------------------
# Anthropic: content_block_delta with delta.type == thinking_delta (field
# thinking). signature_delta / text_delta must NOT set thinking.
# --------------------------------------------------------------------------
{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'k', model => 'claude-opus-4-8',
  );

  my $sse = <<'SSE';
event: content_block_delta
data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"Let me "}}

event: content_block_delta
data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"reason."}}

event: content_block_delta
data: {"type":"content_block_delta","delta":{"type":"signature_delta","signature":"sigabc"}}

event: content_block_delta
data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Answer"}}

event: message_stop
data: {"type":"message_stop"}

SSE

  my $chunks = $anthropic->process_stream_data($sse);
  is($chunks->[0]->thinking, 'Let me ', 'Anthropic: first thinking_delta on ->thinking');
  is($chunks->[1]->thinking, 'reason.', 'Anthropic: second thinking_delta');
  ok(!$chunks->[2]->has_thinking, 'Anthropic: a signature_delta carries no thinking');
  ok(!$chunks->[3]->has_thinking, 'Anthropic: a text_delta carries no thinking');
  is($chunks->[3]->content, 'Answer', 'Anthropic: text_delta still fills content');
  is($anthropic->aggregate_thinking($chunks), 'Let me reason.',
    'Anthropic: aggregate_thinking reassembles the thinking_delta fragments');
}

# A plain text content_block_delta with no delta.type (older shim shape) still
# yields content and no thinking -- back-compat with t/43_streaming_parser.t.
{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'k', model => 'claude-opus-4-8',
  );
  my $chunk = $anthropic->parse_stream_chunk(
    { type => 'content_block_delta', delta => { text => 'Hello' } });
  is($chunk->content, 'Hello', 'Anthropic: typeless text delta still fills content');
  ok(!$chunk->has_thinking, 'Anthropic: typeless text delta carries no thinking');
}

# --------------------------------------------------------------------------
# Gemini: thought parts (thought:true) feed thinking, answer parts feed content.
# Gemini streams SSE-wrapped candidates JSON (alt=sse).
# --------------------------------------------------------------------------
{
  my $gemini = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-3-flash-preview',
  );

  my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
  my @lines;
  for my $c (
    { candidates => [{ content => { parts => [ { text => 'plan ',   thought => $TRUE } ] } }] },
    { candidates => [{ content => { parts => [ { text => 'more', thought => $TRUE } ] } }] },
    { candidates => [{ content => { parts => [ { text => 'the ' } ] } }] },
    { candidates => [{ content => { parts => [ { text => 'answer' } ], }, finishReason => 'STOP' }] },
  ) {
    push @lines, 'data: ' . $json->encode($c) . "\n";
  }
  my $sse = join("\n", @lines) . "\n";

  my $chunks = $gemini->process_stream_data($sse);
  is($chunks->[0]->thinking, 'plan ', 'Gemini: first thought part on ->thinking');
  is($chunks->[0]->content, '', 'Gemini: a thought-only chunk has empty content');
  is($chunks->[2]->content, 'the ', 'Gemini: an answer part fills content');
  ok(!$chunks->[2]->has_thinking, 'Gemini: an answer-only chunk carries no thinking');
  is($gemini->aggregate_thinking($chunks), 'plan more',
    'Gemini: aggregate_thinking reassembles the thought parts');
  is(join('', map { $_->content } @$chunks), 'the answer',
    'Gemini: content aggregation excludes thought parts');
}

# A single chunk carrying interleaved thought + answer parts: thought -> thinking,
# answer -> content.
{
  my $gemini = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-3-flash-preview',
  );
  my $chunk = $gemini->parse_stream_chunk({
    candidates => [{ content => { parts => [
      { text => 'reason', thought => $TRUE },
      { text => 'reply' },
    ] } }],
  });
  is($chunk->thinking, 'reason', 'Gemini: thought part in a mixed chunk -> thinking');
  is($chunk->content, 'reply', 'Gemini: answer part in a mixed chunk -> content');
}

# --------------------------------------------------------------------------
# Ollama native /api/chat: message.thinking per NDJSON chunk (think=true).
# --------------------------------------------------------------------------
{
  my $ollama = Langertha::Engine::Ollama->new(
    url => 'http://test.invalid:11434', model => 'qwen3:8b',
  );

  my $ndjson = <<'NDJSON';
{"message":{"thinking":"Let me ","content":""},"done":false}
{"message":{"thinking":"think.","content":""},"done":false}
{"message":{"content":"Hello!"},"done":false}
{"message":{"content":""},"done":true,"done_reason":"stop","eval_count":5}
NDJSON

  my $chunks = $ollama->process_stream_data($ndjson);
  is($chunks->[0]->thinking, 'Let me ', 'Ollama: first message.thinking on ->thinking');
  is($chunks->[1]->thinking, 'think.', 'Ollama: second message.thinking');
  ok(!$chunks->[2]->has_thinking, 'Ollama: a content-only chunk carries no thinking');
  is($ollama->aggregate_thinking($chunks), 'Let me think.',
    'Ollama: aggregate_thinking reassembles message.thinking fragments');
  is(join('', map { $_->content } @$chunks), 'Hello!',
    'Ollama: content aggregation unaffected');
}

# --------------------------------------------------------------------------
# aggregate_thinking edge cases (mirror aggregate_tool_calls contract).
# --------------------------------------------------------------------------
{
  my $ollama = Langertha::Engine::Ollama->new(
    url => 'http://test.invalid:11434', model => 'x',
  );
  is($ollama->aggregate_thinking([]), undef,
    'aggregate_thinking: empty list -> undef (mirrors Response.thinking absence)');
  is($ollama->aggregate_thinking(undef), undef,
    'aggregate_thinking: non-array -> undef');

  require Langertha::Stream::Chunk;
  my @chunks = (
    Langertha::Stream::Chunk->new(content => 'a'),
    Langertha::Stream::Chunk->new(content => 'b', thinking => 'x'),
    Langertha::Stream::Chunk->new(content => 'c'),
    Langertha::Stream::Chunk->new(content => 'd', thinking => 'y'),
  );
  is($ollama->aggregate_thinking(\@chunks), 'xy',
    'aggregate_thinking: concatenates only chunks that carry thinking, in order');
}

# --------------------------------------------------------------------------
# LM Studio native /api/v1/chat: reasoning.start / reasoning.delta /
# reasoning.end SSE events (lmstudio.ai/docs/developer/rest/streaming-events).
# chat.end carries the aggregated result "equivalent to a non-streaming
# response", so the streamed thinking must equal what chat_response lifts from
# that same result: several reasoning blocks joined by "\n". -- karr k334
# --------------------------------------------------------------------------
{
  my $lms = Langertha::Engine::LMStudio->new( url => 'http://h:1234', model => 'm' );

  my $sse = <<'SSE';
event: chat.start
data: {"type":"chat.start","model_instance_id":"m"}

event: reasoning.start
data: {"type":"reasoning.start"}

event: reasoning.delta
data: {"type":"reasoning.delta","content":"Need to"}

event: reasoning.delta
data: {"type":"reasoning.delta","content":" add."}

event: reasoning.end
data: {"type":"reasoning.end"}

event: reasoning.start
data: {"type":"reasoning.start"}

event: reasoning.delta
data: {"type":"reasoning.delta","content":"Check."}

event: reasoning.end
data: {"type":"reasoning.end"}

event: message.start
data: {"type":"message.start"}

event: message.delta
data: {"type":"message.delta","content":"4"}

event: message.end
data: {"type":"message.end"}

event: chat.end
data: {"type":"chat.end","result":{"model_instance_id":"m","output":[{"type":"reasoning","content":"Need to add."},{"type":"reasoning","content":"Check."},{"type":"message","content":"4"}],"stats":{"input_tokens":3,"total_output_tokens":5},"response_id":"resp_1"}}

SSE

  my $chunks = $lms->process_stream_data($sse);
  my @thinking = grep { $_->has_thinking } @$chunks;
  is(scalar @thinking, 3, 'LMStudio: one thinking chunk per reasoning.delta');
  is($thinking[0]->thinking, 'Need to', 'LMStudio: reasoning.delta content on ->thinking');
  is($thinking[0]->content, '', 'LMStudio: a reasoning chunk carries no content');
  is($lms->aggregate_thinking($chunks), "Need to add.\nCheck.",
    'LMStudio: aggregate_thinking reassembles the deltas, blocks joined by newline');
  is(join('', map { $_->content } @$chunks), '4', 'LMStudio: content aggregation unaffected');

  my $end = $json_lms->decode( ( $sse =~ /^data: (\{"type":"chat\.end".*)$/m )[0] );
  my $resp = $lms->chat_response( HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], $json_lms->encode( $end->{result} ) ) );
  is($lms->aggregate_thinking($chunks), $resp->thinking,
    'LMStudio: streamed thinking equals chat_response thinking of the same result');
}

# An empty-string thinking is still "seen" (defined), so it is not undef.
{
  my $ollama = Langertha::Engine::Ollama->new(
    url => 'http://test.invalid:11434', model => 'x',
  );
  require Langertha::Stream::Chunk;
  my @chunks = ( Langertha::Stream::Chunk->new(content => 'a', thinking => '') );
  is($ollama->aggregate_thinking(\@chunks), '',
    'aggregate_thinking: a defined empty-string thinking yields "" not undef');
}

done_testing;

#!/usr/bin/env perl
# ABSTRACT: Test SSE and NDJSON stream chunk parsing per engine
use strict;
use warnings;
use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;
use Langertha::Engine::Anthropic;

plan(23);

my $json = JSON::MaybeXS->new->utf8(1);

# Test OpenAI SSE parsing
my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'test',
  model => 'gpt-4o-mini',
);

my $openai_sse = <<'SSE';
data: {"id":"1","choices":[{"delta":{"content":"Hello"}}]}

data: {"id":"2","choices":[{"delta":{"content":" World"}}]}

data: {"id":"3","choices":[{"delta":{},"finish_reason":"stop"}]}

data: [DONE]

SSE

my $openai_chunks = $openai->process_stream_data($openai_sse);
is(scalar @$openai_chunks, 3, 'OpenAI: parsed 3 chunks');
is($openai_chunks->[0]->content, 'Hello', 'OpenAI: first chunk content');
is($openai_chunks->[1]->content, ' World', 'OpenAI: second chunk content');
is($openai_chunks->[2]->content, '', 'OpenAI: final chunk empty content');
ok($openai_chunks->[2]->is_final, 'OpenAI: final chunk marked as final');
is($openai_chunks->[2]->finish_reason, 'stop', 'OpenAI: finish reason correct');

# Test Ollama NDJSON parsing
my $ollama = Langertha::Engine::Ollama->new(
  url => 'http://test.invalid:11434',
  model => 'llama3.1',
);

my $ollama_ndjson = <<'NDJSON';
{"message":{"content":"Hello"},"done":false}
{"message":{"content":" World"},"done":false}
{"message":{"content":""},"done":true,"done_reason":"stop","eval_count":10}
NDJSON

my $ollama_chunks = $ollama->process_stream_data($ollama_ndjson);
is(scalar @$ollama_chunks, 3, 'Ollama: parsed 3 chunks');
is($ollama_chunks->[0]->content, 'Hello', 'Ollama: first chunk content');
is($ollama_chunks->[1]->content, ' World', 'Ollama: second chunk content');
ok($ollama_chunks->[2]->is_final, 'Ollama: final chunk marked as final');
is($ollama_chunks->[2]->finish_reason, 'stop', 'Ollama: finish reason correct');
is($ollama_chunks->[2]->usage->{completion_tokens}, 10, 'Ollama: usage included');

# Test Anthropic SSE parsing
my $anthropic = Langertha::Engine::Anthropic->new(
  api_key => 'test',
  model => 'claude-3-5-sonnet-20240620',
);

my $anthropic_sse = <<'SSE';
event: message_start
data: {"type":"message_start","message":{"id":"1"}}

event: content_block_start
data: {"type":"content_block_start","index":0}

event: content_block_delta
data: {"type":"content_block_delta","delta":{"text":"Hello"}}

event: content_block_delta
data: {"type":"content_block_delta","delta":{"text":" World"}}

event: message_delta
data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":15}}

event: message_stop
data: {"type":"message_stop"}

SSE

my $anthropic_chunks = $anthropic->process_stream_data($anthropic_sse);
is(scalar @$anthropic_chunks, 4, 'Anthropic: parsed 4 relevant chunks');
is($anthropic_chunks->[0]->content, 'Hello', 'Anthropic: first chunk content');
is($anthropic_chunks->[1]->content, ' World', 'Anthropic: second chunk content');
is($anthropic_chunks->[2]->finish_reason, 'end_turn', 'Anthropic: message_delta has stop_reason');
ok($anthropic_chunks->[3]->is_final, 'Anthropic: message_stop is final');
# karr k167: Anthropic splits finish_reason/usage (message_delta) from is_final
# (message_stop). The cross-dialect contract (OpenAI/Ollama above) puts both on
# the is_final chunk, so the message_delta metadata is replayed onto message_stop.
is($anthropic_chunks->[3]->finish_reason, 'end_turn', 'k167: is_final chunk carries finish_reason');
is($anthropic_chunks->[3]->usage->{output_tokens}, 15, 'k167: is_final chunk carries usage');

# Test callback functionality
my @callback_results;
my $callback = sub { push @callback_results, $_[0]->content };

$openai->process_stream_data($openai_sse, $callback);
is(scalar @callback_results, 3, 'Callback called for each chunk');
is($callback_results[0], 'Hello', 'Callback received correct content');

# Test SSE comment handling
my $sse_with_comment = <<'SSE';
: this is a comment
data: {"id":"1","choices":[{"delta":{"content":"Test"}}]}

SSE

my $comment_chunks = $openai->process_stream_data($sse_with_comment);
is(scalar @$comment_chunks, 1, 'SSE comments ignored');
is($comment_chunks->[0]->content, 'Test', 'Content after comment correct');

done_testing;

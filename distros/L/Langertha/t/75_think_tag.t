#!/usr/bin/env perl
# ABSTRACT: Test think tag filtering for reasoning models

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Response;
use Langertha::Engine::OpenAI;
use Langertha::Engine::DeepSeek;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::NousResearch;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- filter_think_content basics ---

my $engine_on = Langertha::Engine::OpenAI->new(
  api_key => 'testkey',
  model => 'gpt-4o-mini',
);

my $engine_off = Langertha::Engine::OpenAI->new(
  api_key => 'testkey',
  model => 'gpt-4o-mini',
  think_tag_filter => 0,
);

# Basic filtering
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    '<think>Let me reason about this...</think>The answer is 4.'
  );
  is($text, 'The answer is 4.', 'think tag stripped from text');
  is($thinking, 'Let me reason about this...', 'thinking content extracted');
}

# No think tags
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    'Just a plain answer.'
  );
  is($text, 'Just a plain answer.', 'text unchanged without think tags');
  is($thinking, undef, 'thinking is undef without think tags');
}

# Multiple think blocks
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    '<think>First thought</think>Part one. <think>Second thought</think>Part two.'
  );
  is($text, 'Part one. Part two.', 'multiple think blocks stripped');
  is($thinking, "First thought\nSecond thought", 'multiple thinking blocks joined with newline');
}

# Multiline think content
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    "<think>Line 1\nLine 2\nLine 3</think>Answer here."
  );
  is($text, 'Answer here.', 'multiline think block stripped');
  is($thinking, "Line 1\nLine 2\nLine 3", 'multiline thinking preserved');
}

# Filter disabled — no filtering even with think tags
{
  my ($text, $thinking) = $engine_off->filter_think_content(
    '<think>reasoning</think>Answer.'
  );
  is($text, '<think>reasoning</think>Answer.', 'text unchanged when filter disabled');
  is($thinking, undef, 'thinking undef when filter disabled');
}

# Unclosed think tag — model stopped mid-thought
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    '<think>I am reasoning about this problem and then the output got cut off'
  );
  is($text, '', 'unclosed think tag: content stripped');
  is($thinking, 'I am reasoning about this problem and then the output got cut off',
    'unclosed think tag: thinking extracted');
}

# Unclosed think tag with content before it
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    'Preamble text <think>reasoning without close'
  );
  is($text, 'Preamble text', 'unclosed think tag with prefix: content preserved');
  is($thinking, 'reasoning without close',
    'unclosed think tag with prefix: thinking extracted');
}

# Closed pair followed by unclosed tag
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    '<think>first thought</think>Answer. <think>second thought without close'
  );
  is($text, 'Answer.', 'closed + unclosed: content is answer only');
  is($thinking, "first thought\nsecond thought without close",
    'closed + unclosed: both thinking blocks captured');
}

# Undefined text input
{
  my ($text, $thinking) = $engine_on->filter_think_content(undef);
  is($text, undef, 'undef text returns undef');
  is($thinking, undef, 'thinking undef for undef input');
}

# Leading whitespace after removal
{
  my ($text, $thinking) = $engine_on->filter_think_content(
    '<think>hmm</think>   The answer is here.'
  );
  is($text, 'The answer is here.', 'leading whitespace trimmed after think removal');
}

# Custom think tag
{
  my $custom = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model => 'gpt-4o-mini',
    think_tag_filter => 1,
    think_tag => 'reasoning',
  );
  my ($text, $thinking) = $custom->filter_think_content(
    '<reasoning>Deep thought</reasoning>42.'
  );
  is($text, '42.', 'custom tag name stripped');
  is($thinking, 'Deep thought', 'custom tag thinking extracted');

  # Default tag NOT stripped with custom tag
  my ($text2, $thinking2) = $custom->filter_think_content(
    '<think>not stripped</think>Answer.'
  );
  is($text2, '<think>not stripped</think>Answer.', 'default tag not stripped with custom tag');
  is($thinking2, undef, 'no thinking extracted for wrong tag');
}

# --- Orphan closing tag and untouched text (karr k302) ---
# DeepSeek-R1 and Qwen3-thinking chat templates put the opening <think> into
# the generation prompt, so a server without a reasoning parser returns
# "reasoning...</think>answer": the reasoning must not leak into content. And
# a reply without any think tag is the model's text byte for byte — the filter
# runs on every engine, so trimming there would eat the first line's
# indentation of every code answer.

{
  my ($text, $thinking) = $engine_on->filter_think_content(
    "Let me think about it.\n</think>\n\nThe answer is 4."
  );
  is($text, 'The answer is 4.', 'orphan closing tag: content after it');
  is($thinking, "Let me think about it.\n", 'orphan closing tag: everything before it is thinking');
}

{
  my ($text, $thinking) = $engine_on->filter_think_content(
    "first</think>Answer <think>second</think> more"
  );
  is($text, 'Answer  more', 'orphan closing tag followed by a pair: both removed');
  is($thinking, "first\nsecond", 'orphan closing tag followed by a pair: both thoughts');
}

{
  my ($text, $thinking) = $engine_on->filter_think_content("</think>Answer.");
  is($text, 'Answer.', 'bare orphan closing tag: tag removed');
  is($thinking, undef, 'bare orphan closing tag: no empty thinking');
}

{
  my $code = "    def f():\n        return 1\n";
  my ($text, $thinking) = $engine_on->filter_think_content($code);
  is($text, $code, 'no tag: leading indentation and trailing newline kept exactly');
  is($thinking, undef, 'no tag: no thinking');
}

{
  my ($text, $thinking) = $engine_on->filter_think_content(
    "<think>plan</think>\n\n    indented code\n"
  );
  is($text, "    indented code\n",
    'after a leading block: the blank lines go, the first line keeps its indentation');
}

{
  my ($text, $thinking) = $engine_on->filter_think_content(
    "<think>a<think>b</think>c</think>done"
  );
  is($text, 'c</think>done', 'nested tags are not balanced: the first closing tag ends the block');
  is($thinking, 'a<think>b', 'nested tags: thinking up to the first closing tag');
}

{
  my $vllm_resp = HTTP::Response->new(200, 'OK');
  $vllm_resp->header('Content-Type' => 'application/json');
  $vllm_resp->content($json->encode({
    id => 'chatcmpl-qwen3', model => 'Qwen/Qwen3-8B',
    choices => [{ message => { role => 'assistant',
      content => "Two and two.\n</think>\n\nThe answer is 4." }, finish_reason => 'stop' }],
  }));
  my $resp = $engine_on->chat_response($vllm_resp);
  is($resp->content, 'The answer is 4.', 'chat_response: orphan closing tag reasoning out of content');
  is($resp->thinking, "Two and two.\n", 'chat_response: orphan reasoning on thinking');

  my $plain_resp = HTTP::Response->new(200, 'OK');
  $plain_resp->header('Content-Type' => 'application/json');
  $plain_resp->content($json->encode({
    id => 'chatcmpl-plain', model => 'gpt-4o-mini',
    choices => [{ message => { role => 'assistant', content => "  indented\n" }, finish_reason => 'stop' }],
  }));
  my $plain = $engine_on->chat_response($plain_resp);
  is($plain->content, "  indented\n", 'chat_response without tags: content untouched');
  ok(!$plain->has_thinking, 'chat_response without tags: no thinking');
}

# --- Response clone_with ---

{
  my $r = Langertha::Response->new(
    content       => 'original',
    id            => 'resp-123',
    model         => 'gpt-4o',
    finish_reason => 'stop',
    usage         => { prompt_tokens => 10, completion_tokens => 5 },
    created       => 1700000000,
  );

  my $clone = $r->clone_with(content => 'modified', thinking => 'I thought hard');
  isa_ok($clone, 'Langertha::Response');
  is($clone->content, 'modified', 'clone_with overrides content');
  is($clone->thinking, 'I thought hard', 'clone_with adds thinking');
  ok($clone->has_thinking, 'has_thinking predicate works');
  is($clone->id, 'resp-123', 'clone_with preserves id');
  is($clone->model, 'gpt-4o', 'clone_with preserves model');
  is($clone->finish_reason, 'stop', 'clone_with preserves finish_reason');
  is(0 + $clone->created, 1700000000, 'clone_with preserves created');
  is($clone->prompt_tokens, 10, 'clone_with preserves usage');
}

# clone_with without thinking
{
  my $r = Langertha::Response->new(content => 'hello');
  my $clone = $r->clone_with(content => 'world');
  is($clone->content, 'world', 'clone_with minimal response');
  ok(!$clone->has_thinking, 'no thinking on minimal clone');
  ok(!$clone->has_id, 'no id on minimal clone');
}

# --- chat_response integration with think tag filter ---

{
  my $ds = Langertha::Engine::DeepSeek->new(
    api_key => 'testkey',
    model => 'deepseek-reasoner',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-ds123',
    model => 'deepseek-reasoner',
    created => 1700000002,
    choices => [{
      message => {
        role => 'assistant',
        content => '<think>Let me think step by step...
2 + 2 = 4</think>The answer is 4.',
      },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 15, completion_tokens => 20, total_tokens => 35 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $ds->chat_response($http_resp);
  isa_ok($resp, 'Langertha::Response');
  is("$resp", 'The answer is 4.', 'DeepSeek chat_response filters think tags');
  is($resp->content, 'The answer is 4.', 'content is filtered');
  ok($resp->has_thinking, 'thinking is populated');
  is($resp->thinking, "Let me think step by step...\n2 + 2 = 4", 'thinking content extracted');
  is($resp->id, 'chatcmpl-ds123', 'metadata preserved through filter');
  is($resp->model, 'deepseek-reasoner', 'model preserved');
  is($resp->prompt_tokens, 15, 'usage preserved');
}

# --- Defaults: filter ON everywhere ---

{
  my $ds = Langertha::Engine::DeepSeek->new(
    api_key => 'testkey',
    model => 'deepseek-chat',
  );
  ok($ds->think_tag_filter, 'DeepSeek think_tag_filter defaults to 1');
  is($ds->think_tag, 'think', 'DeepSeek think_tag defaults to think');
}

{
  ok($engine_on->think_tag_filter, 'OpenAI think_tag_filter defaults to 1');
}

# --- OpenAI with filter explicitly enabled ---

{
  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-oai123',
    model => 'gpt-4o-mini',
    choices => [{
      message => { role => 'assistant', content => '<think>reasoning</think>Clean answer.' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 5, completion_tokens => 3, total_tokens => 8 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $engine_on->chat_response($http_resp);
  is($resp->content, 'Clean answer.', 'OpenAI with filter enabled strips think tags');
  ok($resp->has_thinking, 'thinking populated on OpenAI with filter');
  is($resp->thinking, 'reasoning', 'thinking extracted on OpenAI with filter');
}

# --- Filter enabled, no think tags in response — thinking should not be set ---

{
  my $ds = Langertha::Engine::DeepSeek->new(
    api_key => 'testkey',
    model => 'deepseek-chat',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-ds456',
    model => 'deepseek-chat',
    choices => [{
      message => { role => 'assistant', content => 'No thinking here.' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 5, completion_tokens => 3, total_tokens => 8 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $ds->chat_response($http_resp);
  is($resp->content, 'No thinking here.', 'content unchanged without think tags');
  ok(!$resp->has_thinking, 'thinking not set without think tags');
}

# --- Filter explicitly disabled — think tags pass through ---

{
  my $ds = Langertha::Engine::DeepSeek->new(
    api_key => 'testkey',
    model => 'deepseek-reasoner',
    think_tag_filter => 0,
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-ds789',
    model => 'deepseek-reasoner',
    choices => [{
      message => { role => 'assistant', content => '<think>keep this</think>Answer.' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 5, completion_tokens => 3, total_tokens => 8 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $ds->chat_response($http_resp);
  is($resp->content, '<think>keep this</think>Answer.', 'think tags preserved with filter disabled');
  ok(!$resp->has_thinking, 'no thinking with filter disabled');
}

# --- simple_chat_stream filtering ---

# We can't easily mock the full streaming pipeline without a real HTTP agent,
# but we can test that simple_chat_stream calls filter_think_content via
# the around modifier by testing filter_think_content directly on streaming output.
# The around modifier wraps the return value of simple_chat_stream which returns
# a concatenated string — so testing filter_think_content on that string is equivalent.

{
  my $stream_content = '<think>step 1: consider the problem</think>The final streamed answer.';
  my ($filtered, $thinking) = $engine_on->filter_think_content($stream_content);
  is($filtered, 'The final streamed answer.', 'streaming content would be filtered');
  is($thinking, 'step 1: consider the problem', 'streaming thinking would be extracted');
}

# --- Native reasoning_content (OpenAI-compatible: DeepSeek, Groq, vLLM, etc.) ---

{
  my $ds = Langertha::Engine::DeepSeek->new(
    api_key => 'testkey',
    model => 'deepseek-reasoner',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-native1',
    model => 'deepseek-reasoner',
    choices => [{
      message => {
        role => 'assistant',
        content => 'The answer is 4.',
        reasoning_content => "Let me think step by step...\n2 + 2 = 4",
      },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 15, completion_tokens => 20, total_tokens => 35 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $ds->chat_response($http_resp);
  is($resp->content, 'The answer is 4.', 'native reasoning_content: content is clean');
  ok($resp->has_thinking, 'native reasoning_content: thinking is set');
  is($resp->thinking, "Let me think step by step...\n2 + 2 = 4",
    'native reasoning_content: thinking extracted from message');
  is($resp->id, 'chatcmpl-native1', 'native reasoning_content: metadata preserved');
}

# --- Native reasoning_content absent ---

{
  my $openai = Langertha::Engine::OpenAI->new(
    api_key => 'testkey',
    model => 'gpt-4o-mini',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-noreason',
    model => 'gpt-4o-mini',
    choices => [{
      message => { role => 'assistant', content => 'Just an answer.' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 5, completion_tokens => 3, total_tokens => 8 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $openai->chat_response($http_resp);
  is($resp->content, 'Just an answer.', 'no reasoning_content: content normal');
  ok(!$resp->has_thinking, 'no reasoning_content: thinking not set');
}

# --- Native reasoning_content + think_tag_filter interaction ---
# When reasoning_content is provided AND think_tag_filter is on but content
# has no <think> tags, the native thinking should be preserved via clone_with.

{
  my $ds = Langertha::Engine::DeepSeek->new(
    api_key => 'testkey',
    model => 'deepseek-reasoner',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'chatcmpl-both',
    model => 'deepseek-reasoner',
    choices => [{
      message => {
        role => 'assistant',
        content => 'Clean answer.',
        reasoning_content => 'Native reasoning here.',
      },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 5, completion_tokens => 3, total_tokens => 8 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $ds->chat_response($http_resp);
  is($resp->content, 'Clean answer.',
    'reasoning_content + filter: content unchanged (no tags to strip)');
  ok($resp->has_thinking, 'reasoning_content + filter: thinking preserved');
  is($resp->thinking, 'Native reasoning here.',
    'reasoning_content + filter: native thinking preserved through clone_with');
}

# --- Anthropic thinking blocks ---

{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'testkey',
    model => 'claude-sonnet-4-6',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'msg_think1',
    model => 'claude-sonnet-4-6',
    stop_reason => 'end_turn',
    content => [
      { type => 'thinking', thinking => 'I need to consider this carefully...' },
      { type => 'text', text => 'The answer is 42.' },
    ],
    usage => { input_tokens => 20, output_tokens => 10 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $anthropic->chat_response($http_resp);
  is($resp->content, 'The answer is 42.', 'Anthropic thinking: content is text blocks only');
  ok($resp->has_thinking, 'Anthropic thinking: thinking is set');
  is($resp->thinking, 'I need to consider this carefully...',
    'Anthropic thinking: extracted from thinking blocks');
}

# --- Anthropic multiple thinking blocks ---

{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'testkey',
    model => 'claude-sonnet-4-6',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'msg_think2',
    model => 'claude-sonnet-4-6',
    stop_reason => 'end_turn',
    content => [
      { type => 'thinking', thinking => 'First thought.' },
      { type => 'thinking', thinking => 'Second thought.' },
      { type => 'text', text => 'Final answer.' },
    ],
    usage => { input_tokens => 20, output_tokens => 10 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $anthropic->chat_response($http_resp);
  is($resp->content, 'Final answer.', 'Anthropic multi-think: content correct');
  is($resp->thinking, "First thought.\nSecond thought.",
    'Anthropic multi-think: thinking blocks joined');
}

# --- Anthropic without thinking blocks (normal response) ---

{
  my $anthropic = Langertha::Engine::Anthropic->new(
    api_key => 'testkey',
    model => 'claude-sonnet-4-6',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    id => 'msg_nothink',
    model => 'claude-sonnet-4-6',
    stop_reason => 'end_turn',
    content => [
      { type => 'text', text => 'Just a normal response.' },
    ],
    usage => { input_tokens => 10, output_tokens => 5 },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $anthropic->chat_response($http_resp);
  is($resp->content, 'Just a normal response.', 'Anthropic no-think: content normal');
  ok(!$resp->has_thinking, 'Anthropic no-think: thinking not set');
}

# --- Gemini thought parts ---

{
  my $gemini = Langertha::Engine::Gemini->new(
    api_key => 'testkey',
    model => 'gemini-2.5-flash',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    candidates => [{
      content => {
        parts => [
          { text => 'Internal reasoning here...', thought => JSON->true },
          { text => 'The answer is 42.' },
        ],
        role => 'model',
      },
      finishReason => 'STOP',
    }],
    usageMetadata => {
      promptTokenCount => 8,
      candidatesTokenCount => 15,
      totalTokenCount => 23,
    },
    modelVersion => 'gemini-2.5-flash-preview',
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $gemini->chat_response($http_resp);
  is($resp->content, 'The answer is 42.', 'Gemini thought: content excludes thought parts');
  ok($resp->has_thinking, 'Gemini thought: thinking is set');
  is($resp->thinking, 'Internal reasoning here...',
    'Gemini thought: extracted from thought parts');
}

# --- Gemini without thought parts ---

{
  my $gemini = Langertha::Engine::Gemini->new(
    api_key => 'testkey',
    model => 'gemini-2.5-flash',
  );

  my $http_resp = HTTP::Response->new(200, 'OK');
  $http_resp->content($json->encode({
    candidates => [{
      content => {
        parts => [{ text => 'Normal Gemini response.' }],
        role => 'model',
      },
      finishReason => 'STOP',
    }],
    usageMetadata => {
      promptTokenCount => 5,
      candidatesTokenCount => 3,
      totalTokenCount => 8,
    },
  }));
  $http_resp->header('Content-Type' => 'application/json');

  my $resp = $gemini->chat_response($http_resp);
  is($resp->content, 'Normal Gemini response.', 'Gemini no-thought: content normal');
  ok(!$resp->has_thinking, 'Gemini no-thought: thinking not set');
}

# --- NousResearch reasoning attribute ---

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'testkey',
    model => 'DeepHermes-3-Mistral-24B-Preview',
  );
  ok(!$nous->reasoning, 'NousResearch reasoning defaults to 0');

  # chat_messages without reasoning — no extra system message
  my $msgs = $nous->chat_messages('Hello');
  is(scalar @$msgs, 1, 'without reasoning: 1 message');
  is($msgs->[0]{role}, 'user', 'without reasoning: user message only');
}

{
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'testkey',
    model => 'DeepHermes-3-Mistral-24B-Preview',
    reasoning => 1,
  );
  ok($nous->reasoning, 'NousResearch reasoning can be enabled');

  # chat_messages with reasoning — reasoning prompt prepended
  my $msgs = $nous->chat_messages('Hello');
  is(scalar @$msgs, 2, 'with reasoning: 2 messages');
  is($msgs->[0]{role}, 'system', 'with reasoning: system message first');
  like($msgs->[0]{content}, qr/deep thinking AI/, 'with reasoning: reasoning prompt content');
  is($msgs->[1]{role}, 'user', 'with reasoning: user message second');
}

{
  # reasoning + system_prompt — both present
  my $nous = Langertha::Engine::NousResearch->new(
    api_key => 'testkey',
    model => 'DeepHermes-3-Mistral-24B-Preview',
    reasoning => 1,
    system_prompt => 'You are a math tutor.',
  );
  my $msgs = $nous->chat_messages('What is 2+2?');
  is(scalar @$msgs, 3, 'reasoning + system_prompt: 3 messages');
  like($msgs->[0]{content}, qr/deep thinking AI/, 'reasoning prompt is first');
  is($msgs->[1]{content}, 'You are a math tutor.', 'user system_prompt is second');
  is($msgs->[2]{role}, 'user', 'user message is third');
}

done_testing;

#!/usr/bin/env perl
# ABSTRACT: Test Langertha::Response metadata container

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use Path::Tiny;

use Langertha::Response;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::Ollama;
use Langertha::Engine::AKI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Response basics ---

my $r = Langertha::Response->new(content => 'Hello world');
is("$r", 'Hello world', 'Response stringifies to content');
is($r->content, 'Hello world', 'content accessor works');
ok(!$r->has_raw, 'no raw without setting it');
ok(!$r->has_id, 'no id without setting it');
ok(!$r->has_model, 'no model without setting it');
ok(!$r->has_finish_reason, 'no finish_reason without setting it');
ok(!$r->has_usage, 'no usage without setting it');

# --- Response with all metadata ---

my $r2 = Langertha::Response->new(
  content       => 'Hi',
  raw           => { foo => 'bar' },
  id            => 'resp-123',
  model         => 'gpt-4o',
  finish_reason => 'stop',
  usage         => { prompt_tokens => 10, completion_tokens => 5, total_tokens => 15 },
  created       => 1700000000,
);
is("$r2", 'Hi', 'full Response stringifies');
is($r2->id, 'resp-123', 'id accessor');
is($r2->model, 'gpt-4o', 'model accessor');
is($r2->finish_reason, 'stop', 'finish_reason accessor');
is(0 + $r2->created, 1700000000, 'created numifies to the Unix timestamp');
is($r2->prompt_tokens, 10, 'prompt_tokens convenience');
is($r2->completion_tokens, 5, 'completion_tokens convenience');
is($r2->total_tokens, 15, 'total_tokens from usage');

# --- Anthropic-style usage (input_tokens/output_tokens) ---

my $r3 = Langertha::Response->new(
  content => 'test',
  usage   => { input_tokens => 20, output_tokens => 8 },
);
is($r3->prompt_tokens, 20, 'prompt_tokens from input_tokens');
is($r3->completion_tokens, 8, 'completion_tokens from output_tokens');
is($r3->total_tokens, 28, 'total_tokens computed from sum');

# --- No usage returns undef ---

my $r4 = Langertha::Response->new(content => 'test');
is($r4->prompt_tokens, undef, 'prompt_tokens undef without usage');
is($r4->completion_tokens, undef, 'completion_tokens undef without usage');
is($r4->total_tokens, undef, 'total_tokens undef without usage');

# --- String context in expressions ---

my $r5 = Langertha::Response->new(content => 'hello');
ok($r5 eq 'hello', 'eq comparison works');
like("$r5", qr/hello/, 'regex match via stringification');

# --- OpenAI chat_response returns Response ---

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'testkey',
  model => 'gpt-4o-mini',
);

my $openai_http = HTTP::Response->new(200, 'OK');
$openai_http->content($json->encode({
  id => 'chatcmpl-abc123',
  model => 'gpt-4o-mini-2024-07-18',
  created => 1700000001,
  choices => [{
    message => { role => 'assistant', content => 'OpenAI says hello' },
    finish_reason => 'stop',
  }],
  usage => { prompt_tokens => 12, completion_tokens => 4, total_tokens => 16 },
}));
$openai_http->header('Content-Type' => 'application/json');

my $openai_resp = $openai->chat_response($openai_http);
isa_ok($openai_resp, 'Langertha::Response');
is("$openai_resp", 'OpenAI says hello', 'OpenAI Response stringifies');
is($openai_resp->id, 'chatcmpl-abc123', 'OpenAI id extracted');
is($openai_resp->model, 'gpt-4o-mini-2024-07-18', 'OpenAI model extracted');
is($openai_resp->finish_reason, 'stop', 'OpenAI finish_reason extracted');
is(0 + $openai_resp->created, 1700000001, 'OpenAI created extracted');
is($openai_resp->prompt_tokens, 12, 'OpenAI prompt_tokens');
is($openai_resp->completion_tokens, 4, 'OpenAI completion_tokens');
is($openai_resp->total_tokens, 16, 'OpenAI total_tokens');
ok($openai_resp->has_raw, 'OpenAI raw populated');

# --- Anthropic chat_response returns Response ---

my $anthropic = Langertha::Engine::Anthropic->new(
  api_key => 'testkey',
  model => 'claude-sonnet-4-6',
);

my $anthropic_http = HTTP::Response->new(200, 'OK');
$anthropic_http->content($json->encode({
  id => 'msg_abc123',
  model => 'claude-sonnet-4-6',
  stop_reason => 'end_turn',
  content => [{ type => 'text', text => 'Anthropic says hello' }],
  usage => { input_tokens => 15, output_tokens => 6 },
}));
$anthropic_http->header('Content-Type' => 'application/json');

my $anthropic_resp = $anthropic->chat_response($anthropic_http);
isa_ok($anthropic_resp, 'Langertha::Response');
is("$anthropic_resp", 'Anthropic says hello', 'Anthropic Response stringifies');
is($anthropic_resp->id, 'msg_abc123', 'Anthropic id extracted');
is($anthropic_resp->model, 'claude-sonnet-4-6', 'Anthropic model extracted');
is($anthropic_resp->finish_reason, 'end_turn', 'Anthropic finish_reason from stop_reason');
is($anthropic_resp->prompt_tokens, 15, 'Anthropic prompt_tokens from input_tokens');
is($anthropic_resp->completion_tokens, 6, 'Anthropic completion_tokens from output_tokens');
is($anthropic_resp->total_tokens, 21, 'Anthropic total_tokens computed');

# --- Gemini chat_response returns Response ---

my $gemini = Langertha::Engine::Gemini->new(
  api_key => 'testkey',
  model => 'gemini-2.5-flash',
);

my $gemini_http = HTTP::Response->new(200, 'OK');
$gemini_http->content($json->encode({
  candidates => [{
    content => { parts => [{ text => 'Gemini says hello' }], role => 'model' },
    finishReason => 'STOP',
  }],
  usageMetadata => {
    promptTokenCount => 8,
    candidatesTokenCount => 3,
    totalTokenCount => 11,
  },
  modelVersion => 'gemini-2.5-flash-preview-04-17',
  responseId => 'mCvJaNXTBvqd1dkPx6WbwAQ',
}));
$gemini_http->header('Content-Type' => 'application/json');

my $gemini_resp = $gemini->chat_response($gemini_http);
isa_ok($gemini_resp, 'Langertha::Response');
is("$gemini_resp", 'Gemini says hello', 'Gemini Response stringifies');
is($gemini_resp->model, 'gemini-2.5-flash-preview-04-17', 'Gemini model from modelVersion');
is($gemini_resp->finish_reason, 'STOP', 'Gemini finish_reason extracted');
is($gemini_resp->prompt_tokens, 8, 'Gemini prompt_tokens normalized');
is($gemini_resp->completion_tokens, 3, 'Gemini completion_tokens normalized');
is($gemini_resp->total_tokens, 11, 'Gemini total_tokens normalized');
# karr k335: every other engine fills Response.id from the wire's response id;
# Gemini's is responseId. Without it id is undef on Gemini alone.
is($gemini_resp->id, 'mCvJaNXTBvqd1dkPx6WbwAQ', 'Gemini id from responseId');

# --- Ollama chat_response returns Response ---

my $ollama = Langertha::Engine::Ollama->new(
  url => 'http://test.invalid:11434',
  model => 'llama3.3',
);

my $ollama_http = HTTP::Response->new(200, 'OK');
$ollama_http->content($json->encode({
  model => 'llama3.3:latest',
  message => { role => 'assistant', content => 'Ollama says hello' },
  done => JSON->true,
  done_reason => 'stop',
  total_duration => 5000000000,
  load_duration => 1000000000,
  prompt_eval_count => 20,
  prompt_eval_duration => 200000000,
  eval_count => 10,
  eval_duration => 300000000,
}));
$ollama_http->header('Content-Type' => 'application/json');

my $ollama_resp = $ollama->chat_response($ollama_http);
isa_ok($ollama_resp, 'Langertha::Response');
is("$ollama_resp", 'Ollama says hello', 'Ollama Response stringifies');
is($ollama_resp->model, 'llama3.3:latest', 'Ollama model extracted');
is($ollama_resp->finish_reason, 'stop', 'Ollama finish_reason from done_reason');
is($ollama_resp->prompt_tokens, 20, 'Ollama prompt_tokens from prompt_eval_count');
is($ollama_resp->completion_tokens, 10, 'Ollama completion_tokens from eval_count');
ok($ollama_resp->has_timing, 'Ollama timing populated');
is($ollama_resp->timing->{total_duration}, 5000000000, 'Ollama timing total_duration');
is($ollama_resp->timing->{load_duration}, 1000000000, 'Ollama timing load_duration');
is($ollama_resp->timing->{prompt_eval_duration}, 200000000, 'Ollama timing prompt_eval_duration');
is($ollama_resp->timing->{eval_duration}, 300000000, 'Ollama timing eval_duration');
is($ollama_resp->timing->{total_seconds}, 5, 'Ollama timing total_seconds derived from ns');
is($ollama_resp->timing->{load_seconds}, 1, 'Ollama timing load_seconds derived from ns');
is($ollama_resp->timing->{prompt_eval_seconds}, 0.2, 'Ollama timing prompt_eval_seconds derived from ns');
is($ollama_resp->timing->{eval_seconds}, 0.3, 'Ollama timing eval_seconds derived from ns');
ok($ollama_resp->has_total, 'Ollama has_total from total_seconds');
is($ollama_resp->total_seconds, 5, 'Ollama total_seconds convenience');
ok(!$ollama_resp->has_ttft, 'Ollama has_ttft false (sync engine)');

# --- AKI chat_response returns Response ---

my $aki = Langertha::Engine::AKI->new(
  api_key => 'testkey',
  model => 'llama3_8b_chat',
);

my $aki_http = HTTP::Response->new(200, 'OK');
$aki_http->content($json->encode({
  success => JSON->true,
  text => 'AKI says hello',
  model_name => 'Meta-Llama-3-8B-Instruct',
  total_duration => 0.7,
}));
$aki_http->header('Content-Type' => 'application/json');

my $aki_resp = $aki->chat_response($aki_http);
isa_ok($aki_resp, 'Langertha::Response');
is("$aki_resp", 'AKI says hello', 'AKI Response stringifies');
is($aki_resp->model, 'Meta-Llama-3-8B-Instruct', 'AKI model from model_name');
ok($aki_resp->has_timing, 'AKI timing populated');
is($aki_resp->total_seconds, 0.7, 'AKI total_duration (seconds) surfaces as total_seconds');
ok(!exists $aki_resp->timing->{total_duration},
  'AKI no longer emits the raw total_duration key (Ollama-ns collision, karr k126)');

# --- clone_with: probes survives (the gap that bit karr #4) ---

subtest 'clone_with carries probes through (karr #5 regression gate)' => sub {
  my $r = Langertha::Response->new(
    content => 'x',
    probes  => { qk_cache => [ [1, 2], [3, 4] ], config => { layer => 0 } },
  );
  ok($r->has_probes, 'probes set');

  my $r2 = $r->clone_with(content => 'y');
  ok($r2->has_probes, 'probes survives a content override');
  is_deeply($r2->probes->{qk_cache}, [ [1, 2], [3, 4] ], 'probes qk_cache intact');
  is($r2->probes->{config}{layer}, 0, 'probes config intact');

  # Sequential chain: probes → rate_limit (mirrors simple_chat chain)
  require Langertha::RateLimit;
  my $rl = Langertha::RateLimit->new(
    requests_remaining => 50,
    tokens_remaining   => 2000,
    raw                => {},
  );
  my $r3 = $r2->clone_with(rate_limit => $rl);
  ok($r3->has_probes, 'probes survives a sequential rate_limit override');
  ok($r3->has_rate_limit, 'rate_limit applied');
  is_deeply($r3->probes->{qk_cache}, [ [1, 2], [3, 4] ], 'probes still intact');
  is($r3->rate_limit->requests_remaining, 50, 'rate_limit value carried');
};

# --- clone_with: raw survives ---

subtest 'clone_with carries raw through' => sub {
  my $r = Langertha::Response->new(
    content => 'hello',
    raw     => { id => 'r1', nested => { a => 1 } },
  );
  ok($r->has_raw, 'raw set');

  my $r2 = $r->clone_with(content => 'world');
  ok($r2->has_raw, 'raw survives a content override');
  is($r2->raw->{id}, 'r1', 'raw id intact');
  is($r2->raw->{nested}{a}, 1, 'raw nested hash intact');
};

# --- clone_with: timing -> tool_calls chain (karr #5 2-step regression) ---

subtest 'clone_with timing then tool_calls preserves both' => sub {
  my $r = Langertha::Response->new(content => 'orig');
  ok(!$r->has_timing, 'no timing initially');
  ok(!$r->has_tool_calls, 'no tool_calls initially');

  my $r2 = $r->clone_with(timing => { total_seconds => 1.5 });
  ok($r2->has_timing, 'timing set after first clone');
  is($r2->total_seconds, 1.5, 'total_seconds readable');
  ok(!$r2->has_tool_calls, 'no tool_calls yet');

  my $r3 = $r2->clone_with(
    tool_calls => [{
      name      => 'extract',
      arguments => { x => 1 },
      synthetic => 1,
    }],
  );
  ok($r3->has_timing, 'timing survives second clone');
  is($r3->total_seconds, 1.5, 'total_seconds survives second clone');
  ok($r3->has_tool_calls, 'tool_calls set after second clone');
  is($r3->tool_call('extract')->arguments->{x}, 1, 'tool_calls value reachable');
};

# --- Ollama chat_response over what a real server actually sends (karr #92) ---
#
# The hand-written Ollama payload above omits created_at, the one field every
# real Ollama server sends — and it sends it as an RFC3339 string, which no
# Maybe[Int] will take. That killed every non-streaming Ollama chat from
# 1fac6c4 onwards without the suite noticing, because the only other Ollama
# coverage (t/64_tool_calling_ollama_mock.t) drives chat_with_tools_f, which
# reads the raw parse_response HashRef and never builds a Response at all.
# These fixtures are captured verbatim from a real server, so the constructor
# is fed the wire shape rather than a payload written to fit the class.

sub ollama_http {
  my ( $body ) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->header('Content-Type' => 'application/json');
  $http->content($body);
  return $http;
}

subtest 'Ollama chat_response over captured server fixtures (karr #92)' => sub {
  my $data_dir = path(__FILE__)->parent->child('data');

  my $call_body = $data_dir->child('ollama_tool_call_response.json')->slurp_raw;
  my $call_resp = eval { $ollama->chat_response(ollama_http($call_body)) };
  # Test definedness, not truth: a tool-call-only reply has empty content and
  # Response stringifies to content, so the object itself is false here.
  ok(defined $call_resp, 'tool-call fixture: Response constructed, no type-constraint croak')
    or diag($@);

  SKIP: {
    skip 'no Response to inspect', 6 unless defined $call_resp;
    isa_ok($call_resp, 'Langertha::Response');
    is(0 + $call_resp->created, 1771732845, 'created numifies to Unix seconds');
    is($call_resp->raw->{created_at}, '2026-02-22T04:00:45.027209927Z',
      'native RFC3339 stamp preserved verbatim under raw');
    is($call_resp->model, 'qwen3:8b', 'model from fixture');
    is($call_resp->finish_reason, 'stop', 'finish_reason from done_reason');
    is(scalar @{$call_resp->tool_calls}, 1, 'tool call extracted from the same payload');
  }

  my $result_body = $data_dir->child('ollama_tool_result_response.json')->slurp_raw;
  my $result_resp = eval { $ollama->chat_response(ollama_http($result_body)) };
  ok(defined $result_resp, 'tool-result fixture: Response constructed') or diag($@);

  SKIP: {
    skip 'no Response to inspect', 2 unless defined $result_resp;
    is("$result_resp", '22', 'tool-result fixture stringifies to its content');
    is(0 + $result_resp->created, 1771732852, 'created numifies to Unix seconds');
  }
};

subtest 'Ollama created_at normalization (karr #92)' => sub {
  my %stamps = (
    'fractional UTC'         => '2026-02-22T04:00:45.027209927Z',
    'whole-second UTC'       => '2026-02-22T04:00:45Z',
    'positive UTC offset'    => '2026-02-22T05:00:45+01:00',
    'negative UTC offset'    => '2026-02-22T03:00:45-01:00',
    'offset without a colon' => '2026-02-22T03:00:45-0100',
    'epoch seconds'          => 1771732845,
    'epoch seconds as text'  => '1771732845',
  );
  for my $name (sort keys %stamps) {
    my $body = $json->encode({
      model       => 'qwen3:8b',
      created_at  => $stamps{$name},
      message     => { role => 'assistant', content => 'hi' },
      done        => JSON->true,
      done_reason => 'stop',
    });
    my $resp = eval { $ollama->chat_response(ollama_http($body)) };
    ok(defined $resp, "$name: Response constructed") or diag($@);
    is(defined $resp ? 0 + $resp->created : undef, 1771732845,
      "$name: created numifies to the expected Unix timestamp");
  }

  # A stamp we cannot read must drop the field, never take the response down:
  # created is informational metadata, the content is what the caller asked for.
  for my $bad ('not-a-timestamp', '0001-01-01T00:00:00Z', '') {
    my $body = $json->encode({
      model      => 'qwen3:8b',
      created_at => $bad,
      message    => { role => 'assistant', content => 'hi' },
      done       => JSON->true,
    });
    my $resp = eval { $ollama->chat_response(ollama_http($body)) };
    ok(defined $resp, "unreadable created_at '$bad': Response still constructed") or diag($@);
    ok(defined $resp && !$resp->has_created, "unreadable created_at '$bad': created left unset");
    is(defined $resp ? "$resp" : undef, 'hi', "unreadable created_at '$bad': content intact");
  }

  # TO_JSON must keep emitting a number for created, whichever form the server
  # used — a trace consumer sees the same shape for Ollama as for OpenAI.
  my $encoder = JSON::MaybeXS->new->canonical(1)->convert_blessed(1);
  for my $stamp ('2026-02-22T04:00:45.027209927Z', '1771732845') {
    my $body = $json->encode({
      model      => 'qwen3:8b',
      created_at => $stamp,
      message    => { role => 'assistant', content => 'hi' },
      done       => JSON->true,
    });
    my $resp = $ollama->chat_response(ollama_http($body));
    like($encoder->encode($resp), qr/"created":1771732845(?![0-9"])/,
      "created serializes as a JSON number (from '$stamp')");
  }
};

# --- Boolean context (karr #100) ---
#
# `use overload '""' => ..., fallback => 1` makes Perl derive bool from the
# string overload, so a Response whose content is the empty string was FALSE --
# exactly the shape of a tool-call-only reply (see the Ollama fixture subtest
# above) and of an Anthropic reply that is pure tool_use. A caller writing
# `if (my $resp = $engine->simple_chat(...))` silently skipped a perfectly good
# response. An explicit bool overload separates "this object exists" from "its
# content is non-empty"; callers who mean the latter ask `length "$resp"`.

subtest 'Response is true in boolean context whatever its content (karr #100)' => sub {
  my $tool_only = Langertha::Response->new(
    content    => '',
    tool_calls => [
      { name => 'get_weather', arguments => { city => 'Berlin' }, id => 'call_1' },
    ],
  );

  ok($tool_only, 'tool-call-only Response (empty content) is true');
  ok(!!$tool_only, 'double negation stays true');
  is(($tool_only ? 'taken' : 'skipped'), 'taken', 'ternary takes the true branch');
  is(scalar @{ $tool_only->tool_calls }, 1,
    'the tool call a false Response would have hidden is reachable');

  ok(Langertha::Response->new(content => ''), 'empty content, no tool calls: still true');
  ok(Langertha::Response->new(content => '0'),
    q{content '0' is true -- the classic Perl false-string trap does not leak through});

  # The stringification contract is the part nobody may break.
  is("$tool_only", '', 'empty-content Response still stringifies to the empty string');
  is("" . Langertha::Response->new(content => '0'), '0', q{content '0' still stringifies to '0'});
  is(length("$tool_only"), 0, 'length() over the stringification still reports emptiness');
  ok(!length("$tool_only"), 'emptiness stays testable -- that is what length is for');

  # Comparison and concatenation keep routing through the '""' overload.
  my $hello = Langertha::Response->new(content => 'hello');
  ok($hello eq 'hello', 'eq against a plain string works');
  ok($hello ne 'goodbye', 'ne against a plain string works');
  ok($tool_only eq '', 'empty-content Response is still eq to the empty string');
  is($hello . '!', 'hello!', 'concatenation still uses the content');
};


done_testing;

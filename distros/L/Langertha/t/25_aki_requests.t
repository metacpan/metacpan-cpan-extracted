#!/usr/bin/env perl
# ABSTRACT: Test AKI.IO native API request generation and mock responses

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::AKI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Default model (karr k132) ---
# The native default is MiniMax M3, replacing the EOL llama3_8b_chat (EOL
# 2026-09-30). minimax_m3 is the exact id AKI's native /api/endpoints listing
# carries for "MiniMax M3 428B".
is(Langertha::Engine::AKI->new(api_key => 'testkey')->default_model,
  'minimax_m3', 'AKI native default_model is minimax_m3 (M3), not the EOL llama3_8b_chat');

# --- tool_wire_format is pinned to hermes (karr k254) ---
# The native /api/call body has no tools field; tools only reach the model via
# the Hermes system prompt. Another tag would make the engine claim
# tools_native (the HermesTools rule keys on the resolved tag, k251) while the
# tools silently vanish from the request, so a non-hermes tag is a
# misconfiguration that must fail at construction and point to AKIOpenAI.
is(Langertha::Engine::AKI->new(api_key => 'testkey')->tool_wire_format,
  'hermes', 'AKI native defaults to the hermes tool wire');
{
  my $aki = Langertha::Engine::AKI->new(api_key => 'testkey', tool_wire_format => 'hermes');
  is($aki->tool_wire_format, 'hermes', 'an explicit hermes tag is accepted');
  ok($aki->supports('tools_hermes') && !$aki->supports('tools_native'),
    'an explicit hermes tag keeps the hermes capability flags');
}
for my $fmt (qw( openai anthropic )) {
  my $err;
  eval { Langertha::Engine::AKI->new(api_key => 'testkey', tool_wire_format => $fmt); 1 }
    or $err = $@;
  like($err // '', qr/tool_wire_format '\Q$fmt\E'.*hermes.*AKIOpenAI/s,
    "tool_wire_format => '$fmt' croaks at construction, naming hermes and AKIOpenAI");
}

# --- Chat request format ---

my $aki = Langertha::Engine::AKI->new(
  api_key => 'testkey',
  model => 'llama3_8b_chat',
  system_prompt => 'systemprompt',
  temperature => 0.5,
  top_k => 40,
  top_p => 0.9,
  max_gen_tokens => 2000,
);

my $request = $aki->chat('testprompt');
is($request->uri, 'https://aki.io/api/call/llama3_8b_chat', 'AKI chat request uri is correct');
is($request->method, 'POST', 'AKI chat request method is correct');
is($request->header('Content-Type'), 'application/json; charset=utf-8', 'AKI chat request JSON Content Type is set');

my $data = $json->decode($request->content);

# chat_context is a JSON string (not native array) per AKI API convention
my $expected_chat_context = $json->encode([{
  content => "systemprompt", role => "system",
},{
  content => "testprompt", role => "user",
}]);

is($data->{key}, 'testkey', 'AKI request has key in body');
is($data->{temperature}, 0.5, 'AKI request has temperature');
is($data->{top_k}, 40, 'AKI request has top_k');
is($data->{top_p}, 0.9, 'AKI request has top_p');
is($data->{max_gen_tokens}, 2000, 'AKI request has max_gen_tokens');
is($data->{wait_for_result}, JSON->true, 'AKI request has wait_for_result');

# chat_context should be a JSON-encoded string
ok(!ref $data->{chat_context}, 'chat_context is a string (not a reference)');
my $decoded_context = $json->decode($data->{chat_context});
is_deeply($decoded_context, [{
  content => "systemprompt", role => "system",
},{
  content => "testprompt", role => "user",
}], 'AKI chat_context decodes to correct messages');

# No Authorization header (key is in body)
ok(!$request->header('Authorization'), 'AKI request has no Authorization header');

# --- Chat response parsing ---

my $mock_response = HTTP::Response->new(200, 'OK');
$mock_response->content($json->encode({
  success => JSON->true,
  text => 'Hello from AKI!',
  total_duration => 0.7,
  model_name => 'Meta-Llama-3-8B-Instruct',
}));
$mock_response->header('Content-Type' => 'application/json');

my $result = $aki->chat_response($mock_response);
is($result, 'Hello from AKI!', 'AKI chat response parsed correctly');
ok(!$result->has_tool_calls, 'plain AKI response carries no tool_calls');

# --- Chat response with a Hermes tool call (karr #123, ADR 0003) ---
# AKI composes Role::HermesTools with tool_wire_format 'hermes'; a <tool_call>
# block emitted in the native `text` field must land on Response.tool_calls,
# not stay buried as raw text in content.

my $tool_response = HTTP::Response->new(200, 'OK');
$tool_response->content($json->encode({
  success    => JSON->true,
  text       => 'Let me add those. <tool_call>{"name": "add", "arguments": {"a": 7, "b": 15}}</tool_call>',
  model_name => 'Meta-Llama-3-8B-Instruct',
}));
$tool_response->header('Content-Type' => 'application/json');

my $tool_result = $aki->chat_response($tool_response);
ok($tool_result->has_tool_calls, 'AKI hermes tool call lands on Response.tool_calls');
is(scalar @{$tool_result->tool_calls}, 1, 'AKI response has one tool call');
is($tool_result->tool_calls->[0]->name, 'add', 'AKI tool call name');
is($tool_result->tool_calls->[0]->arguments->{a}, 7, 'AKI tool call argument a');
is($tool_result->tool_calls->[0]->arguments->{b}, 15, 'AKI tool call argument b');
unlike("$tool_result", qr/tool_call/, 'AKI content strips the tool_call tag');

# --- Chat response id, usage, and timing (karr #126) ---
# Verbatim body shape from capture 3 of the karr #101 run: the native wire
# names its token counts and durations differently from the OpenAI shim.

my $full_response = HTTP::Response->new(200, 'OK');
$full_response->content($json->encode({
  text                   => 'OK',
  success                => JSON->true,
  job_id                 => 'a871d5bd-1111-2222-3333-00000000097ad',
  model_name             => 'Llama-3.1-8B-Instruct',
  prompt_length          => 37,
  num_generated_tokens   => 2,
  num_cached_tokens      => 16,
  current_context_length => 39,
  max_seq_len            => 65536,
  total_duration         => 0.14,
  compute_duration       => 0.123,
  ep_version             => 3,
}));
$full_response->header('Content-Type' => 'application/json');

my $full = $aki->chat_response($full_response);
is($full->id, 'a871d5bd-1111-2222-3333-00000000097ad', 'AKI job_id maps to Response.id');
is($full->prompt_tokens, 37, 'AKI prompt_length maps to prompt_tokens');
is($full->completion_tokens, 2, 'AKI num_generated_tokens maps to completion_tokens');
is($full->cached_tokens, 16, 'AKI num_cached_tokens maps to cached_tokens');
is($full->total_seconds, 0.14, 'AKI total_duration surfaces as engine-agnostic total_seconds');
is($full->timing->{compute_seconds}, 0.123, 'AKI compute_duration surfaces as compute_seconds');
ok(!exists $full->timing->{total_duration},
  'AKI drops the raw total_duration key (Ollama-ns collision, karr #126)');

# --- Chat error response ---

my $error_response = HTTP::Response->new(200, 'OK');
$error_response->content($json->encode({
  success => JSON->false,
  error => 'Invalid API key',
}));
$error_response->header('Content-Type' => 'application/json');

eval { $aki->chat_response($error_response) };
like($@, qr/API error.*Invalid API key/, 'AKI error response throws with message');

# --- list_models request format ---

my $lm_request = $aki->list_models_request;
is($lm_request->uri, 'https://aki.io/api/endpoints?key=testkey', 'AKI list_models request uri is correct');
is($lm_request->method, 'GET', 'AKI list_models request method is GET');

# --- list_models response parsing ---

my $lm_response = HTTP::Response->new(200, 'OK');
$lm_response->content($json->encode({
  endpoints => ['llama3_8b_chat', 'flux_schnell', 'qwen3_chat'],
}));
$lm_response->header('Content-Type' => 'application/json');

my $endpoints = $lm_request->response_call->($lm_response);
is_deeply($endpoints, ['llama3_8b_chat', 'flux_schnell', 'qwen3_chat'],
  'AKI list_models response parsed correctly');

# --- endpoint_details request format ---

my $ed_request = $aki->endpoint_details_request('llama3_8b_chat');
is($ed_request->uri, 'https://aki.io/api/endpoints/llama3_8b_chat?key=testkey',
  'AKI endpoint_details request uri is correct');
is($ed_request->method, 'GET', 'AKI endpoint_details request method is GET');

# --- endpoint_details response parsing ---

my $ed_response = HTTP::Response->new(200, 'OK');
$ed_response->content($json->encode({
  name => 'llama3_8b_chat',
  title => 'LLama 3.x Chat',
  description => 'Llama 3.x Instruct Chat example API',
  version => 2,
  http_methods => ['GET', 'POST'],
  parameter_description => {
    input => {
      chat_context => { type => 'json', required => JSON->false },
      temperature => { type => 'float', minimum => 0, maximum => 1, default => 0.8 },
    },
    output => {
      text => { type => 'string' },
      model_name => { type => 'string' },
    },
  },
}));
$ed_response->header('Content-Type' => 'application/json');

my $details = $ed_request->response_call->($ed_response);
is($details->{name}, 'llama3_8b_chat', 'endpoint_details name is correct');
is($details->{title}, 'LLama 3.x Chat', 'endpoint_details title is correct');
ok($details->{parameter_description}{input}{chat_context}, 'endpoint_details has chat_context param');

# --- Chat without optional params ---

my $aki_minimal = Langertha::Engine::AKI->new(
  api_key => 'testkey',
  model => 'llama3_8b_chat',
);

my $min_request = $aki_minimal->chat('hello');
my $min_data = $json->decode($min_request->content);
is($min_data->{key}, 'testkey', 'AKI minimal request has key');
is($min_data->{wait_for_result}, JSON->true, 'AKI minimal request has wait_for_result');
ok(!exists $min_data->{temperature}, 'AKI minimal request has no temperature');
ok(!exists $min_data->{top_k}, 'AKI minimal request has no top_k');

# chat_context is JSON string
ok(!ref $min_data->{chat_context}, 'minimal chat_context is a string');
my $min_decoded = $json->decode($min_data->{chat_context});
is_deeply($min_decoded, [{
  content => "hello", role => "user",
}], 'AKI minimal chat_context decodes correctly');

# --- openai() method ---

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $aki_openai = $aki->openai;
  isa_ok($aki_openai, 'Langertha::Engine::AKIOpenAI');
  is($aki_openai->model, 'gpt-oss-120b', 'openai() uses AKIOpenAI default model (gpt-oss-120b, karr k132)');
  is($aki_openai->api_key, 'testkey', 'openai() passes api_key');
  ok(scalar @warnings >= 1, 'openai() without explicit model emits warning');
  like($warnings[0] || '', qr/cannot be mapped/, 'warning mentions model mapping');
}

# openai() with explicit model does not warn
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $aki_openai = $aki->openai(model => 'llama3-chat-8b');
  is($aki_openai->model, 'llama3-chat-8b', 'openai(model => ...) uses given model');
  is(scalar @warnings, 0, 'openai() with explicit model does not warn');
}

# --- anthropic() method (karr #103, mirrors LMStudio->anthropic) ---

{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $aki_anthropic = $aki->anthropic;
  isa_ok($aki_anthropic, 'Langertha::Engine::AKIAnthropic');
  is($aki_anthropic->model, 'gpt-oss-120b', 'anthropic() uses AKIAnthropic default model (gpt-oss-120b, karr k132)');
  is($aki_anthropic->api_key, 'testkey', 'anthropic() passes api_key');
  is($aki_anthropic->url, 'https://aki.io/anthropic',
    'anthropic() uses AKIAnthropic own url (not the native https://aki.io base)');
  is($aki_anthropic->system_prompt, 'systemprompt', 'anthropic() passes system_prompt');
  is($aki_anthropic->temperature, 0.5, 'anthropic() passes temperature');
  ok(scalar @warnings >= 1, 'anthropic() without explicit model emits warning');
  like($warnings[0] || '', qr/cannot be mapped/, 'warning mentions model mapping');
}

# anthropic() with explicit model does not warn
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $aki_anthropic = $aki->anthropic(model => 'gemma4-26b');
  is($aki_anthropic->model, 'gemma4-26b', 'anthropic(model => ...) uses given model');
  is($aki_anthropic->url, 'https://aki.io/anthropic',
    'anthropic() with explicit model still uses AKIAnthropic own url');
  is(scalar @warnings, 0, 'anthropic() with explicit model does not warn');
}

# anthropic() with explicit url override
{
  my $aki_anthropic = $aki->anthropic(
    model => 'gemma4-26b',
    url   => 'https://aki.example.test/anthropic',
  );
  is($aki_anthropic->url, 'https://aki.example.test/anthropic',
    'anthropic() honours explicit url override');
}

# --- A per-request model is routed into the URL (karr k357) ---
# The native wire names the model as the endpoint in /api/call/{model}. A
# per-request model (chat_f, Langertha::Chat's model) used to ride %extra into
# the body as an unknown field while the URL still named chat_model, so the
# override never changed which model answered. It now names the endpoint for
# that request and never reaches the body.
{
  my $engine = Langertha::Engine::AKI->new( api_key => 'testkey', model => 'minimax_m3' );
  my $msgs = [ { role => 'user', content => 'hi' } ];
  my $request = $engine->chat_request( $msgs, model => 'qwen3_32b' );
  is( $request->uri, 'https://aki.io/api/call/qwen3_32b', 'per-request model: the endpoint names the override' );
  ok( !exists $json->decode( $request->content )->{model}, 'per-request model: no model field in the body' );
  for my $none ( undef, '' ) {
    my $plain = $engine->chat_request( $msgs, model => $none );
    is( $plain->uri, 'https://aki.io/api/call/minimax_m3', 'an empty override keeps chat_model' );
    ok( !exists $json->decode( $plain->content )->{model}, 'and sends no model field' );
  }
  is( $engine->chat_model, 'minimax_m3', 'the engine keeps its chat_model' );
}

done_testing;

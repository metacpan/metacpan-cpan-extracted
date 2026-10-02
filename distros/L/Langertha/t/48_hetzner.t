#!/usr/bin/env perl
# ABSTRACT: Test Hetzner Inference engine request generation

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Hetzner;
use Langertha::Content::Image;
use Langertha::Tool;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

plan(29);

# --- Basic chat request ---

my $hetzner = Langertha::Engine::Hetzner->new(
  api_key       => 'testkey',
  model         => 'Qwen/Qwen3.6-35B-A3B-FP8',
  system_prompt => 'You are a helpful assistant',
  temperature   => 0.5,
);

my $req = $hetzner->chat('What is Perl?');
is($req->uri, 'https://inference.hetzner.com/api/v1/chat/completions',
  'Hetzner chat request URI is correct');
is($req->method, 'POST', 'Hetzner chat request method is POST');
is($req->header('Authorization'), 'Bearer testkey',
  'Hetzner chat request Authorization header is correct');
is($req->header('Content-Type'), 'application/json; charset=utf-8',
  'Hetzner chat request JSON Content Type is set');

my $data = $json->decode($req->content);
is_deeply($data, {
  messages => [
    { content => 'You are a helpful assistant', role => 'system' },
    { content => 'What is Perl?',               role => 'user' },
  ],
  model      => 'Qwen/Qwen3.6-35B-A3B-FP8',
  stream     => JSON->false,
  temperature => 0.5,
  max_tokens => 4096,
}, 'Hetzner basic chat request body is correct');

# --- Multi-turn messages roundtrip ---

my $multi_msgs = $hetzner->chat_messages(
  { role => 'user',      content => 'hi' },
  { role => 'assistant', content => 'hello there' },
  { role => 'user',      content => 'and now?' },
);
my $multi_req = $hetzner->chat_request($multi_msgs);
my $multi_data = $json->decode($multi_req->content);
# 1 system (from system_prompt) + 3 explicit = 4 messages
is(scalar @{$multi_data->{messages}}, 4, 'multi-turn has 4 messages');
is($multi_data->{messages}[2]{role}, 'assistant',
  'assistant role preserved across turn');
is($multi_data->{messages}[2]{content}, 'hello there',
  'assistant content preserved across turn');

# --- Vision: image_url content part serializes for OpenAI-compatible wire ---

my $vision_engine = Langertha::Engine::Hetzner->new(
  api_key => 'testkey',
  model   => 'Qwen/Qwen3.6-35B-A3B-FP8',
);
my $img = Langertha::Content::Image->from_url('https://example.test/cat.jpg');
my $vision_normalized = $vision_engine->chat_messages({
  role    => 'user',
  content => [ 'what is in this image?', $img ],
});
is_deeply($vision_normalized, [{
  role    => 'user',
  content => [
    { type => 'text', text => 'what is in this image?' },
    { type => 'image_url', image_url => { url => 'https://example.test/cat.jpg' } },
  ],
}], 'image_url content part serializes for Hetzner (OpenAI-compatible wire)');

# --- Structured output: response_format with json_schema ---

my $structured = Langertha::Engine::Hetzner->new(
  api_key         => 'testkey',
  model           => 'Qwen/Qwen3.6-35B-A3B-FP8',
  response_format => {
    type        => 'json_schema',
    json_schema => {
      name   => 'perl_fact',
      strict => JSON->true,
      schema => {
        type       => 'object',
        properties => { summary => { type => 'string' } },
        required   => ['summary'],
      },
    },
  },
);
my $structured_data = $json->decode($structured->chat('one fact')->content);
is($structured_data->{response_format}{type}, 'json_schema',
  'structured output -> response_format.type json_schema');
is($structured_data->{response_format}{json_schema}{name}, 'perl_fact',
  'structured output -> json_schema.name preserved');
is_deeply($structured_data->{response_format}{json_schema}{schema}{required}, ['summary'],
  'structured output -> json_schema.schema.required preserved');

# --- Tools: OpenAI-compatible wire format selection ---

# Pass pre-formatted OpenAI-wire tool definitions (the wire payload chat_request
# accepts); we then assert the round-trip preserves the OpenAI function wrapper.
my $tools = [{
  type     => 'function',
  function => {
    name        => 'echo',
    description => 'Echo the input text',
    parameters  => {
      type       => 'object',
      properties => { message => { type => 'string' } },
      required   => ['message'],
    },
  },
}];
my $tools_msgs = $hetzner->chat_messages('use echo');
my $tools_data = $json->decode(
  $hetzner->chat_request($tools_msgs, tools => $tools)->content
);
is(scalar @{$tools_data->{tools}}, 1, 'one tool sent on the wire');
is($tools_data->{tools}[0]{type}, 'function',
  'tool wire format is OpenAI (function wrapper)');
is($tools_data->{tools}[0]{function}{name}, 'echo',
  'tool name under function key');
is($tools_data->{tools}[0]{function}{description}, 'Echo the input text',
  'tool description under function key');
is_deeply($tools_data->{tools}[0]{function}{parameters}{required}, ['message'],
  'tool parameters.required under function key');

# --- tool_choice follows the capability registry (karr k239, ADR 0002) ---
# Hetzner clears every tool_choice_* flag (nothing confirms the gateway honors
# the field), and the registry is the truth: the OpenAI envelope sends no
# tool_choice the engine does not claim. auto is the wire default and drops
# quietly; a forced choice drops with a carp, since the model then decides.

my @tc_warns;
my $tc_data = do {
  local $SIG{__WARN__} = sub { push @tc_warns, $_[0] };
  $json->decode(
    $hetzner->chat_request($tools_msgs, tools => $tools, tool_choice => 'auto')->content
  );
};
ok(!exists $tc_data->{tool_choice} && !@tc_warns, 'tool_choice auto dropped silently')
  or diag @tc_warns;

@tc_warns = ();
my $tc_named = do {
  local $SIG{__WARN__} = sub { push @tc_warns, $_[0] };
  $json->decode(
    $hetzner->chat_request(
      $tools_msgs,
      tools       => $tools,
      tool_choice => { type => 'tool', name => 'echo' },
    )->content
  );
};
ok(!exists $tc_named->{tool_choice}, 'named tool_choice not sent');
ok((grep { /dropping tool_choice 'tool echo'/ } @tc_warns), 'dropping the named choice carps')
  or diag @tc_warns;

# --- Static model list (no HTTP) ---

my $ids = $hetzner->list_models;
is(ref($ids), 'ARRAY', 'list_models returns ArrayRef (static, no HTTP)');
ok(scalar(@$ids) == 2, 'static model list has exactly 2 entries');
ok((grep { $_ eq 'Qwen/Qwen3.6-35B-A3B-FP8' } @$ids),
  'static model list contains Qwen/Qwen3.6-35B-A3B-FP8');

# --- Capability registry ---

ok($hetzner->supports('chat'), 'chat capability advertised');
# Hetzner Inference documents neither tool calling nor structured output and is
# explicitly experimental, so the engine clears these flags (k138) even though
# it composes Role::Tools/Role::ResponseFormat — the wire still SERIALIZES a
# tools array if a caller forces one (asserted above), the flags just stop
# chat_f from routing to a path the gateway may silently no-op.
ok(!$hetzner->supports('tools_native'), 'tools_native NOT advertised (undocumented/experimental)');
ok(!$hetzner->supports('response_format_json_schema'),
  'response_format_json_schema NOT advertised (undocumented/experimental)');
ok(!$hetzner->supports('parallel_tool_use'), 'parallel_tool_use NOT advertised');
ok(!$hetzner->supports('embedding'), 'embedding NOT advertised');
ok(!$hetzner->supports('transcription'), 'transcription NOT advertised');

done_testing;

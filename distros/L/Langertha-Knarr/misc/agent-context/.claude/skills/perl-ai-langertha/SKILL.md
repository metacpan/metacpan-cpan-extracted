---
name: perl-ai-langertha
description: Use when calling an LLM from Perl through Langertha, or building on it from another distribution — engines, chat_f, supports(), tool calling with MCP, Tool/ToolCall/Response value objects, plugins, Langertha::Raider.
---

# Langertha — calling it

Langertha is a Perl LLM framework: one engine class per provider, one canonical API on top.
The autonomous agent (`Langertha::Raider`) is the separate distribution **langertha-raider**.
This skill is the caller's guide; changing core itself is `langertha-internals`.

## Engines

```perl
use Langertha::Engine::Anthropic;
my $claude = Langertha::Engine::Anthropic->new(
    api_key       => $ENV{ANTHROPIC_API_KEY},  # cloud engines also read LANGERTHA_<NAME>_API_KEY
    system_prompt => 'You are helpful.',
    # model => '...',   # omit for the engine's default_model
);

# Self-hosted: url required, no api_key
my $local = Langertha::Engine::OllamaOpenAI->new( url => 'http://localhost:11434/v1' );

# Proxy (hi-proto pattern — the proxy routes the model)
my $proxy = Langertha::Engine::OpenAI->new(
    url => 'http://127.0.0.1:5000/api/v1', model => $model_key, api_key => 'proxy' );
```

Pick the engine by the wire the endpoint speaks. Bases: `OpenAIBase` (`/chat/completions`),
`AnthropicBase` (`/v1/messages`), `TranscriptionBase` (transcription only, e.g. `Whisper`),
and `Remote` for engines with their own format (Gemini, Ollama native, AKI, LMStudio native,
Perplexity). The full catalogue is `perldoc Langertha` → *Engine Modules*. `OpenAI` has a lazy
`whisper` attribute: `$openai->whisper->simple_transcription('audio.mp3')`.

`chat_model` (used by chat and `supports()`) defaults to `model`. Check `$response->model`
when it matters which model answered — some shims substitute silently.

## Sync and `_f`

```perl
my $r = $engine->simple_chat('What is Perl?');   # blocking; Response stringifies to content
use Future::AsyncAwait;
$r = await $engine->simple_chat_f('Tell me a story.');
```

`IO::Async` and `Net::Async::HTTP` are `recommends`, not `requires`. Without them every `_f`
method still returns a `Future`, but runs **synchronously** over LWP (warns once per process),
so futures awaited "in parallel" run one after another. Install both for real concurrency.

`simple_chat*` take messages only: a trailing `reasoning_effort => 'high'` is sent as user
text (Langertha warns). Pass controls to `chat_f` or set them on the engine.

## Capabilities — `supports()`

`$engine->supports('tool_choice_named')`; `$engine->engine_capabilities` is the HashRef.
Flag names: `chat streaming tools_native tool_choice_{auto,any,none,named} tools_hermes
response_format_json_{object,schema} embedding transcription image_generation temperature
reasoning_effort prompt_cache prompt_cache_key cached_content seed context_size response_size
system_prompt keep_alive parallel_tool_use runtime_metrics prefix_caching server_tools
image_input` (`image_input` is model-scoped: "this model sees images"; it never blocks sending)
(the `%ROLE_TO_CAPS` map in `Langertha::Role::Capabilities` is the authority).

- The answer is evaluated for the current `chat_model` — the same engine class can answer
  differently for another model. Query it on the configured engine, not the class.
- Some combinations croak before the request instead of returning a provider 400:
  `tools` + a `response_format` on Groq and Cerebras (Groq also rejects `json_schema` with
  streaming). Run the tools, then a second structured-output turn.

## `chat_f` — single turn, named args

```perl
my $response = await $engine->chat_f(
    messages        => [ { role => 'user', content => $prompt } ],
    tools           => [ $tool_hash, ... ],          # any provider shape
    tool_choice     => { type => 'tool', name => 'extract' },
    response_format => { type => 'json_schema', json_schema => { ... } },
    reasoning_effort => 'high',                      # per-request control
);
my $args = $response->tool_call_args('extract');   # HashRef
my $tc   = $response->tool_call('extract');        # or ->tool_call for the first
# $tc->name, ->arguments, ->id, ->synthetic (true when chat_f rewrote the request)
```

Every path lands on `Response.tool_calls` as `Langertha::ToolCall`, so read it the same way on
every provider. What `chat_f` does per wire:

| You pass | Engine | Result |
|---|---|---|
| `tools` | `tools_native` | native tools on the wire |
| `tools` | only `tools_hermes` (NousResearch, AKI native) | tools rendered into the system prompt, `<tool_call>` blocks lifted onto `tool_calls`; `tool_choice => 'none'` withholds them |
| forced `tool_choice` | `tool_choice_named` | native forced tool |
| forced `tool_choice` | no `tool_choice_named`, has `response_format_json_schema` (Perplexity, NousResearch, some models) | rewritten to `json_schema`; `ToolCall` with `synthetic => 1` |
| `response_format` | first-party Anthropic | native `output_config.format` |
| `response_format` | `/anthropic` shim engines | synth tool + forced choice, lifted into `content` (no streaming) |
| `response_format` | Gemini / Ollama native | `responseJsonSchema` / `format` |
| `tools` + `response_format` | Groq, Cerebras | croaks |

Perplexity (`/v1/agent`) has client function tools (no `tool_choice` / `parallel_tool_calls`) and no `json_object`; `OpenAIResponses`
(`/v1/responses`) has tools, no streaming. `chat_f` is one turn; MCP loops: `chat_with_tools_f`.

## Reading a Response

`content`, `model`, `finish_reason`, `thinking`, `citations`, `tool_calls`;
`usage` (a `Langertha::Usage`: `input_tokens`, `output_tokens`, `total_tokens`,
`cached_tokens`, `cache_write_tokens`; `->{...}` still gives the provider hash);
`rate_limit` (`Langertha::RateLimit`: `requests_remaining`, `tokens_remaining`, and per bucket
`*_reset_at` — a `Moment` — plus `*_reset_after` seconds; `undef` when the wire sent nothing);
`created` (`Langertha::Moment`: numifies to the epoch, stringifies to ISO-8601);
`ttft_seconds` / `total_seconds` (`timing` holds engine-native stages). Test with the
`has_*` predicates before reading optional fields.

## Value objects

| Class | Use |
|---|---|
| `Langertha::Tool` | `from_hash` (MCP / Anthropic / OpenAI / Gemini shapes), `from_list`; `->to($fmt)`; `Tool->format_list($fmt, \@tools)` builds a whole `tools` payload |
| `Langertha::ToolCall` | `ToolCall->extract($fmt, $data)` → list of calls from a raw response (croaks if `$fmt` is a ref); `extract_sniff($data)` only when the format is unknown |
| `Langertha::ToolChoice` | `auto` / `any` / `none` / `specific($name)`, `from_hash`; `->to($fmt)` |
| `Langertha::ToolResult` | `name`, `id`, `content` (MCP content array), `is_error`; `->to($fmt)` gives the result block |
| `Langertha::Usage`, `RateLimit`, `Moment` | see above; `Moment->from_wire($v)` returns undef instead of dying |
| `Langertha::Content::Image` | `from_url` / `from_file` / `from_data` / `from_base64`; put it in `content => [ $text, $img ]` |
| `Langertha::CallResult` | from `simple_embedding_result(_f)` / `simple_transcription_call(_f)` / `simple_image_result(_f)`: `value` plus `usage`, `rate_limit`, `model`, `total_seconds`, `raw` (the bare `simple_embedding` / `simple_transcription` / `simple_image` and their `_f` return only the value) |
| `Langertha::RunContext`, `Role::Runnable` | generic run context + `run_f` contract, used by Raider/Raid nodes |

`$fmt` is a `tool_wire_format`: `openai`, `anthropic`, `gemini`, `ollama`, `responses`
(plus `hermes` / `mcp` for `Tool`). Use the engine's own `$engine->tool_wire_format`.

## Request controls

Set on the engine, or per request through `chat_f`:

- `reasoning_effort` (`none minimal low medium high xhigh max`; values the wire cannot take are
  dropped), `thinking_budget` (Gemini 2.5), `thinking_display` (Anthropic).
- `prompt_cache` / `prompt_cache_ttl` (Anthropic `cache_control`), `prompt_cache_key` (OpenAI).
  A 200 does not prove a cache write; check `usage`.
- Self-hosted (vLLM, SGLang, llama.cpp): `prefix_cache_salt`, `cache_prompt`, `n_cache_reuse`,
  `id_slot`, `priority`, … and `poll_metrics_f` (Prometheus `/metrics`).
- Also: `temperature`, `seed`, `response_size`, `context_size`, `parallel_tool_use`,
  `keep_alive` (Ollama native), Gemini `create_cached_content_f` & co.

## Tool calling with MCP

You bring the MCP client; Langertha does not depend on one. `mcp_servers` takes any
`Net::Async::MCP`-compatible client (it must answer `list_tools` and `call_tool`).

```perl
use MCP::Server; use Net::Async::MCP; use IO::Async::Loop;
my $server = MCP::Server->new(name => 'my-tools', version => '1.0');
$server->tool(
    name => 'search_files', description => 'Search files',
    input_schema => { type => 'object',
        properties => { pattern => { type => 'string' } }, required => ['pattern'] },
    code => sub { my ($tool, $args) = @_;          # $tool is MCP::Tool, not your class
        $tool->text_result(join "\n", glob $args->{pattern}) },   # (text, 1) = error
);
my $mcp = Net::Async::MCP->new(server => $server);
IO::Async::Loop->new->add($mcp);
await $mcp->initialize;
my $engine = Langertha::Engine::Anthropic->new( mcp_servers => [$mcp] );
my $response = await $engine->chat_with_tools_f('Find all .pm files in lib/');
```

`tool_max_iterations` caps the loop; Hermes engines run it with the tools in the prompt.

## Plugins

```perl
package Langertha::Plugin::MyGuard;  use Langertha qw( Plugin );
async sub plugin_before_tool_call {
    my ($self, $name, $input) = @_;
    return if $name eq 'dangerous_tool';   # empty list = skip the call
    return ($name, $input);
}
__PACKAGE__->meta->make_immutable;
```

Attach with `plugins => ['MyGuard', 'Langfuse']` (short names resolve to `Langertha::Plugin::*`,
then `LangerthaX::Plugin::*`). All hooks are `async sub`, chained in order.

| Host | Hooks that fire |
|---|---|
| `Langertha::Chat` (wraps an engine) | `plugin_before_llm_call($conv, $iter)`, `plugin_after_llm_response($data, $iter)`, `plugin_before_tool_call($name, $input)`, `plugin_after_tool_call($name, $input, $result)` |
| `Langertha::Embedder` / `Langertha::ImageGen` | `plugin_before/after_embedding`, `plugin_before/after_image_gen` |
| `Langertha::Raider` (langertha-raider) | the Chat hooks plus `plugin_before_raid(\@msgs)`, `plugin_build_conversation(\@conv)`, `plugin_after_raid($result)` |

Engines (`Engine::Remote`) also compose `Role::PluginHost` for `fire_event_f` custom events.

## Raider — separate distribution langertha-raider

`cpanm Langertha::Raider`; then `use Langertha::Raider` (or `use Langertha qw( Raider )`).

```perl
my $raider = Langertha::Raider->new(
    engine         => $engine,           # with mcp_servers
    mission        => 'You are a code reviewer.',
    max_iterations => 10,
    # optional: max_context_tokens, context_compress_threshold, compression_engine,
    #           raider_mcp => 1 (self-tools: ask_user, pause, abort, ...), plugins => [...]
);
my $result = await $raider->raid_f('Review lib/App.pm');   # keeps history across raids
say $result;
if ($result->is_question) { $result = await $raider->respond_f('Yes, go ahead.') }
# also is_final / is_pause / is_abort; sync wrappers raid / respond
$raider->add_history(user => $text);   # replay persisted turns
$raider->clear_history;
my $m = $raider->metrics;              # { raids, iterations, tool_calls, time_ms }
```

The result class is `Langertha::Raider::Result`; core's `Langertha::Result` is only a stub.

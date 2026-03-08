```
 __                              __   __
|  .---.-.-----.-----.-----.----|  |_|  |--.---.-.
|  |  _  |     |  _  |  -__|   _|   _|     |  _  |
|__|___._|__|__|___  |_____|__| |____|__|__|___._|
---------------|_____|----------------------------
```

<p align="center">
  <em>The clan of fierce vikings with axes and shields to AId your rAId</em>
</p>

<p align="center">
  <a href="https://metacpan.org/pod/Langertha"><img src="https://img.shields.io/cpan/v/Langertha?style=flat-square&label=CPAN" alt="CPAN"></a>
  <a href="https://github.com/Getty/langertha/actions"><img src="https://img.shields.io/github/actions/workflow/status/Getty/langertha/test.yml?style=flat-square&label=CI" alt="CI"></a>
  <a href="https://metacpan.org/pod/Langertha"><img src="https://img.shields.io/cpan/l/Langertha?style=flat-square" alt="License"></a>
  <a href="https://discord.gg/Y2avVYpquV"><img src="https://img.shields.io/discord/1095536723398238308?style=flat-square&label=Discord" alt="Discord"></a>
</p>

---

**Langertha** is a unified Perl interface for LLM APIs. One API, many providers. Supports chat, streaming, embeddings, transcription, MCP tool calling, autonomous agents, observability, and dynamic model discovery.

## Supported Providers

| Provider | Chat | Streaming | Tools (MCP) | Embeddings | Images | Transcription | Models API |
|----------|:----:|:---------:|:-----------:|:----------:|:------:|:-------------:|:----------:|
| [OpenAI](https://platform.openai.com/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| [Anthropic](https://console.anthropic.com/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [Gemini](https://ai.google.dev/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [Ollama](https://ollama.com/) | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | :white_check_mark: |
| [Groq](https://console.groq.com/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | :white_check_mark: | :white_check_mark: |
| [Mistral](https://console.mistral.ai/) :eu: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [DeepSeek](https://platform.deepseek.com/) :cn: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [MiniMax](https://www.minimax.io/) :cn: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [Perplexity](https://docs.perplexity.ai/) :us: | :white_check_mark: | :white_check_mark: | | | | | |
| [Nous Research](https://nousresearch.com/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [Cerebras](https://cloud.cerebras.ai/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | |
| [OpenRouter](https://openrouter.ai/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | |
| [Replicate](https://replicate.com/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | |
| [HuggingFace](https://huggingface.co/) :us: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | |
| [vLLM](https://docs.vllm.ai/) | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | |
| [AKI.IO](https://aki.io/) :eu: | :white_check_mark: | :white_check_mark: | :white_check_mark: | | | | :white_check_mark: |
| [Whisper](https://github.com/fedirz/faster-whisper-server) | | | | | | :white_check_mark: | |

## Quick Start

```bash
cpanm Langertha
```

```perl
use Langertha::Engine::OpenAI;

my $openai = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
    model   => 'gpt-4o-mini',
);

print $openai->simple_chat('Hello from Perl!');
```

## Usage Examples

### Cloud APIs

```perl
use Langertha::Engine::Anthropic;

my $claude = Langertha::Engine::Anthropic->new(
    api_key => $ENV{ANTHROPIC_API_KEY},
    model   => 'claude-sonnet-4-6',
);
print $claude->simple_chat('Generate Perl Moose classes for GeoJSON.');
```

```perl
use Langertha::Engine::Gemini;

my $gemini = Langertha::Engine::Gemini->new(
    api_key => $ENV{GEMINI_API_KEY},
    model   => 'gemini-2.5-flash',
);
print $gemini->simple_chat('Explain quantum computing.');
```

### Local Models with Ollama

```perl
use Langertha::Engine::Ollama;

my $ollama = Langertha::Engine::Ollama->new(
    url   => 'http://localhost:11434',
    model => 'llama3.3',
);
print $ollama->simple_chat('Do you wanna build a snowman?');
```

### AKI.IO :eu: European AI Infrastructure

[AKI.IO](https://aki.io/) is a **European AI model hub** based in Germany. All inference
runs on EU-based infrastructure, making it a strong choice for GDPR-compliant
and data-sovereignty-sensitive applications. No data leaves the EU.

```perl
use Langertha::Engine::AKI;

my $aki = Langertha::Engine::AKI->new(
    api_key => $ENV{AKI_API_KEY},
    model   => 'llama3_8b_chat',
);
print $aki->simple_chat('Hello!');

# OpenAI-compatible API for streaming & tool calling
# Note: native model names are not mapped automatically to /v1 names
my $aki_openai = $aki->openai(model => 'llama3-chat-8b');
```

### Self-hosted with vLLM

```perl
use Langertha::Engine::vLLM;

my $vllm = Langertha::Engine::vLLM->new(
    url   => $ENV{VLLM_URL},
    model => 'meta-llama/Llama-3.3-70B-Instruct',
);
print $vllm->simple_chat('Hello!');
```

## Streaming

Real-time token streaming with callbacks, iterators, or async/await:

```perl
# Callback
$engine->simple_chat_stream(sub {
    print shift->content;
}, 'Write a poem about Perl');

# Iterator
my $iter = $engine->simple_chat_stream_iterator('Tell me a story');
while (my $chunk = $iter->next) {
    print $chunk->content;
}

# Async/await with real-time streaming
use Future::AsyncAwait;

my ($content, $chunks) = await $engine->simple_chat_stream_realtime_f(
    sub { print shift->content },
    'Explain monads'
);
```

## MCP Tool Calling

Langertha integrates with [MCP](https://modelcontextprotocol.io/) (Model Context Protocol) servers via [Net::Async::MCP](https://metacpan.org/pod/Net::Async::MCP). LLMs can discover and invoke tools automatically.

```perl
use IO::Async::Loop;
use Net::Async::MCP;
use Future::AsyncAwait;

my $loop = IO::Async::Loop->new;

# Connect to an MCP server (in-process, stdio, or HTTP)
my $mcp = Net::Async::MCP->new(
    command => ['npx', '@anthropic/mcp-server-web-search'],
);
$loop->add($mcp);
await $mcp->initialize;

# Any engine, same API
my $engine = Langertha::Engine::Anthropic->new(
    api_key     => $ENV{ANTHROPIC_API_KEY},
    model       => 'claude-sonnet-4-6',
    mcp_servers => [$mcp],
);

my $response = await $engine->chat_with_tools_f(
    'Search the web for Perl MCP modules'
);
say $response;
```

The tool-calling loop runs automatically:

1. Gathers available tools from all configured MCP servers
2. Sends chat request with tool definitions to the LLM
3. If the LLM returns tool calls, executes them via MCP
4. Feeds tool results back to the LLM and repeats
5. Returns the final text response

Works with **all engines** that support tool calling (see table above).

### Hermes-Native Tool Calling

For models that support the [Hermes tool calling format](https://nousresearch.com/) (via `<tool_call>` XML tags) but lack API-level tool support, engines compose `Langertha::Role::HermesTools`:

```perl
# NousResearch, AKI, and AKIOpenAI compose HermesTools out of the box
my $nous = Langertha::Engine::NousResearch->new(
    api_key     => $ENV{NOUSRESEARCH_API_KEY},
    mcp_servers => [$mcp],
);

my $aki = Langertha::Engine::AKI->new(
    api_key     => $ENV{AKI_API_KEY},
    mcp_servers => [$mcp],
);
```

Tools are injected into the system prompt and `<tool_call>` tags are parsed from the model's text output. The tool prompt template is customizable via `hermes_tool_prompt`.

## Response Metadata

`simple_chat` returns `Langertha::Response` objects with full metadata — token usage, model, finish reason, timing. Backward-compatible: stringifies to the text content, so existing code works unchanged.

```perl
my $r = $engine->simple_chat('Hello!');
print $r;                    # prints the text (stringification)
say $r->model;               # gpt-4o-mini
say $r->prompt_tokens;       # 12
say $r->completion_tokens;   # 8
say $r->total_tokens;        # 20
say $r->finish_reason;       # stop
```

Works across all engines. Each provider's token counts and metadata are normalized automatically.

### Rate Limiting

Rate limit information from HTTP response headers is extracted automatically and normalized into `Langertha::RateLimit` objects. Available per-response and on the engine (always reflects the latest response):

```perl
my $r = $engine->simple_chat('Hello!');

# Per-response rate limit
if ($r->has_rate_limit) {
    say $r->requests_remaining;              # 499
    say $r->tokens_remaining;                # 29990
    say $r->rate_limit->requests_reset;      # "12s" or RFC 3339
    say $r->rate_limit->raw;                 # all provider-specific headers
}

# Engine always has latest rate limit
say $engine->rate_limit->requests_remaining if $engine->has_rate_limit;
```

Supported providers: OpenAI, Groq, Cerebras, OpenRouter, Replicate, HuggingFace (`x-ratelimit-*`), Anthropic (`anthropic-ratelimit-*`). Local engines (Ollama, vLLM, llama.cpp) typically don't return rate limit headers.

## Chain-of-Thought Reasoning

Reasoning models produce chain-of-thought thinking alongside their answers. Langertha extracts this automatically — the response content is always clean, and thinking is available separately:

```perl
my $r = $engine->simple_chat('Solve this step by step...');
say $r;                  # clean answer
say $r->thinking;        # chain-of-thought reasoning (if any)
say $r->has_thinking;    # check if thinking was produced
```

**Native API extraction** works automatically for providers that return reasoning as a separate field:

| Provider | Reasoning Field | Models |
|----------|----------------|--------|
| DeepSeek | `reasoning_content` | deepseek-reasoner |
| Anthropic | `thinking` content blocks | claude with extended thinking |
| Gemini | `thought` parts | gemini-2.5-flash/pro |
| OpenAI | `reasoning_content` | o1, o3, o4-mini |

**Think tag filtering** handles open-source reasoning models that embed `<think>...</think>` tags inline (DeepSeek R1 via Ollama/vLLM, QwQ, Hermes with reasoning). The filter is enabled by default on all engines and strips tags automatically. Handles both closed and unclosed tags (when models stop mid-thought).

```perl
# NousResearch with reasoning enabled
my $nous = Langertha::Engine::NousResearch->new(
    api_key   => $ENV{NOUSRESEARCH_API_KEY},
    model     => 'DeepHermes-3-Mistral-24B-Preview',
    reasoning => 1,   # enables chain-of-thought system prompt
);
my $r = $nous->simple_chat('Explain why the sky is blue');
say $r;               # clean answer
say $r->thinking;     # <think> content extracted automatically

# Custom tag name for models using different tags
my $engine = Langertha::Engine::vLLM->new(
    url       => $vllm_url,
    model     => 'my-model',
    think_tag => 'reasoning',   # default: 'think'
);
```

## Raider — Autonomous Agent

`Langertha::Raider` is a stateful agent with conversation history and MCP tool calling. It maintains context across multiple interactions ("raids").

```perl
use Langertha::Raider;

my $raider = Langertha::Raider->new(
    engine  => $engine,    # any engine with mcp_servers
    mission => 'You are a code explorer.',
);

# First raid — tools are called automatically, history is saved
my $r1 = await $raider->raid_f('What files are in lib/?');
say $r1;

# Second raid — has context from the first conversation
my $r2 = await $raider->raid_f('Read the main module.');
say $r2;

# Metrics across all raids
say $raider->metrics->{tool_calls};  # cumulative
$raider->clear_history;              # start fresh
```

Key features: persistent history, mission (system prompt), cumulative metrics (raids, iterations, tool_calls, time_ms), context compression, session history, Hermes tool calling support, plugin system.

### Plugins

Extend the Raider with plugins that hook into every stage of the raid lifecycle:

```perl
my $raider = Langertha::Raider->new(
    engine  => $engine,
    plugins => ['Langfuse', 'MyApp::Guardrails'],
);
```

Plugins are Moose classes extending `Langertha::Plugin` with async hook methods:

- `plugin_before_raid` — transform input messages
- `plugin_build_conversation` — transform assembled conversation
- `plugin_before_llm_call` — transform conversation before each LLM call
- `plugin_after_llm_response` — inspect/transform LLM response
- `plugin_before_tool_call` — inspect/skip/transform tool calls
- `plugin_after_tool_call` — transform tool results
- `plugin_after_raid` — transform the final result

Short names are resolved to `Langertha::Plugin::*` or `LangerthaX::Plugin::*`. The built-in `Langfuse` plugin provides full observability as an alternative to engine-level Langfuse.

```perl
# Quick plugin with sugar
package MyApp::Guardrails;
use Langertha qw( Plugin );

around plugin_before_tool_call => async sub {
    my ($orig, $self, $name, $input) = @_;
    my @result = await $self->$orig($name, $input);
    return if $name eq 'dangerous_tool';  # skip
    return @result;
};

__PACKAGE__->meta->make_immutable;
```

### Context Compression

For long-running agents, history can grow large. Enable auto-compression to keep token usage under control:

```perl
my $raider = Langertha::Raider->new(
    engine             => $engine,
    mission            => 'You are an assistant.',
    max_context_tokens => 100_000,           # enables auto-compression
    context_compress_threshold => 0.75,      # compress at 75% (default)
    # compression_engine => $cheap_engine,   # optional: use a cheaper model
);
```

When prompt tokens exceed the threshold, the working history is automatically summarized via LLM before the next raid. The summary replaces the history, keeping context compact while preserving key information.

### Session History

The full session history (including tool calls and results) is archived in `session_history` — never auto-compressed, persisted across `clear_history` and `reset`:

```perl
# Register MCP tool so the LLM can query its own history
$raider->register_session_history_tool($mcp_server);

# Or inspect programmatically
my @all = @{$raider->session_history};
```

### Mid-Raid Context Injection

Feed additional context to the agent while it's working — it picks it up at the next iteration:

```perl
# From another async task, timer, or callback:
$raider->inject('Also check the test files');
$raider->inject({ role => 'user', content => 'Focus on .pm files' });

# Or use on_iteration for programmatic injection per iteration:
my $raider = Langertha::Raider->new(
    engine  => $engine,
    on_iteration => sub {
        my ($raider, $iteration) = @_;
        return ['Check the error log'] if $iteration == 3;
        return;
    },
);
```

Injected messages are persisted in history so the agent remembers them across raids.

## Observability with Langfuse

Every engine has [Langfuse](https://langfuse.com/) observability built in. Just set env vars — zero code changes:

```bash
export LANGFUSE_PUBLIC_KEY=pk-lf-...
export LANGFUSE_SECRET_KEY=sk-lf-...
export LANGFUSE_URL=http://localhost:3000   # optional, defaults to cloud
```

```perl
my $engine = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
);

$engine->simple_chat('Hello!');  # auto-traced
$engine->langfuse_flush;         # send events to Langfuse
```

`simple_chat` calls are auto-instrumented with traces and generations (including token usage and timing). Raider raids create cascading traces with proper hierarchy:

```
Trace: "raid" (with userId, sessionId, tags)
  ├── Span: iteration-1
  │     ├── Generation: llm-call (with usage, modelParameters)
  │     ├── Span: tool: list_files (with input/output, timing)
  │     └── Span: tool: read_file
  ├── Span: iteration-2
  │     └── Generation: llm-call (final response)
  └── [trace updated with output at end]
```

Customize Raider traces with user/session/tag metadata:

```perl
my $raider = Langertha::Raider->new(
    engine             => $engine,
    langfuse_user_id   => 'user-42',
    langfuse_session_id => 'session-abc',
    langfuse_tags      => ['production', 'v2'],
);
```

Disabled by default — active only when both keys are set. A Kubernetes manifest for self-hosted Langfuse is included: `kubectl apply -f ex/langfuse-k8s.yaml`

## Wrapper Classes

Wrap an engine with optional overrides for specific use cases:

```perl
use Langertha::Chat;
use Langertha::Embedder;
use Langertha::ImageGen;

# Chat wrapper with custom system prompt and model
my $chat = Langertha::Chat->new(
    engine        => $openai,
    system_prompt => 'You are a pirate.',
    model         => 'gpt-4o',
    temperature   => 0.9,
);
print $chat->simple_chat('Ahoy!');

# Embedding wrapper with specific model
my $embedder = Langertha::Embedder->new(
    engine => $openai,
    model  => 'text-embedding-3-small',
);
my $vec = $embedder->simple_embedding('some text');

# Image generation wrapper
my $imagegen = Langertha::ImageGen->new(
    engine  => $openai,
    model   => 'gpt-image-1',
    size    => '1024x1024',
    quality => 'high',
);
my $images = $imagegen->simple_image('A cat in space');
```

Wrappers support plugins via the same `plugins` attribute as Raider.

## Async/Await

All operations have async variants via [Future::AsyncAwait](https://metacpan.org/pod/Future::AsyncAwait):

```perl
use Future::AsyncAwait;

async sub main {
    my $response = await $engine->simple_chat_f('Hello!');
    say $response;
}

main()->get;
```

## Embeddings

```perl
use Langertha::Engine::OpenAI;

my $openai = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
);

my $embedding = $openai->simple_embedding('Some text to embed');
# Returns arrayref of floats
```

Also supported by Ollama (e.g. `mxbai-embed-large`).

## Image Generation

```perl
use Langertha::Engine::OpenAI;

my $openai = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
);

my $images = $openai->simple_image('A viking with an axe in pixel art');
# Returns arrayref of image objects with url or b64_json
```

Default model is `gpt-image-1`. Pass `size`, `quality`, or `n` as extra arguments.

## Transcription (Whisper)

```perl
use Langertha::Engine::Whisper;

my $whisper = Langertha::Engine::Whisper->new(
    url => $ENV{WHISPER_URL},
);
print $whisper->simple_transcription('recording.ogg');
```

OpenAI and Groq also support transcription via their Whisper endpoints:

```perl
my $openai = Langertha::Engine::OpenAI->new(
    api_key => $ENV{OPENAI_API_KEY},
);
print $openai->simple_transcription('recording.ogg');
```

## Dynamic Model Discovery

Query available models from any provider API:

```perl
my $models = $engine->list_models;
# Returns: ['gpt-4o', 'gpt-4o-mini', 'o1', ...]

my $models = $engine->list_models(full => 1);       # Full metadata
my $models = $engine->list_models(force_refresh => 1); # Bypass cache
```

Results are cached for 1 hour (configurable via `models_cache_ttl`).

## Testing

```bash
# Run all unit tests
prove -l t/

# Run mock tool calling tests (no API keys needed)
prove -l -It/lib t/64_tool_calling_ollama_mock.t
prove -l -It/lib t/66_tool_calling_hermes.t

# Run live integration tests
TEST_LANGERTHA_OPENAI_API_KEY=...    \
TEST_LANGERTHA_ANTHROPIC_API_KEY=... \
TEST_LANGERTHA_GEMINI_API_KEY=...    \
prove -l t/80_live_tool_calling.t

# Ollama with multiple models
TEST_LANGERTHA_OLLAMA_URL=http://localhost:11434     \
TEST_LANGERTHA_OLLAMA_MODELS=qwen3:8b,llama3.2:3b   \
prove -l t/80_live_tool_calling.t

# NousResearch (Hermes-native tool calling via <tool_call> tags)
TEST_LANGERTHA_NOUSRESEARCH_API_KEY=... \
prove -l t/80_live_tool_calling.t

# vLLM (requires --enable-auto-tool-choice and --tool-call-parser on server)
TEST_LANGERTHA_VLLM_URL=http://localhost:8000/v1              \
TEST_LANGERTHA_VLLM_MODEL=Qwen/Qwen2.5-3B-Instruct           \
TEST_LANGERTHA_VLLM_TOOL_CALL_PARSER=hermes                   \
prove -l t/80_live_tool_calling.t
```

## Examples

See the [`ex/`](ex/) directory for runnable examples:

| Example | Description |
|---------|-------------|
| `synopsis.pl` | Basic usage with multiple engines |
| `response.pl` | Response metadata (tokens, model, timing) |
| `streaming_callback.pl` | Real-time streaming with callbacks |
| `streaming_iterator.pl` | Streaming with iterator pattern |
| `streaming_future.pl` | Async streaming with Futures |
| `async_await.pl` | Async/await patterns |
| `mcp_inprocess.pl` | MCP tool calling with in-process server |
| `mcp_stdio.pl` | MCP tool calling with stdio server |
| `hermes_tools.pl` | Hermes-native tool calling with NousResearch |
| `raider.pl` | Autonomous agent with MCP tools and history |
| `raider_run.pl` | Full Raider demo: self-tools, engine/MCP catalogs, bootstrapping |
| `raider_plugin_sugar.pl` | Raider with plugins using class sugar |
| `raider_rag.pl` | RAG (Retrieval-Augmented Generation) with Raider |
| `langfuse.pl` | Langfuse observability tracing |
| `langfuse-k8s.yaml` | Kubernetes manifest for self-hosted Langfuse |
| `embedding.pl` | Text embeddings |
| `transcription.pl` | Audio transcription with Whisper |
| `structured_output.pl` | Structured/JSON output |

## Community

- **CPAN**: [Langertha on MetaCPAN](https://metacpan.org/pod/Langertha)
- **GitHub**: [Getty/langertha](https://github.com/Getty/langertha) - Issues & PRs welcome
- **Discord**: [Join the community](https://discord.gg/Y2avVYpquV)
- **IRC**: `irc://irc.perl.org/ai`

## License

This is free software licensed under the same terms as Perl itself (Artistic License / GPL).

---

> **THIS API IS WORK IN PROGRESS**

# Langertha — CLAUDE.md

## Overview

Langertha is a Perl LLM framework supporting 15+ engines via composable Moose roles. It provides chat, tool calling (MCP), streaming, embeddings, transcription, and an autonomous agent (Raider).

## Build System

Uses `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
dzil test           # Build and test
prove -l t/         # Run tests directly
prove -lv t/60_tool_calling.t  # Single test, verbose
```

## Architecture

### Engine Hierarchy (lib/Langertha/Engine/)

```
Engine::Remote              url required, JSON + HTTP
  │
  ├── Engine::AnthropicBase /v1/messages format, x-api-key auth, SSE streaming
  │     │
  │     ├── Anthropic       Claude models, thinking blocks, tool_use
  │     ├── MiniMaxAnthropic MiniMax via legacy /anthropic/v1 shim endpoint
  │     └── LMStudioAnthropic LM Studio Anthropic-compatible endpoint
  │
  ├── Engine::OpenAIBase    /chat/completions format, Bearer auth, SSE streaming
  │     │
  │     │  Cloud providers (url has default, api_key from env)
  │     ├── OpenAI          gpt-4o, embeddings, whisper transcription, structured output
  │     ├── DeepSeek        deepseek-chat/reasoner, structured output
  │     ├── Groq            ultra-fast inference, whisper transcription, structured output
  │     ├── Mistral         EU-hosted, embeddings, structured output
  │     ├── MiniMax         Shanghai (default), 1M context window, M2.7
  │     ├── NousResearch    Hermes models, <tool_call> XML tool format
  │     ├── Cerebras        wafer-scale chips, fastest inference
  │     ├── OpenRouter      meta-provider, 300+ models, provider/model format
  │     ├── Replicate       thousands of open-source models, owner/model format
  │     ├── HuggingFace     Inference Providers, org/model format
  │     ├── Perplexity      search-augmented, citations — NO tool calling
  │     ├── AKIOpenAI       EU/Germany, GDPR-compliant
  │     │
  │     │  Self-hosted (url required, no api_key)
  │     ├── OllamaOpenAI    Ollama /v1 endpoint, embeddings
  │     ├── vLLM            high-throughput inference, single-model server
  │     └── LlamaCpp        llama.cpp server, embeddings
  │
  │  Non-OpenAI formats (own request/response handling)
  ├── Gemini                ?key= auth, functionDeclarations, thought parts
  ├── Ollama                native /api/chat, NDJSON streaming, OpenAPI spec
  └── AKI                   key-in-body auth, EU/Germany, /api/call/{model}
```

Whisper extends OpenAI (inherits full chain).

### Roles (lib/Langertha/Role/)

- **Chat** — sync/async chat (`simple_chat`, `simple_chat_f`)
- **Tools** — MCP tool calling loop (`chat_with_tools_f`, `mcp_servers`)
- **Streaming** — SSE streaming responses
- **Embedding** — Vector embeddings (`simple_embedding`)
- **Transcription** — Audio transcription
- **HTTP** — HTTP transport (sync + async via IO::Async)
- **JSON** — JSON encoding/decoding
- **SystemPrompt** — System prompt management
- **Temperature**, **ResponseSize**, **ContextSize**, **Seed** — Generation parameters
- **ResponseFormat** — JSON mode / structured output
- **Models** — Model selection and defaults
- **Langfuse** — Observability (traces, spans, generations)
- **OpenAICompatible** — OpenAI-format request/response handling
- **OpenAPI** — OpenAPI spec validation
- **ThinkTag** — Chain-of-thought `<think>` tag filtering

### Core Classes

- **Langertha::Response** — LLM response with metadata, stringifies to content
- **Langertha::Stream** / **Stream::Chunk** — Streaming iteration
- **Langertha::Request::HTTP** — Internal HTTP request wrapper
- **Langertha::Raider** — Autonomous agent (see below)
- **Langertha::Raider::Result** — Raid result with type handling

## Raider (Autonomous Agent)

`Langertha::Raider` wraps an engine with conversation history, MCP tools, and a multi-turn tool-calling loop.

### Key Features

- **Conversation history** persisted across raids (only user + final assistant messages)
- **Session history** — full archive including tool calls (never compressed)
- **Auto-compression** — summarizes history when token threshold exceeded
- **Metrics** — tracks raids, iterations, tool calls, timing
- **Langfuse integration** — traces, spans, generations per raid
- **Hermes tool calling** — for models without native tool support
- **Mid-raid injection** — `inject()` and `on_iteration` callback
- **Self-tools** (virtual) — `raider_mcp => 1` enables agent-controlled tools:
  - `raider_ask_user` — ask user questions (sync callback or async pause)
  - `raider_pause` — pause execution for later resumption
  - `raider_abort` — abort the raid
  - `raider_wait` — wait N seconds
  - `raider_wait_for` — wait for external condition
  - `raider_session_history` — query/search session history
  - `raider_manage_mcps` — list/activate/deactivate catalog MCPs
  - `raider_switch_engine` — switch between catalog engines (requires `engine_catalog`)
- **Inline tools** — `tools => [...]` for quick tool definitions without MCP server setup
- **MCP catalog** — `mcp_catalog => {...}` for dynamic MCP server management
- **Engine catalog** — `engine_catalog => {...}` for runtime engine switching via `switch_engine`/`reset_engine`
- **Embedding search** — semantic session history search via cosine similarity
- **Result objects** — `raid_f` returns `Langertha::Raider::Result` (stringifies for backward compat)
- **Continuation** — `respond_f` resumes after question/pause results

### Raider API

```perl
my $result = await $raider->raid_f(@messages);  # Returns Result
my $result = $raider->raid(@messages);           # Sync wrapper

# Interactive self-tools
if ($result->is_question) {
    my $next = await $raider->respond_f($answer);
}

# Engine switching (programmatic API, NOT LLM-controlled)
$raider->switch_engine('smart');     # Switch to catalog engine
$raider->reset_engine;               # Back to default engine
my $engine = $raider->active_engine; # Current engine
my $info = $raider->engine_info;     # { name, class, model }
my $list = $raider->list_engines;    # All engines with status
```

## OOP Framework

Moose exclusively. All classes use `__PACKAGE__->meta->make_immutable`.

## Async

`Future::AsyncAwait` (>= 0.66) for all async methods. IO::Async for event loop.

## MCP (Model Context Protocol)

- `Net::Async::MCP` — MCP client
- `MCP::Server` — MCP server (tool definitions)
- Tool definitions use `inputSchema` (camelCase) in MCP format
- Each engine's `format_tools()` converts to provider format

## Testing

- `TEST_LANGERTHA_<ENGINE>_API_KEY` env vars for live tests
- Live tests cost real money — be selective
- Unit tests in `t/00-75*.t`, live tests in `t/80-86*.t`
- Test framework: `Test2::Bundle::More`

## POD

Uses `@Author::GETTY` PodWeaver. `# ABSTRACT:` required on every .pm file. Inline `=attr`, `=method`, `=seealso` directives.

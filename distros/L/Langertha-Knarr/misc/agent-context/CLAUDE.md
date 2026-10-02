# Langertha::Knarr — CLAUDE.md

## Overview

Knarr is an LLM proxy that accepts requests in OpenAI, Anthropic, Ollama, A2A, ACP or AG-UI format, routes them to any Langertha backend engine, and traces them via Langfuse (when Langfuse keys are set).

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/knarr-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `knarr-worker` (default) |
| Write/extend tests | `knarr-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `knarr-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Build System

Uses `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
dzil test           # Build and test
prove -l t/         # Run tests directly
prove -lv t/10-config.t  # Single test, verbose
```

## Architecture

### Request Flow

```
Client → [OpenAI|Anthropic|Ollama|A2A|ACP|AG-UI] → Knarr
                                               │
                         ┌─────────────────────┴───────────────┐
                         │                                     │
        model configured (or discovered         model unknown, or discovered
        elsewhere), or no upstream for          from that upstream, AND a
        the protocol                            passthrough upstream for it
                         │                                     │
  [RequestLog] → [Tracing] → Handler::Router          Raw HTTP 1:1 (Knarr.pm)
                         │                                     │
   model → engine │ unknown → default engine │ none → 404   Langfuse trace only
```

- **Raw passthrough** (unknown model, protocol has a `passthrough:` upstream) pipes
  all HTTP bytes 1:1 to the upstream with the client's own headers/key — preserves
  tool_use, usage, cache_control. Traced, not request-logged. Knarr's own
  `proxy_api_key` is removed from `Authorization`/`x-api-key` element by element, a
  header left empty is dropped (k44, k53; `Knarr::_without_proxy_key`, every forwarding
  path); Ollama `/api/generate` goes to
  the upstream's `/api/generate` (k46).
- `passthrough: true` = openai + anthropic only; ollama needs an explicit URL;
  A2A/ACP/AG-UI never pass through (k41).
- `auto_discover` feeds the model lists; a model known only from it goes raw passthrough
  when the client protocol's upstream is the endpoint that listed it (same
  scheme/host/port/path, trailing `/v1` ignored -- k54, `Passthrough::same_upstream`;
  `Router::discovered_url` + `Passthrough::is_upstream_for`) AND the request still
  carries a provider key once the proxy key is stripped (OpenAI `Authorization`,
  Anthropic `x-api-key`/`Authorization`, Ollama none; `Knarr::_carries_provider_key`),
  else it is routed (k47, k52). If that raw passthrough gets a 401 from the upstream
  (placeholder key), the status is inspected before any byte reaches the client and the
  request is answered through the handler chain instead (engine, Knarr's key; native +
  PSGI, sync + stream); upstream asked once, one trace (Handler::Tracing) with metadata
  `passthrough_fallback: 401` -- the raw trace of such a request opens only once the
  status rules the fallback out (`Tracing::start_trace` `start_hires`). Other statuses
  and unknown models' 401s pass through (k66; `Knarr::_raw_passthrough_falls_back`).
  An id several endpoints list belongs to the passthrough
  upstream's endpoint, else the first by config name; collisions logged at debug (k55).
  Models under `models:` are always routed.
- No model in the request (A2A always, ACP w/o `agent_name`) → default engine with its
  own `model:` (k42). Nothing can serve → 404 in the protocol's error shape.
- Request fields on the routed path: tools/tool_choice, response_format, temperature,
  max_tokens, seed, parallel_tool_calls, prompt_cache_key, reasoning_effort (Anthropic
  `thinking`/`output_config.effort` and Ollama `think` mapped by `Reasoning`), images
  (`Image`) — all capability-gated per engine.

### Module Structure

- **Langertha::Knarr** — IO::Async server, dispatch, raw passthrough
- **Langertha::Knarr::Config** — YAML config loader, validation, env scanning
- **Langertha::Knarr::Router** — Model → Engine routing with caching + auto-discovery
- **Langertha::Knarr::Request** — Normalized request value object (protocol, messages, tools, tool_choice, response_format, …)
- **Langertha::Knarr::Response** — Normalized response value object (content, model, usage, tool_calls, finish_reason); `coerce()` upgrades any legacy shape
- **Langertha::Knarr::Stream** — Async chunk iterator; `from_list`, `from_callback` constructors
- **Langertha::Knarr::Tracing** — Langfuse trace/generation per request (async flush via Net::Async::HTTP); transport `ingestion` (batch API) or `otel` (OTLP/HTTP JSON spans, built at `end_trace`)
- **Langertha::Knarr::RequestLog** — JSONL per-request logging
- **Langertha::Knarr::Session** — Per-conversation state
- **Langertha::Knarr::PSGI** — PSGI adapter (buffered streams, same auth + raw passthrough)
- **Langertha::Knarr::Reasoning** — Anthropic `thinking` / Ollama `think` → normalized `reasoning_effort` (budget_tokens via core BudgetPolicy)
- **Langertha::Knarr::PassthroughUsage** — reads token usage + model off a copy of a raw passthrough answer (JSON body or SSE/NDJSON frames) for the Langfuse trace; forwarded bytes untouched
- **Langertha::Knarr::Image** — face image parts (OpenAI image_url, Anthropic image blocks, Ollama images) → core `Langertha::Content::Image`; no-op on a core that cannot write every content format
- **Langertha::Knarr::Manifest** — `/.well-known/langertha.json` provider manifest from the exposed model surface (needs core `Langertha::Manifest::Builder`, else 404)
- **Langertha::Knarr::Protocol** — Moose role for all wire protocols
- **Langertha::Knarr::Protocol::OpenAI** — `/v1/chat/completions`, `/v1/models`
- **Langertha::Knarr::Protocol::Anthropic** — `/v1/messages`
- **Langertha::Knarr::Protocol::Ollama** — `/api/chat`, `/api/generate`, `/api/tags`, `/api/version`, `/api/show`
- **Langertha::Knarr::Protocol::A2A** — Google Agent2Agent JSON-RPC (`GET /.well-known/agent.json`, `POST /`)
- **Langertha::Knarr::Protocol::ACP** — BeeAI/Linux Foundation ACP (`GET /agents`, `POST /runs`)
- **Langertha::Knarr::Protocol::AGUI** — CopilotKit AG-UI (`POST /awp`)
- **Langertha::Knarr::Handler** — Moose role for all handlers
- **Langertha::Knarr::Role::UpstreamHTTP** — timed Net::Async::HTTP client (`timeout` total / `stall_timeout` streaming) for Passthrough, A2AClient, ACPClient
- **Langertha::Knarr::Handler::Router** — Model routing, passthrough fallback
- **Langertha::Knarr::Handler::Passthrough** — Raw HTTP forwarding to upstream APIs
- **Langertha::Knarr::Handler::Tracing** — Langfuse decorator (wraps any handler)
- **Langertha::Knarr::Handler::RequestLog** — JSONL logging decorator
- **Langertha::Knarr::Handler::Engine** — Single Langertha engine handler
- **Langertha::Knarr::Handler::Raider** — Per-session Langertha::Raider
- **Langertha::Knarr::Handler::Code** — Coderef handler (tests/fakes)
- **Langertha::Knarr::Handler::A2AClient** — Remote A2A agent consumer
- **Langertha::Knarr::Handler::ACPClient** — Remote ACP agent consumer
- **Langertha::Knarr::CLI** — MooX::Cmd entry point
- **Langertha::Knarr::CLI::Cmd::Start** — `knarr start` (also `--from-env` for Docker)
- **Langertha::Knarr::CLI::Cmd::Models** — `knarr models`
- **Langertha::Knarr::CLI::Cmd::Check** — `knarr check`
- **Langertha::Knarr::CLI::Cmd::Init** — `knarr init` (env scanning, config generation)
- **Langertha::Knarr::CLI::Cmd::Container** — deprecated alias of `start --from-env -p 8080 -p 11434` (no options of its own, always `0.0.0.0`)
- **Langertha::Knarr::CLI::Role::GlobalOptions** — `-c`/`-v` accepted after `start`/`check`/`models` too

### Streaming Formats

| Format | Protocol | End Marker |
|--------|----------|------------|
| OpenAI | SSE | `data: [DONE]` |
| Anthropic | SSE | `event: message_stop` |
| Ollama | NDJSON | `{"done": true}` |
| A2A | SSE | status event with `final: true` |
| ACP | SSE | `event: run.completed` |
| AG-UI | SSE | `RUN_FINISHED` event |

## OOP Framework

- **Moose**: Knarr.pm, Handler role, all Handler::* modules, Protocol role + Protocol::* modules, Role::UpstreamHTTP, Request, Response, Session, Stream, Manifest, PSGI, Reasoning, PassthroughUsage
- **Plain** (functions): Image
- **Moo**: CLI, Config, Router, Tracing, RequestLog

CLI uses MooX::Cmd + MooX::Options.

## Config Format

Reference = `Config.pm` POD (one `=attr` per key, with its env var); annotated
example in `share/example-config.yaml`.

- `listen` default `127.0.0.1:8080` + `127.0.0.1:11434`. `knarr start -p N` replaces
  it with `-H` (default `0.0.0.0`):N — the Docker CMD passes `-p 8080 -p 11434`.
- Passthrough is **off** unless `passthrough:` is set; `--from-env` turns it on.
- `auto_discover` default 0 (on under `--from-env` and in `knarr init` output).

```yaml
listen:
  - "0.0.0.0:8080"
  - "0.0.0.0:11434"
models:
  gpt-4o:
    engine: OpenAI
    api_key_env: OPENAI_API_KEY   # else only LANGERTHA_OPENAI_API_KEY is read
  local:
    engine: OllamaOpenAI
    url: http://gpu-box:11434/v1   # not localhost:11434 — Knarr listens there
    context_size: 32768            # Ollama/LMStudio native only
    user_agent_timeout: 600
default:
  engine: OpenAI
  api_key_env: OPENAI_API_KEY
auto_discover: true
passthrough:                       # or: true (openai + anthropic)
  anthropic: https://api.anthropic.com
  openai: https://api.openai.com
proxy_api_key: ${KNARR_API_KEY}
public_url: https://knarr.example  # manifest base URL
langfuse: { url: "http://localhost:3000", public_key: pk-lf-x, secret_key: sk-lf-x, trace_name: knarr-proxy, transport: ingestion, timeout: 15 }  # or otel (OTLP/HTTP JSON)
logging: { file: requests.jsonl, dir: requests/ }
upstream_timeout: 300              # 0 disables
upstream_stall_timeout: 120
probe_capabilities: 1
probe_timeout: 10
ollama_compat_version: 0.34.4      # x.y.z only, >= 0.6.4 for VS Code Copilot
workers: 1                         # KNARR_WORKERS; knarr start -w wins
a2a: { name: Langertha Knarr Agent, description: LLM agent served through Langertha Knarr }  # agent card
```

## Testing

```bash
prove -l t/         # All tests
prove -lv t/10-config.t   # Config tests
```

## CLI

```bash
knarr start                                # Start with ./knarr.yaml
knarr start -c production.yaml -v          # Custom config, verbose (-c/-v also before the subcommand)
knarr start --from-env                     # Auto-detect config from ENV
knarr start --from-env -p 8080 -p 11434   # ENV config, custom ports
knarr start -p 9090                        # Single port on 0.0.0.0 (-H to change)
knarr start --log-file x.jsonl -n my-trace # Dashed or underscored long options, any position
knarr models                               # List models
knarr models --format json                 # JSON output
knarr check                                # Validate config
knarr init                                 # Generate config from env
knarr init -e .env -e .env.local           # Scan .env files (.env, .env.local, ~/.env always)
knarr init -l 0.0.0.0:8080 -o knarr.yaml   # Listen address, output file
```

`-w/--workers N` (else `workers:` / `KNARR_WORKERS`, default 1 = no fork): prefork — the parent binds, runs discovery +
capability probe once, forks N workers on the same sockets, restarts dead ones (backoff
up to 30 s), forwards SIGTERM/SIGINT (`Knarr::run` / `_run_workers`, k51). Sessions are
per worker.

## Environment

- `KNARR_DEBUG=1` — Enable verbose logging (same as `--verbose`)
- `KNARR_API_KEY` (proxy_api_key), `KNARR_PUBLIC_URL` (public_url)
- `KNARR_LOG_FILE`, `KNARR_LOG_DIR` (logging.file / logging.dir)
- `KNARR_TRACE_NAME`, `LANGFUSE_TRACE_NAME`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_URL` / `LANGFUSE_BASE_URL`
- `KNARR_LANGFUSE_TRANSPORT` (langfuse.transport: `ingestion` default, `otel`), `KNARR_LANGFUSE_TIMEOUT` (langfuse.timeout, default 15 s, 0 = none)
- `KNARR_UPSTREAM_TIMEOUT`, `KNARR_UPSTREAM_STALL_TIMEOUT`, `KNARR_PROBE_CAPABILITIES`, `KNARR_PROBE_TIMEOUT`, `KNARR_OLLAMA_COMPAT_VERSION`
- `KNARR_A2A_NAME`, `KNARR_A2A_DESCRIPTION` (a2a.name / a2a.description)
- `KNARR_WORKERS` (workers)
- Provider keys for `--from-env` / `knarr init`: `Config.pm` `@ENGINE_DEFS` (`LANGERTHA_*` > bare > `TEST_LANGERTHA_*`)

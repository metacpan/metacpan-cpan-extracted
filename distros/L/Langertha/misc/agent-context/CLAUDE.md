# Langertha — CLAUDE.md

Canonical instruction file for the Langertha repo. Langertha is a Perl LLM framework supporting
~25 engines via composable Moose roles: chat, tool calling (MCP), streaming, embeddings,
transcription, and structured output. The autonomous agent (Raider) lives in the
sibling distribution langertha-raider (`Langertha::Raider`, `requires 'Langertha'`).

This distribution ships its own agent skills (`.claude/skills/`), agents (`.claude/agents/`),
and house rules (`.claude/rules/`). The engineering discipline, delegation, coordination,
public-issue and release rules live in `.claude/rules/langertha-rules.md` — imported here so
they load for the main agent and every subagent.

@.claude/rules/langertha-rules.md

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — principle
and lane are in the house rules. Agents in this repo:

| Task | Agent |
|---|---|
| Implement / refactor / debug / test behavior-relevant code | `langertha-worker` (default) |
| Async & transport: Future/IO::Async semantics, HTTP backend seam, streaming, MetricsPoll, hangs | `langertha-async-worker` |
| Change the wire seam itself: Tool/ToolCall/ToolResult/ToolChoice, capability registry, `chat_f` rewrite matrix, reasoning/cache wire formats | `langertha-wire-worker` |
| Review a diff / branch / fix wave (read-only, severity-ranked findings + verdict) | `langertha-reviewer` |
| Write / extend tests (regression, TDD red phase, fixtures, transport tests) | `langertha-test-writer` |
| User-facing POD, `lib/Langertha.pm` catalogues, `Changes` entries | `langertha-pod-writer` |
| Commits, `Changes`, card → done, pre-release audit | `langertha-release-manager` |
| Backfill & record architecture decisions in `docs/adr/` | `langertha-adr-auditor` |
| Validate / red-team a plan against LLM-provider reality; market & provider Sonderheiten | `langertha-llm-advisor` |

The natural chain: orchestrator plans → `langertha-llm-advisor` validates it against provider
reality → `langertha-worker` (or the `langertha-async-worker` / `langertha-wire-worker`
specialist) implements → `langertha-reviewer` reviews → `langertha-adr-auditor` records the
decision → `langertha-release-manager` audits before a release.

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main agent
delegates rather than loading them. Skill sources live under `.claude/skills/`.

## Coordination & public issues

- **karr** (`refs/karr/*`, board state in git refs) is the internal AI work board — always in
  scope, just use it (`karr board`, `karr list`, `karr create …`). One board, single repo.
- **GitHub issues** (`gh`, `github.com/Getty/langertha`) are the **public** tracker — real
  users' bug reports. **Never touch without explicit instruction.** Guardrails: house rules +
  skill `langertha-github-issues`.

## Architecture decisions (ADRs)

`docs/adr/` records the WHY behind architecturally-significant decisions so it survives
refactors:

- **0001** — tool wire-translation routes through value objects keyed by `tool_wire_format`
- **0002** — engine capabilities derive from the composed role inventory
- **0003** — `Response.tool_calls` is the single source of truth for emitted tool calls
- **0004** — provider-specific wire extras extend the request body / `Response` (no `extra_body` side-channel)
- **0005** — structured output and forced tool calling are unified; `chat_f` auto-rewrites per capability
- **0006** — engine inheritance encodes the wire dialect; roles encode capabilities
- **0007** — Raider keeps a never-compressed session archive plus an auto-compressed working history
- **0008** — Raider exposes its control surface to the model as virtual self-tools
- **0009** — request-side control params (reasoning effort, prompt caching) as a per-concern wire-format quartet
- **0010** — canonical inbound `ToolCall->extract($fmt,$data)` + symmetric `ToolChoice->to($fmt)` complete the value-object seam
- **0011** — response timing: engine-agnostic seconds + engine-native stages, first-write-wins
- **0012** — self-hosted runtime knobs as a per-concern wire-format value object
- **0013** — the wire envelope is a composed role (parallel `AnthropicCompatible`), nuancing 0006
- **0014** — self-hosted engines expose runtime metrics via `Role::Runtime::MetricsPoll` (Prometheus `/metrics` scrape)
- **0015** — `-excludes` role-composition pattern + per-family `engine_capabilities` correction (cache-control direction-pair); the per-dialect generation-parameter block as a deliberate dialect split
- **0016** — a wire envelope becomes a `Role::<X>Compatible` only when a second consumer needs it from a different parent; capability roles are roles from day one
- **0017** — `Response.created` is a `Langertha::Moment` value object (`0+` = epoch, `""` = ISO stamp with sub-seconds), reversing karr #92's engine-side epoch conversion
- **0018** — where a provider's wire *spelling* is normalized: value-object door (universal) / dialect role (family) / engine `around chat_response` (one provider)
- **0019** — model-scoped capability corrections (amends 0002): declarative `model_capability_corrections` keyed on `chat_model` (layer 3)
- **0020** — Open-Responses envelope as third composed role `Role::ResponsesCompatible` (OpenAIResponses + Perplexity, divergence hooks — six since k213)
- **0021** — pairwise capability exclusions (tools + `response_format`) croak at the `chat_f`/streaming layer — mechanism superseded by 0024
- **0022** — `RateLimit` resets split into typed instant (`*_reset_at`) + duration (`*_reset_after`), `undef` when the wire sent neither; `retry_after` seconds from `Retry-After`, errors (429) recorded before the croak (k300)
- **0023** — per-model reasoning wire-truth is a typed `Reasoning::Profile` resolved via `for_model($id)`; carries `is_reasoning_model` (k186) and multi-digit guards (k196)
- **0024** — pairwise capability exclusions are model-scoped (`model_capability_exclusions` on `Role::Chat`), engine-scoped on Groq/Cerebras
- **0025** — `temperature` emission is gated on resolved reasoning effort for OpenAI reasoning models (drop+carp; `temperature=1` passes)
- **0026** — Raider/Raid extracted to sibling dist `langertha-raider`; core keeps generic primitives (`RunContext`, `Role::Runnable`) and the seams
- **0027** — sync LWP fallback for the async `_f` transport (`Request::SyncHTTP`, backend selection in `Role::AsyncHTTP`); IO::Async/Net::Async::HTTP are `recommends`
- **0028** — public hook surface for sibling dists: `async_request_f`, `async_loop` (`Maybe[loop]`), `langfuse_timestamp`, `Usage->from_raw`; `tool_loop_response` / `tool_loop_calls` (k341)
- **0029** — provider manifest v1 (`Langertha::Manifest`): strict structure, open values, no secrets, dialect vocabulary incl. `anthropic-compat`, model-scoped capability allowlist
- **0030** — server-side tools are a wire-pinned value object (`Langertha::ServerTool`, croaks off its wire) + `Role::ServerTools`/`server_tools` flag; provider-executed calls go to `Response.server_tool_calls`, never `tool_calls`; citations merged, deduped by url without `utm_*`
- **0031** — `Usage.input_tokens` keeps the wire's meaning; `input_includes_cache` records whether cache reads/writes are in it, and `Pricing` (optional cache rates) prices each token once
- **0032** — learned model capabilities: explicit `probe_model_capabilities_f` reads the provider's own model metadata (`Langertha::ModelProbe`, keyed by `model_metadata_format`) into a per-instance store applied after layer 3 (authoritative for reported models, under the layer-1/2 wire gates); `image_input` only; never implicit
- **0033** — `tool_wire_format` is model-scoped on `Engine::NousResearch`: resolved per instance from `chat_model` via `_is_hermes_model` (`hermes` for Hermes models, `openai` default for the ~341-model gateway's other slugs); the k251 capability rule and the `reasoning` prompt follow the same predicate (amends 0001/0002/0019, k238)
- **0034** — non-chat calls (embedding / transcription / image) return an opt-in `Langertha::CallResult` (value + `usage` via `Usage->from_raw`, `rate_limit`, `model`, `total_seconds`, `raw`) from `simple_embedding_result(_f)` / `simple_transcription_call(_f)` / `simple_image_result(_f)`; deliberately not `Langertha::Response` (chat-shaped), bare methods unchanged
- **0035** — a bound Gemini `cachedContent` owns `systemInstruction` / `tools` / `toolConfig`: `generateContent` drops them (both spellings, body and `%extra`) and carps once per engine, rather than croaking or merging into the cache; evidence is the observed server 400, not the docs (k340)
- **0036** — one Langertha-owned redirect policy (`Langertha::HTTP::Redirect`) on both transports: same origin unchanged, cross-origin keeps only representation headers and strips chain credentials from the URL, GET/HEAD only, no https→http; default `user_agent` is `Langertha::HTTP::UserAgent`, injected clients keep their own (k374, amends 0027)
- **0037** — `connect_address` pins an engine's TCP connection to a caller-checked IP (DNS-rebinding defence); Host, SNI and the certificate check keep the host name; async `on_ready` / sync request-scoped `_extra_sock_opts` + `_check_sock` wraps verify every connection before writing; cross-host redirects and unpinnable setups refuse (k375, amends 0036)

Format + when-to-write: skill `langertha-adr`; backfill new ones via the `langertha-adr-auditor`
agent. `CONTEXT.md` is the domain language for the tools lane (canonical terms, not a decision
log) — ADRs link to it, they don't restate it.

## Build & test

Uses the `[@Author::GETTY]` Dist::Zilla plugin bundle.

```bash
dzil test                       # Build and test (recursive)
prove -lr t/                    # Run tests directly (recursive — see note)
prove -lv t/60_tool_calling.t   # Single test, verbose
```

**Verify recursively.** `prove -l t/` is NOT recursive and silently skips `t/` subdir tests.
Use `prove -lr t/` or `dzil test`. Live tests (the `t/8x` files gated in `BEGIN` — list in skill
`langertha-testing`) are gated on `TEST_LANGERTHA_<ENGINE>_API_KEY` (self-hosted ones on a server
URL) and skip without keys (and cost real money — be selective).
**TSystems is not live-testable** — no developer key is available to the project (the `.env`
key is empty and none is obtainable), so its wire behavior is **documentation-derived, not
live-verified**; treat `docs.llmhub.t-systems.net` as the source of truth for it
(→ ADR 0024 / karr #184).
Test framework: `Test2::Bundle::More`. `dzil release` is forbidden without explicit go-ahead
(house rules).

## OOP / Async / MCP / POD

- **Moose exclusively.** Every class ends with `__PACKAGE__->meta->make_immutable`. One
  documented exception: `Langertha::Moment` subclasses the XS `Time::Moment` (blessed SCALARs,
  constructors bless from inside XS) — do not "convert it to Moose". → **ADR 0017**.
- **`Future::AsyncAwait`** (>= 0.66) for all async methods; **IO::Async** event loop when
  `Net::Async::HTTP` is installed, else a blocking sync LWP fallback (IO::Async is `recommends`) → **ADR 0027**.
- **MCP**: any `Net::Async::MCP`-compatible client via `mcp_servers` (user-supplied, not a core
  dependency since ADR 0026), `MCP::Server` (tool definitions, `inputSchema` camelCase).
- **POD**: `@Author::GETTY` PodWeaver. `# ABSTRACT:` required on every `.pm`; inline `=attr`,
  `=method`, `=seealso`. Use the `langertha-pod-writer` agent for documentation.
- **Naming** (enforced by `.perlcriticrc` on every `dzil test`): packages are
  `CamelCase` (`vLLM` brand exempt), subroutines and variables are `snake_case`.
  Moose lifecycle methods (`BUILD`, `DEMOLISH`, `FOREIGNBUILDARGS`, …) and tied-method
  names are exempt. Ambiguous single-letter names (`$x`, `$obj`, …) are prohibited.
  Run `perlcritic --profile .perlcriticrc lib/ bin/ maint/` locally.

## Architecture

### Engine hierarchy (`lib/Langertha/Engine/`)

```
Engine::Remote              url required, JSON + HTTP
  │
  ├── Engine::AnthropicBase /v1/messages format, x-api-key auth, SSE streaming
  │     ├── Anthropic       Claude models, thinking blocks, tool_use
  │     ├── MiniMaxAnthropic MiniMax via legacy /anthropic shim endpoint
  │     ├── MoonshotAnthropic Moonshot Kimi via /anthropic shim endpoint
  │     ├── AKIAnthropic   AKI.IO via /anthropic shim endpoint, EU/Germany
  │     └── LMStudioAnthropic LM Studio Anthropic-compatible endpoint
  │
  ├── Engine::OpenAIBase    /chat/completions format, Bearer auth, SSE streaming
  │     │  Cloud providers (url has default, api_key from env)
  │     ├── OpenAI          gpt-5.6 family + gpt-6-astra flagship, embeddings, whisper transcription, structured output
  │     │     └── OpenAIResponses  /v1/responses API (reasoning models like gpt-5.5-pro); composes `Role::ResponsesCompatible` (`responses` tool/reasoning wire format — shared with Perplexity's Agent API) + `Role::ServerTools` (OpenAI hosted tools); no streaming
  │     ├── DeepSeek        deepseek-flash (V4.1) / v4-pro, structured output
  │     ├── Groq            ultra-fast inference, whisper transcription, structured output
  │     ├── XAI             xAI Grok (grok-4.7), 500K context, agentic tool calling, Imagine image generation
  │     ├── Mistral         EU-hosted, embeddings, Voxtral transcription, structured output
  │     ├── MiniMax         Shanghai (default), ~200K context, M3
  │     ├── Moonshot        Moonshot Kimi (kimi-k3), multimodal, 1M context
  │     ├── NousResearch    Hermes models, <tool_call> XML tool format
  │     ├── Cerebras        wafer-scale chips, fastest inference
  │     ├── OpenRouter      meta-provider, 300+ models, provider/model format
  │     ├── Replicate       thousands of open-source models, owner/model format
  │     ├── HuggingFace     Inference Providers, org/model format
  │     ├── AKIOpenAI       EU/Germany, GDPR-compliant
  │     ├── TSystems        T-Systems AIFS / LLM Hub, T-Cloud Germany + EU hyperscaler models
  │     ├── Scaleway        EU-hosted Generative APIs, drop-in OpenAI replacement
  │     ├── Hetzner         Hetzner Inference (DE, OpenAI-compatible, vision on multimodal models)
  │     │  Self-hosted (url required, no api_key)
  │     ├── OllamaOpenAI    Ollama /v1 endpoint, embeddings
  │     ├── vLLM            high-throughput inference, single-model server
  │     │     └── VLLMHook  vLLM + IBM vLLM-Hook plugin (attention/hidden-state/steering probes)
  │     ├── SGLang          SGLang OpenAI-compatible server, fast structured output, embeddings
  │     ├── LlamaCpp        llama.cpp server, embeddings
  │     └── LMStudioOpenAI  LM Studio's OpenAI-compatible endpoint
  │
  ├── Engine::TranscriptionBase  Transcription-only OpenAI-shape base (no chat/tools)
  │     └── Whisper         self-hosted faster-whisper-server etc.
  │
  │  Non-OpenAI formats (own request/response handling)
  ├── Perplexity            Agent API (/v1/agent), Open-Responses envelope via Role::ResponsesCompatible; search-augmented, citations; client function tools, no `tool_choice` (k213)
  ├── Gemini                ?key= auth, functionDeclarations, thought parts, embedContent embeddings
  ├── Ollama                native /api/chat, NDJSON streaming, OpenAPI spec
  ├── AKI                   key-in-body auth, EU/Germany, /api/call/{model}
  └── LMStudio              LM Studio native API (non-OpenAI/non-Anthropic)
```

- **LMStudio family** — `LMStudio` (native), `LMStudioOpenAI` (OpenAI-compatible),
  `LMStudioAnthropic` (Anthropic-compatible). Pick whichever the server serves.
- **AKI family** — three faces of the same service, all on `LANGERTHA_AKI_API_KEY`:
  `AKI` (official native API, changes often), `AKIOpenAI` (more stable OpenAI-compatible,
  sometimes lacks features), `AKIAnthropic` (`/anthropic` shim, `x-api-key`). All provided;
  no endorsement. Unknown-model handling differs per face: `AKIOpenAI` rejects an unknown ID
  loudly; `AKI` (native) errors on a gated/unknown endpoint (e.g. `Client not authorized for
  endpoint minimax_m3!`) rather than substituting; only the `AKIAnthropic` shim silently answers
  with a different model. Check `$response->model` / watch for errors when it matters which model
  replied.
- **Whisper / `->whisper`** — `Whisper` extends `TranscriptionBase` (transcription only, no
  chat/tools/embeddings). The `whisper` attribute on `OpenAI` returns a `TranscriptionBase`
  pre-configured with the parent's `api_key`/`url`.

### Roles — composition patterns

Dialect bases compose roles with the **`with map { 'Langertha::Role::'.$_ } qw(...)`**
pattern (not the simpler `with 'Langertha::Role::X'`). This is the `-excludes`
canon — the explicit list makes the *intentional* role set visible and resolves
collisions on `_build_*_wire_format` / `content_format` / `stream_format`
between overlapping roles. Dialect-specific subclasses override the colliding
defaults via `around engine_capabilities` (the ADR 0002 escape hatch) to
delete the inapplicable flag for their family. → **ADR 0015**.

### Roles (`lib/Langertha/Role/`)

- **Capabilities** — `engine_capabilities` registry + `supports($cap)`; flags derive from the
  composed role inventory (`%ROLE_TO_CAPS`), engines correct wire reality via
  `around engine_capabilities`. → **ADR 0002**.
- **Chat** — sync/async chat (`simple_chat`, `simple_chat_f`); `chat_f(messages, tools,
  tool_choice, response_format)` for single-turn structured calls (auto-rewrites per wire reality).
- **Tools** — MCP tool-calling loop (`chat_with_tools_f`, `mcp_servers`); thin tag-driven
  orchestration over the value objects. → **ADR 0001**.
- **HermesTools** — `<tool_call>` XML tag names + prompt template for the `hermes` wire format.
- **Streaming** — SSE / NDJSON streaming. **Embedding**, **Transcription**, **ImageGeneration**.
- **HTTP** (sync + async; backend selection in **AsyncHTTP**, ADR 0027) · **JSON** (`$self->json`) · **OpenAICompatible** ·
  **AnthropicCompatible** (`/v1/messages` envelope, parallel to `OpenAICompatible`) ·
  **ResponsesCompatible** (Open-Responses `/v1/responses` + `/v1/agent` envelope, shared by
  `OpenAIResponses` + `Perplexity` via divergence hooks — ADR 0020) ·
  **OpenAPI** (spec validation) · **ThinkTag** (`<think>` filtering) · **Langfuse** (observability).
- **Runtime::MetricsPoll** — async Prometheus `/metrics` scrape for self-hosted engines
  (vLLM, SGLang, llama.cpp). URL derived by stripping the trailing `/v1` from the engine's
  `url`; Ollama is intentionally not composed (its stats live at `/api/ps` in JSON).
  → **ADR 0014**.
- **ServerTools** — `server_tools` capability + per-engine default server-side tools, composed by
  `OpenAIResponses` (the `_server_tool_wire_check` hook carries provider divergence). → **ADR 0030**.
- **ImageInput** — `image_input` capability, model-scoped ("the model sees the image", not just
  "the wire carries it"); family defaults + allowlists per engine, gateways/self-hosted don't claim;
  never blocks; its one reader picks the tool-result image form on the `responses` / Gemini 3 /
  `anthropic` wires (image part vs text placeholder, k344, k359) and the PDF form on OpenAIResponses /
  Gemini 3 (k361). → **ADR 0019** (k266, k344, k359, k361 Updates).
- **SystemPrompt**, **Temperature**, **ResponseSize**, **ContextSize**, **Seed**,
  **ResponseFormat** (`decode_loose_json`), **Models**, **ParallelToolUse**.
- **ReasoningEffort** (`reasoning_effort`) · **PromptCache** (`prompt_cache` / `prompt_cache_key`)
  — request-side controls serialized per-wire by value objects, keyed by per-concern
  `reasoning_wire_format` / `cache_wire_format` (separate from `tool_wire_format`). → **ADR 0009**.

- **RuntimeKnobs** (`knob_wire_format` `vllm` | `sglang` | `llamacpp`) — self-hosted prefix-cache knobs
  (`prefix_cache_salt`, `cache_prompt`, `n_cache_reuse`, `id_slot`, …) via `Langertha::Runtime::Knobs`;
  composed by vLLM, SGLang, LlamaCpp. → **ADR 0012**.
- **CachedContent** — Gemini explicit `cachedContent` resource lifecycle (create/get/list/update/delete).
- **StaticModels** — hardcoded model list for engines without a usable `/models` endpoint
  (Perplexity, NousResearch, MiniMaxAnthropic, MoonshotAnthropic, AKIAnthropic). **KeepAlive** — Ollama native
  `keep_alive` (model residency duration).
- **PluginHost** (Chat, Embedder, ImageGen, Engine::Remote) · **Runnable** (dependency-free
  `run_f` execution contract, generic) — infrastructure roles, not capabilities. (The Raid
  orchestration nodes that consumed Runnable moved to langertha-raider.)

### Core classes

- **Langertha::Response** — LLM response (stringifies to content). `tool_calls` is
  `ArrayRef[Langertha::ToolCall]` — single source of truth, native + synthetic. → **ADR 0003**.
- **Langertha::Tool / ToolCall / ToolResult / ToolChoice** — canonical tool wire-translation
  value objects, dispatched by `tool_wire_format`. Definitions, calls, result blocks, and
  selection policy each own their per-format serializers. → **ADR 0001**, `CONTEXT.md`.
- **Langertha::ServerTool / ServerToolCall** — provider-native server-side tools (web search,
  remote MCP, …) pinned to one `tool_wire_format` (Phase 1: `responses`), and the record of a
  call the provider ran (`Response.server_tool_calls`). → **ADR 0030**.
- **Langertha::Reasoning / PromptCache** — request-side control value objects (reasoning effort,
  prompt caching); per-format serializers dispatched by `reasoning_wire_format` /
  `cache_wire_format`. → **ADR 0009**.
- **Langertha::Moment** — the instant a provider reports (`Response.created`); a `Time::Moment`
  subclass that numifies to the Unix epoch and stringifies to the full ISO-8601 stamp.
  `from_wire` is the lenient inbound door (never dies; an unreadable stamp drops the field).
  Deliberately **not** Moose — the one documented exception, asserted in
  `t/91_response_created.t`. → **ADR 0017**.
- **Langertha::Stream / Stream::Chunk** — streaming iteration; `Stream::Chunk` carries
  `tool_calls`, aggregated by `Role::Chat::aggregate_tool_calls`.
- **Langertha::Content::Image** — provider-agnostic vision input.
- **Langertha::Result** — reserved-namespace stub; the result value object moved to
  `Langertha::Raider::Result` in langertha-raider, the stub stays for CPAN index continuity.
- **Langertha::RunContext** — dependency-free structured execution context (input/state/branch/
  merge) for runnable nodes; a generic core primitive, decoupled from Raider.

### Tool & structured-output flow

`tool_wire_format` (`openai` | `anthropic` | `gemini` | `ollama` | `responses` | `hermes`) keys
all tool wire-translation through the value objects; `chat_f` auto-rewrites between
tools / `tool_choice` / `response_format` when the wire reality demands it (e.g. Perplexity →
`response_format=json_schema` + synthetic ToolCall; first-party Anthropic → native
`output_config.format`; the `/anthropic` shims → synth tool + forced choice). Every case lands as
a `Langertha::ToolCall` on `Response.tool_calls`. The full
decision matrix, the per-provider wire payloads, and the resolved vocabulary (Result envelope,
Assistant echo) live in **`CONTEXT.md`** and **ADRs 0001–0003, 0005** — read those before changing
the seam, and reconcile any drift (open karr tickets #1, #2).

## Raider (autonomous agent) → sibling distribution langertha-raider

The autonomous agent (`Langertha::Raider`, `Raider::Result`), the Raid orchestration layer
(`Langertha::Raid`, `Raid::Loop/Parallel/Sequential`) no longer ship in core; raider talks MCP
through `Net::Async::MCP` directly (the planned `Langertha::Raider::MCP` wrapper was never
built — ADR 0026 update). They live in **langertha-raider**
(`requires 'Langertha'`, never the reverse — same pattern as langertha-knarr/skeid).
`Langertha::RunContext` and `Langertha::Role::Runnable` (the run context + `run_f` contract those
nodes use) stay in core as dependency-free generic primitives. ADRs 0007/0008 record Raider
decisions and stay here as history.

Core keeps the seams they build on: `Role::Tools` / `chat_with_tools_f` (with a duck-typed
`mcp_servers` ArrayRef of any Net::Async::MCP-compatible client), `Role::PluginHost`,
`Langertha::Plugin`. `Langertha::Result` remains a reserved-namespace stub (its code moved to
`Langertha::Raider::Result`; `Langertha::MCP::Client` was never released, so it is simply gone). The lazy `use Langertha qw( Raider )` sugar in
`Langertha.pm` and the `->isa('Langertha::Raider')` check in `Plugin.pm` stay and light up once
langertha-raider is installed.

## Skills map

| Need | Skill |
|---|---|
| Engine creation, MCP, plugin pipeline (architecture); Raider usage (sibling dist langertha-raider) | `perl-ai-langertha` |
| Changing core: capability layers, wire-format tags, envelope roles, adding an engine | `langertha-internals` |
| Writing / reviewing tests: layers, fixtures, local HTTP daemon, live gating | `langertha-testing` |
| Moose patterns (attributes, roles, BUILD, immutability) | `getty-perl-moose` |
| Async (IO::Async, Future, Future::AsyncAwait lifecycle) | `perl-io-async-future` |
| dist.ini / `[@Author::GETTY]` bundle, POD conventions, next-version | `getty-perl-release-author-getty`, `perl-release-dist-ini` |
| Commit message conventions | `getty-git-commit-style` |
| Commit / push cadence, rebase vs merge, branch hygiene | `getty-git-usage` |
| ADR format + backfill method | `langertha-adr` |
| GitHub public issues (`gh`) guardrails | `langertha-github-issues` |
| karr board commands | `kanban-issues-karr-coordination` |

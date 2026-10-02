# ADR 0014 — Self-hosted engines expose runtime metrics via `Role::Runtime::MetricsPoll` (Prometheus `/metrics` scrape)

- Status: accepted
- Date: 2026-08-15
- Tags: engines, observability, runtime-metrics, self-hosted, role

## Context

Langertha ships a dozen self-hosted / OpenAI-compatible engines — `vLLM`,
`SGLang`, `LlamaCpp`, plus `LMStudioOpenAI`, `OllamaOpenAI` and friends. Three
of them (vLLM, SGLang, llama.cpp's built-in server) expose a Prometheus
`GET /metrics` endpoint at the server's HTTP root. This is a wire-reality
that fits *neither* the OpenAI chat-completions path nor the request-side
controls lane (ADR 0009) — it's a sidecar observability surface that needs
its own seam.

The patch that motivates this ADR landed in commit `a8f1c32`
(2026-08-12, "Compose Runtime::MetricsPoll onto self-hosted engines"). It
added:

1. `Langertha::Role::Runtime::MetricsPoll` — a Moose role that exposes
   `poll_metrics_f` (async, IO::Async) and a sync `poll_metrics` wrapper.
2. A `metrics_url` builder that derives the `/metrics` endpoint by stripping
   the trailing `/v1` (and any trailing slash) from the engine's `url`
   attribute — vLLM serves at `http://host:8000/metrics` for an engine
   `url => http://host:8000/v1`.
3. A private `IO::Async::Loop` + `Net::Async::HTTP` client lazy-attached to
   the engine instance (same pattern as `Langertha::Role::Chat`).
4. The `runtime_metrics` capability flag, registered in
   `Langertha::Role::Capabilities`'s `%ROLE_TO_CAPS` map.
5. Composition onto `Langertha::Engine::vLLM`, `Langertha::Engine::SGLang`,
   `Langertha::Engine::LlamaCpp`.
6. `Langertha::Runtime::Metrics` (Prometheus text-format parser) plus the
   per-engine wire contract at `Langertha::Runtime::Metrics::EngineContract`.

The behaviour is shipped and locked in by `t/49_runtime_metrics.t`. The
*shape decisions* are ADR-worthy and were not previously recorded.

## Decision

### 1. The role is a sidecar observability seam, not chat plumbing

`Runtime::MetricsPoll` is a separate role from `Langertha::Role::Chat`,
`Role::Tools`, etc. It does not extend or replace any chat-side role. It
deliberately rides on its own private `IO::Async::Loop` so it cannot deadlock
the chat-side loop when both paths are in flight.

It is composed alongside chat roles, not inside them — `vLLM.pm` does
`with 'Langertha::Role::Tools', 'Langertha::Role::Runtime::MetricsPoll';`
on top of the OpenAIBase chat plumbing. The role's `requires qw(json url)`
(`lib/Langertha/Role/Runtime/MetricsPoll.pm:12-15`) guarantees those
attributes are already present from the chat-side inheritance chain; no new
attribute plumbing on the engine is needed.

### 2. URL derivation is mechanical, not engine-specific

The endpoint convention — `GET /metrics` at the server root, *not* under
`/v1` — is consistent across vLLM, SGLang, and llama.cpp. So the URL
derivation lives in the role (`metrics_url`, line 62–74), not in each engine.
The derivation rule is: strip a trailing `/v1` (and any preceding slash) from
`$self->url->path`, then append `metrics`. Engines that need a different
URL override `metrics_url`.

This keeps the role small and uniform. An engine whose Prometheus endpoint
lives elsewhere (e.g. a future K8s sidecar pattern) overrides the method in
one place.

### 3. Ollama is *not* composed with this role, by design

Ollama's runtime stats live at `GET /api/ps` in JSON, not at `/metrics` in
Prometheus text. The Ollama-specific adapter is a separate piece of work
tracked alongside the wire contract
(`Langertha::Runtime::Metrics::EngineContract` and its companion karr ticket).
Forcing Ollama through this role would either fail (the URL is wrong) or
produce noise (re-purposing `/v1/../metrics`). The right answer is a
different observability seam, not a fit-and-trim here.

The role's POD (`lib/Langertha/Role/Runtime/MetricsPoll.pm:53-59`) calls
this out explicitly so the next person doesn't try to compose it onto
Ollama and "just add a different URL" — they will instead find the
intentional non-composition and either add a sibling role or fill out the
existing karr ticket.

### 4. No Bearer auth, by design

These are local servers. No `Authorization: Bearer …` header is sent by the
role. The role's POD (`lib/Langertha/Role/Runtime/MetricsPoll.pm:48-51`)
documents this and points at `Role::HTTP::generate_http_request` as the
extension point for deployments that sit behind auth (proxy or a custom
request builder).

### 5. `runtime_metrics` is a capability flag, not a chat-side knob

`%ROLE_TO_CAPS` registers `runtime_metrics => 1` from this role, so the
flag is observable via `$engine->supports('runtime_metrics')`. This is the
*only* entry in the registry that does not feed a chat-completions body
field — it advertises observability rather than generation behaviour. The
asymmetry is intentional: chat-side flags say "the wire accepts X", the
runtime flag says "the engine has a /metrics endpoint". A future
ADR-worthy restructuring might split the registry in two; for now, one map
is sufficient and the asymmetry is documented here.

## Rationale

The role sits at a different layer from the chat-completions plumbing —
chat roles compose onto `Langertha::Role::OpenAICompatible` or
`AnthropicCompatible` and route through `Role::HTTP`; the metrics role
routes through a private `Net::Async::HTTP` client against a known-static
URL. Trying to fold it into `Role::Chat` would have required either a new
branch in `chat_request` (wrong shape — it's not a request to the chat
endpoint) or a parallel call site in every consumer (wrong shape — the
*engine* should advertise the capability, not the consumer know).

Composing the role on a per-engine basis and advertising `runtime_metrics`
through the same `engine_capabilities` registry keeps the discoverability
symmetric: `$engine->supports('runtime_metrics')` works the same way as
`$engine->supports('streaming')`. The role's `requires` clause
guarantees the necessary attributes are present without each engine
re-declaring them, so composition stays one-line.

The "Ollama does not compose" decision is the kind of thing a future
reviewer would rightly question — "why doesn't Ollama just use the same
role?" — and that is exactly the question this ADR exists to short-circuit.
The answer is the wire contract: Ollama's stats endpoint speaks JSON at a
non-Prometheus path. Forcing it through the Prometheus role would either
silently break (wrong URL) or add a fork that would have to be carried
forever. The EngineContract POD is the right home for the per-engine
wire fact.

## Consequences

- **A new self-hosted engine with `/metrics`**: one-line `with` addition,
  register the engine in `Langertha::Runtime::Metrics::EngineContract`,
  add a parser fixture to `t/49_runtime_metrics.t`. No chat-side code change.
- **A self-hosted engine with non-Prometheus stats** (Ollama today, future
  TGI / Ray Serve LLM): write a sibling role, not a fork of this one. The
  seam is established here so adding siblings is mechanical.
- **Auth-behind-proxy deployments**: extend `generate_http_request` on the
  engine (no role change). The POD signposts this.
- **The capability registry holds an observability-shaped flag alongside
  chat-shaped flags.** If a future review finds the asymmetry confusing
  enough to split, the registry stays the single point of change (one
  role-to-caps map); the asymmetry would just be removed by extraction.
- **The `metrics_url` derivation rule is shared across the three
  Prometheus-speaking engines** — if a future engine ships `/metrics` under
  a different path (or with a port offset), it overrides `metrics_url` in
  one line. No churn in the role.

## Future work

- **Ollama stats adapter** (JSON `/api/ps` → Prometheus-shaped records) is
  tracked on the karr board alongside the EngineContract POD. When that
  lands, the decision here does not need revisiting — Ollama gets its own
  observability seam, not a fork of this one.
- **Capability registry split** (chat-shape vs observability-shape flags)
  is not currently warranted but is the natural follow-up if the registry
  grows past ~20 entries. Not blocking.
- **`Runtime::Metrics::EngineContract` coverage drift** — the contract
  currently lists the three composed engines. Adding a new Prometheus-
  speaking engine should add a contract entry; a follow-up karr ticket
  should codify the relationship between "composed role" and "contract
  entry" so neither side can drift silently.

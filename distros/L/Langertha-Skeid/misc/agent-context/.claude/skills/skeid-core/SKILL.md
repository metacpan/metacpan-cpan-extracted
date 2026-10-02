---
name: skeid-core
description: Load when working on the Langertha::Skeid control plane — node inventory, weighted routing, admission control, config reload, usage accounting, the admin API.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

`Langertha::Skeid` is the control plane; `Langertha::Skeid::Proxy` is the Mojolicious app on
top of it. Moo, no singletons. Terms below are defined in `CONTEXT.md` — use them exactly.

## Shape

```
Langertha::Skeid          nodes, routing, admission, config, pricing, usage, registry snapshot
  ::Proxy                 Mojolicious app: routes, auth, handlers, upstream I/O
  ::Proxy::RelayContent   upstream body always relayed as raw bytes (skeid #30)
  ::Protocol              shared translation helpers, OpenAI manifest face
  ::Protocol::Anthropic   /v1/messages <-> OpenAI (+ ::Stream)
  ::Protocol::Ollama      /api/chat, /api/generate <-> OpenAI (+ ::Stream)
  ::UsageStore            config normalization + backend factory
  ::UsageStore::JsonLog   append-only JSON events (recommended default)
  ::UsageStore::DBI       sqlite + postgresql
  ::CapacityProbe         timer-driven probes; ::Prometheus, ::Registry, ::Custom
  ::Registry              signed Skeid-to-Skeid snapshot: encode, sign, verify (ADR 0017)
  ::Secret                constant-time compare for keys, tokens, signatures
  ::KeyBroker             resolve($ref) contract; ::OpenBao implements it
```

## Node

A node is a plain hashref in `->nodes`:

```yaml
id: openai-main        # required, unique
url: https://…/v1      # required, base url without endpoint path
model: gpt-4o-mini     # empty/absent = matches any requested model
engine: openai         # Langertha engine id, normalized via normalize_engine_id
weight: 3              # round-robin weight, min 1, integer
max_conns: 8           # admission limit; <= 0 means unlimited
healthy: 1             # operator flag, never set by error handling
tags: [local, gb10]    # grouping for selection; also accepts "local, gb10"
api_key_ref: secret/…  # key reference resolved through the KeyBroker per request
api_key_env: VAR       # fallback: key from this environment variable
capacity: { probe: … } # optional capacity probe, see below
```

Mutating helpers: `add_node`, `remove_node`, `list_nodes`, `set_node_health`.

**Tags group nodes; ids never do.** `select_nodes(tags => [...])` returns nodes carrying *every*
listed tag (AND, not OR); no tags selects everything. Tags are lowercased, trimmed, de-duplicated
and order-preserving, and `normalize_tags` accepts either a list or a comma/space-separated
string because hand-written configs use both. Routing takes the same `tags` argument
(`pick_node`, `route_state`, `route.next`, `route.state`), and it is part of the route key —
two selections over one model must not share a round-robin cursor. This is the foundation the
tiers of ADR 0008 sit on.

**Derived lists are cached, and the invariant is silent when broken.** Which nodes a selection
matches, their order and their weights are computed once and reused until
`_inventory_generation` changes. Anything that touches the inventory must call
`_bump_inventory` — `add_node` and `set_node_health` do it explicitly (a health call that
changes nothing does not bump), and a `trigger` on the `nodes` attribute catches a direct
assignment. Miss one and routing keeps sending traffic to a node that was drained or removed,
with nothing in the logs. `t/24-node-tags.t` is the tripwire; it has been verified to fail when
the bump is removed. The cache and its round-robin cursors are bounded at 256 route keys per
generation, FIFO-evicted together (skeid #55), so client-chosen model names cannot grow them.

Note `pick_node` is protected twice — admission re-reads `healthy` from the live node — so a
stale cache shows up in `route_state`, not there. That matters because `has_eligible` is what
makes the proxy answer `503` instead of waiting for capacity and answering `429`.

## Aliases and tiers

A requested model resolves to an ordered **plan** of tiers, tried until one admits the request
(ADR 0008). A model with no alias resolves to a single implicit tier selecting on its own name
with the global wait — which is why an aliasless config routes exactly as it did before.

```yaml
aliases:
  house-model:
    tiers:
      - tags: [local]
        model: qwen3-32b            # the model the node is asked for
        wait_ms: 200                # wait this long for a local GPU before paying for cloud
      - tags: [cloud, groq]
        model: llama-3.3-70b-versatile
```

`wait_ms` defaults to **0**: writing tiers means "try here, then there", and waiting is opt-in.
A tier without `model` selects on the alias name itself. `tiers` may also be given as a bare
arrayref.

The two ways a tier fails are not the same, and the distinction is the whole design:

- **No eligible node** → skip to the next tier immediately. Waiting cannot conjure a node.
- **Eligible but none admitted** → wait out this tier's `wait_ms`, then fall through.
- Plan exhausted, no tier ever had an eligible node → `503 model_not_found`.
- Plan exhausted, some tier did → `429 rate_limit_error`.

**Requested vs served model.** Once aliases exist, the name the client used and the name the
node is asked for are different strings. The upstream body carries the served model; the usage
event carries `model` (served, what costs money) *and* `requested_model` (what the customer
bought). Dropping either breaks cost attribution silently. `requested_model` was added to the
schema after the fact, so `UsageStore::DBI` adds the column to a pre-existing table on
`prepare` — that is the entire migration story, and it never drops or rewrites a column.

## Per-key policy

Who is asking narrows what the plan may contain (ADR 0008). Resolved once at config load into
immutable policy objects; a request costs one hash lookup.

```yaml
policies:
  standard:  { deny_tags: [cloud] }        # our hardware only
  burstable: {}                            # cloud is fine when local is full
  trial:     { models: [house-model] }     # one product, anywhere
default_policy: standard
keys:
  k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b: burstable  # `skeid keyid <key>` prints the id
  k_9c8b7a6f5e4de5f60718293a4b5c6d7e8f901a2b: { policy: standard, deny_tags: [cloud, eu-outside] }
```

- A key entry is a profile name, or a hash with `policy` plus **sparse** overrides — an absent
  field keeps the profile's value.
- Unlisted keys take `default_policy`. Ten thousand identical customers are zero entries.
- A key id is `k_` + the key's full SHA-1 hex (ADR 0016). A legacy 12-hex id in `keys:` /
  `names:` still matches by prefix (`_configured_key_id`, warned once); a short id plus the
  full id it prefixes is a load error. Usage events keep their recorded id — no migration.
- Identical resolutions are interned, so keys on one profile share one object.
- Naming an undefined policy **croaks** at load. Failing open here would hand out access.

`route_plan` returns `{ tiers, permitted, reason }`. `permitted => 0` means either
`model_not_permitted` or `all_tiers_denied` — both are `403 permission_error`, never a
capacity code. Running out of *permitted* capacity stays `429`: falling through to a denied
node because everything else is full is the exact failure this design exists to prevent.

`deny_tags` filters **node selection**, not only the plan. An alias is a product name, not a
security boundary — without the node-level filter, a key denied `cloud` reaches a cloud node
by asking for its raw model name. `t/26-key-policies.t` proves both halves and was verified to
fail when either is removed.

**Identity is derived, never asserted.** The policy hangs off the customer key id, so that id
comes from the key the caller presented (`key_id_for_key`), not from `x-skeid-key-id` —
unless `routing.trust_key_id_header` says a gateway in front of Skeid authenticated the caller.

## Routing and admission — two steps, both can fail

`route.next` picks a node; `request.start` may still refuse it. That is not redundancy:
between the two, another request may have taken the last slot.

- **Eligible** = model matches (or node/request model empty) AND engine matches (or either
  empty) AND carries every selector tag AND no denied tag AND `healthy`.
- **Admitted** = `inflight < worker_max_conns` (or `max_conns <= 0`) **and** the node's capacity
  reading allows it, if there is a current one. See the probe section below.
- Weighted round-robin walks a per-route-key cursor (`model|engine`, plus tags and denied tags
  when present) over nodes sorted by id, skipping nodes that fail admission — each node is
  checked at most once per selection, whatever its weight (skeid #56). The cursor only advances
  on a successful pick.
- No eligible node → `503 model_not_found` immediately.
- Eligible but none admitted → wait `route_wait_timeout_ms` (poll `route_wait_poll_ms`), then
  `429 rate_limit_error`. Waiting is `Mojo::IOLoop->timer`, never `usleep`.

`inflight` is authoritative and paired: every `request.start` that returned ok MUST get a
`request.finish`, on every path including errors and upstream timeouts. A missed finish leaks
a slot until restart.

## Workers

`serve --workers N` runs `Mojo::Server::Prefork`; default 1, so nothing changes until asked
for. Measured: 170.7 req/s at 4 workers vs 128.1 at one, TTFT p50 88ms vs 120ms
(`docs/bench/2026-08-09-prefork-workers.md`).

**`inflight` and `max_conns` are per-process**, so each process takes
`max_conns / (frontend_count × N)` (`worker_max_conns`, floor 1; `routing.frontend_count` is the
number of Skeid hosts sharing the node, ADR 0012). Without that, `max_conns: 8` across 4 workers
permits 32 — silently. A `max_conns` below that process count cannot be honoured;
`worker_share_warnings` says so at startup rather than pretending. A shared scoreboard that would
replace the worker divisor is designed (ADR 0014) but not implemented.

Anything on a timer runs **once per worker**. Probe intervals are multiplied by the worker
count (`poll_interval_seconds`) so the node sees the configured rate from the group; a probe
whose scaled interval is not below `capacity_max_age_ms` warns at start. `frontend_count`
scales no timer. Vault renewal is deliberately *not* scaled — each process holds its own token
and must keep it alive.

Under prefork the usage store is multi-writer: `jsonlog` (dir mode) and `postgresql` are fine,
**SQLite is not**. Admin API writes reach one worker only, which makes the config file the
only workable source of truth (ADR 0010).

## Capacity probes

`inflight` counts what *this process* sent. Exact for one Skeid in front of one node, an
undercount the moment a second frontend, a prefork worker or a batch job shares it — every
counter sees its own share and together they over-admit. A probe reports what the node says
instead (ADR 0009).

```yaml
nodes:
  - id: gpu-1
    max_conns: 32
    capacity:
      probe: prometheus                 # inflight (default) | ratelimit | prometheus | registry | custom
      url: http://gpu-1:8000/metrics    # or path: /metrics, resolved against the node URL
      interval_ms: 2000
      running: vllm:num_requests_running    # optional; defaults cover vLLM/SGLang/TGI
      limit: 32                             # optional; falls back to max_conns
```

| probe | how | cost |
|---|---|---|
| `inflight` | the default; no probe object exists | none |
| `ratelimit` | `x-ratelimit-*` / `anthropic-ratelimit-*` / `Retry-After` read off responses the proxy already holds | none |
| | requests **and** tokens are read separately; the tightest quota (as a fraction) decides | |
| | read for every node; `probe: ratelimit` starts nothing | |
| `prometheus` | poll a metrics endpoint on a timer | one request per node per interval |
| `registry` | poll a downstream Skeid's signed snapshot (`secret_env`, `read_key_env` or `admin_key_env`; ADR 0017) | one request per node per interval |
| `custom` | a `code` callback or a `class` to load | caller's |

**The rule everything rests on: a probe may only narrow what `max_conns` allows, never widen
it.** `_node_can_take` asks both. A reading that could raise the ceiling would turn a stale
probe into an overload, and for a rented node `max_conns` is a spend limit.

- Readings expire after `capacity_max_age_ms` (5s). Every failure — unreachable endpoint,
  unrecognised metric names, a bad or stale snapshot, a probe that dies — forgets that probe's
  own reading and lets `inflight` decide. Never keep the last reading: unknown is imprecise,
  stale is confidently wrong.
- Two sources on one node: the tighter reading wins while it is current — it carries a pending
  backoff, or is younger than the longer of the two poll intervals (ADR 0017).
- `used` for Prometheus is `running + waiting`. A queued request occupies the node.
- A `429`/`Retry-After` sets a **backoff**, which outlives the age limit (it is a statement
  about the future) and **never touches `healthy`** — busy is not broken, and nothing would
  flip an error-driven flag back.
- Probing never happens on the request path. `ratelimit` is the exception that proves it: it
  reads a response already in hand and issues nothing.

Dispatch: `capacity.set`, `capacity.get`, `capacity.observe`, `capacity.forget`. Probes are
started by `build_app` and rebuilt when `_probe_inventory_key` moves (worker count plus id, URL
and `capacity` block of every probed node) — not on a health flip, which would forget every
reading (skeid #40).

## Function dispatch

`$skeid->call_function($name, \%args)` is the internal command surface. Every call first runs
`maybe_reload_config`, so config staleness is checked on the request path, not by a timer.

```
nodes.add nodes.remove nodes.list nodes.select nodes.set_health nodes.metrics
alias.set policy.set policy.for_key route.plan route.next route.state
request.start request.finish capacity.set capacity.get capacity.observe capacity.forget
usage.record usage.report usage.configure
pricing.set metrics.estimate_cost metrics.normalize
engines.list config.reload config.status
```

Unknown name croaks. Add a function here rather than reaching into the object from the app.

## Config

YAML, re-read when mtime changed (`maybe_reload_config`), or a `config_loader` coderef re-run
from dispatch at most once per `config_reload_interval` (default 1s). A load whose fingerprint
(the loader's optional second return value, else a canonical digest of the structure) matches
the last applied one is a no-op (skeid #38). A reload triggered from dispatch never dies
(skeid #39): the failure is logged and kept in `reload_status`, the request runs under the kept
config, a failing loader or broken file backs off (interval doubling from >=1s, capped at 60s;
skeid #54 — a new file mtime is read at once) and the same broken result is not applied twice.
Construction and explicit `config.reload` still die.

```yaml
nodes:      [ … ]                # replaces the whole inventory on reload
pricing:    { model: {…} }       # replaced wholesale; optional cached_input_per_million / cache_write_per_million
aliases:    { name: {tiers: […]} }   # replaced wholesale on reload
policies:   { name: {…} }        # with default_policy:, names: and keys:
routing:    { wait_timeout_ms: 2000, wait_poll_ms: 25, trust_key_id_header: false, frontend_count: 1 }
admin_api_key: "…"               # or admin_api_key_env:, or admin: { api_key | api_key_env }
usage_store: { backend: …, … }
manifest:   { enabled, public_url, … }   # provider manifest, per-key grants in keys: (ADR 0015)
registry:   { enabled, secret_env, read_key_env, … }   # publish a snapshot (ADR 0017)
```

The admin key is resolved on every applied config as explicit (`serve --admin-api-key`,
`build_app(admin_api_key)`, `new(admin_api_key)`, `set_admin_api_key`) > config (first of the
four spellings present; empty disables) > `SKEID_ADMIN_API_KEY` > off (skeid k64). Off means
`/skeid/*` answers 404, not 401 — absence of the feature, not a failed login.

A reload makes the running config equal to the file (skeid k65): a declared section replaces
what is loaded, a section the last applied config declared and this one drops goes back to its
default (`_config_declared` tracks which), a `routing` key likewise. A section no applied config
declared is left to the API that set it (admin-pushed nodes, `pricing.set`). The exception is
`usage_store`: a removal keeps the running store until restart and warns once — stopping
billing on a reload would be silent data loss (ADR 0004); a *changed* store swaps live.
Nodes are replaced wholesale when the `nodes:` section changes: anything pushed through the
admin API is lost then. That is deliberate — the file is the declared state. An unchanged
`nodes:` section keeps the list, its inventory generation (so probes keep running) and
admin-set health.

ENV defaults: `SKEID_ROUTE_WAIT_TIMEOUT_MS`, `SKEID_ROUTE_WAIT_POLL_MS`, `SKEID_USAGE_DB`,
`SKEID_ADMIN_API_KEY`, `SKEID_TRUST_KEY_ID_HEADER`, `SKEID_CAPACITY_MAX_AGE_MS`,
`SKEID_CONFIG_RELOAD_INTERVAL`, `SKEID_FRONTEND_COUNT`.

## Usage

One usage event per forwarded request, written after `request.finish`, including failures
(`ok = 0`). `record_usage` normalizes metrics, prices them from `model_pricing` at record
time, and hands the event to the configured store. Cache rates price the provider-verbatim
usage block through `Langertha::Usage`/`Pricing` into `cost_cache_read_usd` /
`cost_cache_write_usd` (part of `cost_total_usd`; ADR 0013 update). A stream keeps the
upstream's usage block verbatim (frames merged key by key, later wins — counts are running
totals, never summed) and prices it through the same `metrics.normalize` call as a
non-streamed answer, on every face (skeid #41).

Backend selection in `UsageStore->normalize_config` is inference-first: explicit `backend` wins,
otherwise `sqlite_path`/`path`/`db_path` → sqlite, `dbi:Pg:` dsn → postgresql, `log_path` →
jsonlog. `password_env` reads the password from the environment so it stays out of the file.
Schema is applied from `share/sql/usage_events.<backend>.sql` when `auto_migrate` (default on).

Override points, in order of preference: `usage_store` config → `store_usage_event` /
`query_usage_report` callbacks → subclass. `jsonlog` is the recommended default because it
never blocks the event loop on a database.

`usage_store.flush_interval_ms` (sqlite/postgresql only; ADR 0005 update, skeid k78): default
`0` = each event is written synchronously, as ever. `> 0` = write-behind: events are queued and
written by a timer every that many ms, in one transaction. The queue is also flushed on config
reload (store swap), on shutdown (`END` in `bin/skeid`), before a usage report, and by
`flush_usage`. The price is a loss window: a kill without flush (`SIGKILL`, OOM) loses the
queue, and billed requests with it. Under prefork `SIGTERM`/`SIGINT` make the manager
`SIGKILL` the workers and lose the queue; `SIGQUIT` (the Docker image's `STOPSIGNAL`) flushes.
A lost event is reported on `on_usage_lost`, never silent. `jsonlog` stays the recommendation;
it has nothing to amortise.

`node_metrics` is a *different* thing: volatile in-memory counters for ops, never billed.

## Admin API

`/skeid/*` under bearer auth against `admin_api_key` (constant-time, `Skeid::Secret`):
`GET /skeid/nodes`, `POST /skeid/nodes`, `POST /skeid/nodes/:id/health`,
`GET /skeid/metrics/nodes`, `GET /skeid/usage`, `GET /skeid/config` (`reload_status`: last
reload error, `failed_at`, `failures`). `GET /skeid/registry/snapshot` sits outside that block:
it takes the registry read key or the admin key and answers 404 unless `registry.enabled`.
Public `GET /health` carries `config_reload` without the message and stays `status: ok` while a
reload fails.

## Traps

- Adding a synchronous helper next to an async one. The handlers are async-only; a blocking
  call in a handler stalls every concurrent request. See the event-loop rule.
- Deriving health from errors. Health is operator state; see the flagged ambiguity in
  `CONTEXT.md` and write an ADR before changing it.
- Logging a resolved key. Only key *references* may appear in logs, config and usage events.
- Treating `429` and `503` as interchangeable. Saturation vs. no-such-model are different
  failures with different fixes. `403` is a third: not a capacity answer at all.
- Letting anything a client controls decide the customer key id. It selects both the routing
  policy and the invoice.

---
name: skeid-routing
description: Use when working on how Skeid chooses where a request may go — model aliases and tiers, per-key policies and deny_tags, prefork workers and per-process limits, capacity probes (prometheus, ratelimit, registry, custom).
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

Builds on `skeid-core` (nodes, eligibility, admission, `inflight` pairing). Terms are defined
in `CONTEXT.md`.

## Aliases and tiers

A requested model resolves to an ordered **plan** of tiers, tried until one admits the request
(ADR 0008). A model without alias is one implicit tier selecting on its own name with the global
wait — so an aliasless config routes exactly as before.

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

`wait_ms` defaults to **0** — tiers mean "try here, then there"; waiting is opt-in. A tier
without `model` selects on the alias name. `tiers` may be a bare arrayref.

The two ways a tier fails differ, and that is the whole design:

- **No eligible node** → next tier immediately. Waiting cannot conjure a node.
- **Eligible but none admitted** → wait this tier's `wait_ms`, then fall through.
- Plan exhausted, no tier ever had an eligible node → `503 model_not_found`.
- Plan exhausted, some tier did → `429 rate_limit_error`.

Requested vs served model diverge here: the upstream body carries the served model, the usage
event both (`model`, `requested_model` — skill `skeid-core`, Usage).

## Node kind and the routing key `documents`

A node's `kind` (`chat` default; `documents` = docling-serve, ADR 0028) is a selector axis beside
model, engine and tags. `route_plan(kind => …)` puts the kind on **every** tier, whatever an alias
says; `_route_entry` keeps only nodes of exactly that kind, and a documents selection ignores the
node's `model`. The kind is part of `_route_key`, so a chat model called `documents` and the
documents route never share a cursor. A chat selection no longer takes a node with an empty
`model` of another kind — the invariant the separation rests on (`t/88`, "kind keeps chat and
documents nodes apart").

The documents routes have no model name: they are planned and authorised under the fixed **routing
key** `documents` (`Protocol::Documents->routing_key`). It goes through the same policy check as a
model: `models: [qwen, documents]` grants it, a key whose `models` list leaves it out gets `403`
before a node is picked, `deny_tags` apply, an alias named `documents` tiers the nodes by tags.
The alias is excluded from `list_models`, documents nodes list no model, `_manifest_model_reachable`
selects `kind => ''`. A new kind is a row in `Protocol::Documents`'s `%KIND`, not a branch.

## Per-key policy

Who asks narrows what the plan may contain (ADR 0008). Resolved once at config load into
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

- A key entry is a profile name, or a hash with `policy` plus **sparse** overrides (an absent
  field keeps the profile's value). Unlisted keys take `default_policy` — ten thousand identical
  customers are zero entries.
- Key id = `k_` + the key's full SHA-1 hex (ADR 0016). A legacy 12-hex id in `keys:` / `names:`
  still matches by prefix (`_configured_key_id`, warned once); a short id plus the full id it
  prefixes is a load error. Usage events keep their recorded id — no migration.
- Identical resolutions are interned: keys on one profile share one object.
- Naming an undefined policy **croaks** at load. Failing open would hand out access.
- `route_plan` returns `{ tiers, permitted, reason }`. `permitted => 0` (`model_not_permitted`
  or `all_tiers_denied`) is `403 permission_error`, never a capacity code. Running out of
  *permitted* capacity stays `429` — falling through to a denied node because everything else is
  full is the exact failure this design prevents.
- `deny_tags` filters **node selection**, not only the plan. An alias is a product name, not a
  security boundary: without the node filter a key denied `cloud` reaches a cloud node by asking
  for its raw model name. `t/26-key-policies.t` proves both halves (verified to fail when either
  is removed).
- **Identity is derived, never asserted.** The policy hangs off the customer key id, which comes
  from the presented key (`key_id_for_key`), not from `x-skeid-key-id` — unless
  `routing.trust_key_id_header` says a gateway in front authenticated the caller.

## Customer source

Customer key ids, names and policies from a database view (ADR 0026,
`Langertha::Skeid::CustomerSource`, fetcher `::CustomerSource::DBI`). The section is
`customer_source: { backend: postgresql, dsn | host / port / dbname, user, password_env,
from_usage_store, relation, refresh_interval_s, listen, max_stale_s, connect_timeout_s }` —
`from_usage_store: true` takes the usage store's PostgreSQL connection instead of a `dsn`, the
password always comes from `password_env`. The relation gives
`key_id, name, policy, models` per active key. The rule everything rests on: **the database is
never on the request path, and its connect never runs in the loop's process.** The fetcher polls
on `Mojo::IOLoop` every `refresh_interval_s`; each fetch is a `Mojo::IOLoop->subprocess` that
connects with blocking DBI, runs the one statement and returns the rows (k109); with `listen` a
second child waits for `NOTIFY` (+ 250 ms debounce). Back-off like `_reload_retry_delay`;
`connect_timeout_s` bounds each fetch (libpq `connect_timeout`, `statement_timeout`, and the
parent kills an overrunning child). The **source snapshot** is the last good fetch; a changed
digest calls `reload_config` from the fetch callback, an unchanged one does nothing. The
fingerprint is the file's + `;customer_source:<digest>`, so `maybe_reload_config` still only
reads the file and merges whatever snapshot is in memory.

- Merge happens first in `_apply_config` (`merge_into`): rows are checked (`check_rows` — full id
  only, duplicates reject both, policy must exist in the file, models a list of names), the file
  wins per id (`keys:` directly, via `names:`, short-id prefix → shadowed), the rest become
  `keys:` entries. Accepted ids are added to `client_auth_keys` **after** `_load_client_auth`
  and only when the file declares `client_auth` — a union. No row can make a reload die;
  rejected rows are reported by name or position, never by value (a key may be pasted there).
- Fail-closed: no snapshot (startup failure) or a stale one (`max_stale_s`) merges nothing.
  A failing fetch keeps the last good snapshot. A removed section drops it; a changed one
  restarts the fetcher and keeps the snapshot until the new source answered.
- `build_app` calls `start_customer_source`; `skeid serve` runs `customer_source_startup_fetch`
  (bounded, before listening) and `customer_source_release` before prefork forks (kills the
  children). Tests inject `customer_source_fetcher => sub { $fake }`; `t/83`–`t/87`. `t/87`
  runs the real DBI fetcher on SQLite and against a listener that never answers.
- Not verified offline: the LISTEN child and a real PostgreSQL (`text[]` for `models`) — the
  manual procedure sits in `examples/service/skeid.yaml`.

## Workers

`serve --workers N` runs `Mojo::Server::Prefork`; default 1. Measured 170.7 req/s at 4 workers vs
128.1 at one, TTFT p50 88ms vs 120ms (`docs/bench/2026-08-09-prefork-workers.md`).

- **`inflight` and `max_conns` are per-process**: each process takes
  `max_conns / (frontend_count × N)` (`worker_max_conns`, floor 1; `routing.frontend_count` =
  Skeid hosts sharing the node, ADR 0012). Without it `max_conns: 8` over 4 workers permits 32,
  silently. A `max_conns` below the process count cannot be honoured; `worker_share_warnings`
  says so at startup. A shared scoreboard replacing the divisor is designed (ADR 0014), not built.
- Anything on a timer runs **once per worker**. Probe intervals are multiplied by the worker
  count (`poll_interval_seconds`) so the node sees the configured rate from the group; a probe
  whose scaled interval is not below `capacity_max_age_ms` warns at start. `frontend_count`
  scales no timer. Vault renewal is deliberately *not* scaled — each process keeps its own token.
- Under prefork the usage store is multi-writer: `jsonlog` (dir mode) and `postgresql` are fine,
  **SQLite is not**. Admin API writes reach one worker only, so the config file is the only
  workable source of truth (ADR 0010).

## Capacity probes

`inflight` counts what *this process* sent: exact for one Skeid in front of one node, an
undercount once a second frontend, a prefork worker or a batch job shares it — together they
over-admit. A probe reports what the node says instead (ADR 0009).

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
| `inflight` | default; no probe object exists | none |
| `ratelimit` | `x-ratelimit-*` / `anthropic-ratelimit-*` / `Retry-After` off responses already held; requests **and** tokens read separately, tightest quota (as a fraction) decides; read for every node, `probe: ratelimit` starts nothing | none |
| `prometheus` | poll a metrics endpoint on a timer | one request per node per interval |
| `registry` | poll a downstream Skeid's signed snapshot (`secret_env`, `read_key_env` or `admin_key_env`; ADR 0017) | one request per node per interval |
| `custom` | a `code` callback or a `class` to load | caller's |

**A probe may only narrow what `max_conns` allows, never widen it.** `_node_can_take` asks both.
A reading that could raise the ceiling turns a stale probe into an overload, and for a rented
node `max_conns` is a spend limit.

- Readings expire after `capacity_max_age_ms` (5s). Every failure — unreachable endpoint,
  unrecognised metric names, bad or stale snapshot, a dying probe — forgets that probe's reading
  and lets `inflight` decide. Never keep the last reading: unknown is imprecise, stale is
  confidently wrong.
- Two sources on one node: the tighter reading wins while current — it carries a pending backoff,
  or is younger than the longer of the two poll intervals (ADR 0017).
- Prometheus `used` = `running + waiting`. A queued request occupies the node.
- A `429`/`Retry-After` sets a **backoff**: it outlives the age limit (a statement about the
  future) and **never touches `healthy`** — busy is not broken, and nothing would flip an
  error-driven flag back.
- Probing never happens on the request path; `ratelimit` reads a response already in hand.
- Dispatch: `capacity.set`, `capacity.get`, `capacity.observe`, `capacity.forget`. Probes are
  started by `build_app` and rebuilt when `_probe_inventory_key` moves (worker count plus id, URL
  and `capacity` block of every probed node) — not on a health flip, which would forget every
  reading (skeid #40).

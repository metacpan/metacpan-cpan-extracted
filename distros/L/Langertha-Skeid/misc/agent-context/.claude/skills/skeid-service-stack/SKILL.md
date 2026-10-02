---
name: skeid-service-stack
description: Use when deploying Skeid — the OpenBao KeyBroker and AppRole token lifecycle, the docker compose stack, the ENV surface, customer keys, the usage schema.
user-invocable: false
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
---

How Skeid runs in production and what the example stack under `examples/service/` actually
does. Vocabulary (**Key broker**, **Key reference**, **Customer key ID**, **AppRole token
lifecycle**) is in `CONTEXT.md`.

## The security model in one paragraph

The container boots with an AppRole `role_id` + `secret_id` in its environment, logs into
OpenBao, keeps the resulting token **in memory only**, and renews it on a timer. Provider keys
are read from OpenBao when a node needs one, cached in memory only, and never persisted.
Customer keys are never looked up at all: a caller's identity is the digest of the key it
presented (`skeid keyid`). If renewal fails the
process dies and the orchestrator restarts it, which forces a fresh login. Nothing here is an
optimisation target: a disk cache of the token, a key written to a config file, or a "reuse
the old token if renewal fails" fallback each destroy the property the design exists for.

## KeyBroker::OpenBao

Two clients on purpose: `Mojo::UserAgent` for the request path, `HTTP::Tiny` for boot and for
callers with no IO loop (CLI, tests, setup scripts).

| Method | Does |
|---|---|
| `BUILD` | AppRole login → stores the returned token |
| `needs_refresh` | true within 60s of expiry, or when no client token exists yet |
| `refresh` | `auth/token/renew-self` → new client token + new expiry; **dies** on failure |
| `resolve_key($ref)` | blocking: refresh-if-needed, then KV-v2 read; returns `data.data.api_key` |
| `resolve_key_async($ref, $cb)` | the same, non-blocking; falls back to the blocking path with no IO loop running |
| `start_renewal` | renews on a timer instead of when a request notices; called by `build_app` |
| `list_secrets($path)` | `LIST` under a path; returns key names |

**The request path calls `key_async` and nothing else** — that is the base class's entry point
(see below), and `resolve_key` from a handler blocks every other in-flight request for a whole
vault round-trip. `t/27-keybroker-nonblocking.t` fails if that ever comes back.

`verify_ssl` defaults to **1**. `OPENBAO_VERIFY_SSL=0` exists for a dev vault with a
self-signed certificate; on a real `https://` address it hands the AppRole token to anyone who
can intercept the connection.

Path handling: a **Key reference** is written in logical form (`secret/skeid/remote/groq`) and
rewritten to the KV-v2 API path (`secret/data/skeid/remote/groq`) on read. Config, tickets and
logs use the logical form. A failed read logs the reference and the HTTP status — never the
response body, which may carry what was being read.

Auto-wiring: `Proxy->build_app` constructs the broker when `OPENBAO_ROLE_ID` and
`OPENBAO_SECRET_ID` are both set, then starts its renewal timer. A failure there warns and
leaves Skeid running without a broker — a node with `api_key_ref` then needs a set
`api_key_env`, or every request routed to it is refused with `503 upstream_key_unavailable`.
It never falls back to the client's key; pass-through is only for a node that names no key
source.

## KeyBroker base class — what every broker gets

A subclass implements `resolve_key` (blocking, one reference, dies or returns undef when it
cannot). Everything else lives in `Langertha::Skeid::KeyBroker`:

| Method | Does |
|---|---|
| `key_async($ref, $cb)` | **the request path's entry point**: cache, coalescing, then `resolve_key_async` |
| `resolve_key_async` | default implementation calls the blocking `resolve_key`; override to do better |
| `cached_key($ref)` | the live cache entry, distinguishing "cached failure" from "not cached" |
| `forget_key([$ref])` | drop one or all — what a key rotation calls |

`cache_ttl` 300s, `negative_cache_ttl` 5s (a vault outage must not become a round-trip per
request), and concurrent misses for one reference collapse into a single resolution — without
that, a cold start at concurrency 64 is 64 identical vault calls. A memory cache is explicitly
allowed by ADR 0003; a disk cache is not, at any TTL, for any reason.

## Compose stack

`examples/service/docker-compose.yml` — three services plus a one-shot init:

| Service | Host port | Purpose |
|---|---|---|
| `openbao` | 5501 → 8200 | dev-mode vault: **in memory**, root token `BAO_DEV_ROOT_TOKEN_ID` |
| `postgres` | 5533 → 5432 | usage store |
| `skeid` | 5591 → 8090 | the proxy, `${SKEID_IMAGE:-raudssus/langertha-skeid:latest}` |
| `skeid-init` | — | `profiles: [init]`, runs `init-skeid.sh` once in the **openbao** image |

```bash
cd examples/service && cp .env.example .env   # set SKEID_GROQ_KEY
docker compose up -d openbao postgres
docker compose run --rm skeid-init            # prints OPENBAO_ROLE_ID / OPENBAO_SECRET_ID -> .env
docker compose up -d skeid
docker compose logs -f skeid
```

`init-skeid.sh` (POSIX sh, `bao` CLI, root token as `BAO_TOKEN`): writes the `skeid-keys` policy
(`read` on `secret/data/skeid/*`, `list` on `secret/metadata/skeid/*` — KV v2 paths; a policy on
the logical `secret/skeid/*` would deny every read), enables `approle`, creates role
`skeid-service`, stores `SKEID_GROQ_KEY` / `SKEID_OPENAI_KEY` / `SKEID_ANTHROPIC_KEY` at
`secret/skeid/remote/<provider>` when set (value on stdin, `api_key=-`), and prints `role_id` +
`secret_id`. It needs nothing from the Skeid image, whose `perl:*-slim` base has no PostgreSQL
client and promises no `curl` — which is also why the `skeid` healthcheck is a
`perl -MHTTP::Tiny` one-liner. It creates no table and stores no customer keys: Skeid never
looks a customer key up, and `names:`/`keys:` in `skeid.yaml` hold ids from `skeid keyid`.

Dev mode forgets everything on restart: after the `openbao` container restarts, run
`skeid-init` again and replace both ids in `.env`. The role's `secret_id` has no use limit and
no TTL, so a Skeid restart after `token_max_ttl` (24h) logs in again with the same one.

The printed `role_id`/`secret_id` go into a **local, untracked** `.env`; only `.env.example`
may be committed — `git ls-files examples/service/.env` must print nothing (ADR 0003). The dev
root token and the Postgres password (`POSTGRES_PASSWORD`, also handed to Skeid as
`SKEID_USAGE_DB_PASSWORD`) are placeholders — a real deployment overrides both and does not run
OpenBao in dev mode.

## ENV surface

| Variable | Used by | Meaning |
|---|---|---|
| `OPENBAO_ADDR` | broker | default `http://127.0.0.1:8200` |
| `OPENBAO_ROLE_ID` / `OPENBAO_SECRET_ID` | broker | AppRole credentials; both present ⇒ broker is wired |
| `OPENBAO_VERIFY_SSL` | broker | `0` disables TLS verification — dev vault only |
| `SKEID_ADMIN_API_KEY` | control plane | bearer token for `/skeid/*` |
| `SKEID_USAGE_DB` | control plane | sqlite path, used only when the config has no `usage_store` |
| `SKEID_USAGE_DB_PASSWORD` | example stack | what its `usage_store.password_env` names |
| `SKEID_ROUTE_WAIT_TIMEOUT_MS` / `SKEID_ROUTE_WAIT_POLL_MS` | routing | saturation wait defaults |
| `SKEID_FRONTEND_COUNT` | routing | Skeid hosts sharing the nodes (ADR 0012), default 1 |
| `SKEID_CAPACITY_MAX_AGE_MS` | admission | capacity reading lifetime, default 5000 |
| `SKEID_CONFIG_RELOAD_INTERVAL` | control plane | `config_loader` re-run interval in seconds, default 1 |
| `SKEID_TRUST_KEY_ID_HEADER` | proxy | believe the client's `x-skeid-key-id` — only behind an authenticating gateway |
| `SKEID_UPSTREAM_POOL` | proxy | upstream connection pool size (default 100) |
| `SKEID_UPSTREAM_TIMEOUT` | proxy | seconds an upstream request may take and be silent for (default 300); the client connection of a proxied request gets the same on top of the server's inactivity timeout |

Secrets the config needs are named, never written: a node's `api_key_env`,
`admin.api_key_env`, a usage store's `password_env`, and the registry's `secret_env` /
`read_key_env`.

**Precedence:** a value in the config wins over its ENV default. The admin key is resolved on
every reload as `serve --admin-api-key` > the config's key (any of its four spellings; set empty
it disables `/skeid/*`, 404) > `SKEID_ADMIN_API_KEY` > off (skeid k64).

## Node config with keys

```yaml
nodes:
  - id: groq-main
    url: https://api.groq.com/openai/v1
    model: llama-3.3-70b-versatile
    engine: openai
    api_key_ref: secret/skeid/remote/groq   # KeyBroker (preferred)
  - id: local-vllm
    url: http://vllm:8000/v1
    model: qwen2.5-7b
    engine: vllm
    api_key_env: VLLM_TOKEN                 # fallback when there is no broker
```

## Usage schema

`share/sql/usage_events.postgresql.sql` and `usage_events.sqlite.sql` are the shipped schemas
and the only ones. `auto_migrate` (default on) applies the shipped file on `prepare` — when the
config is applied, so at start — and adds any column an older table is missing; the example
stack relies on that and carries no schema of its own. Reports: `bin/skeid usage --json`, or
`GET /skeid/usage`.

`usage_store.flush_interval_ms` (sqlite/postgresql only, default `0` = synchronous write) turns
on write-behind: events queue in memory and are written every that many ms, and on reload,
shutdown, report and `flush_usage`. A kill without flush loses the queue. Prefork stopped with
`SIGTERM` loses it too (the manager `SIGKILL`s its workers); `SIGQUIT` flushes, which is why the
image sets `STOPSIGNAL SIGQUIT` and the compose stack must not override it. `docker stop`
`SIGKILL`s after its grace period (10 s default): set `stop_grace_period` when streams run
longer. `jsonlog` remains the recommended default.

## Docker image

Built and pushed by `dzil release` via `run_after_release` (see the release rule — never run
that yourself). Tags: `raudssus/langertha-skeid:<version>`, `:<major>`, `:latest`. Source
overrides for an unreleased Langertha go through `SKEID_DOCKER_BUILD_ARGS`
(`--build-arg LANGERTHA_SRC=…`, a CPAN author path or tarball URL), documented at the top of
`dist.ini`. For a local test image:
`docker build -t raudssus/langertha-skeid:test .`, then `SKEID_IMAGE=raudssus/langertha-skeid:test`
in `examples/service/.env` to run the compose stack on it.

Two stages: `build` has `build-essential` and `libpq-dev` and runs `cpm` with
`--top-level-relationship requires,recommends`, so `DBI`, `DBD::Pg` and `DBD::SQLite` come
from the `cpanfile` and nowhere else; the final stage takes `site_perl` and `/opt/skeid` from
it and adds only `libpq5` and `jq`. What the `perl:*-slim` base brings stays (`make`,
`libssl-dev`, `zlib1g-dev`, no compiler). The final stage is the default target, so
`docker build` needs no `--target`. A module with XS that links a new shared library needs
that library in the final stage too — the `perl -M…` line there fails the build when one is
missing.

The process runs as `skeid`, uid and gid 10001 (`USER` is numeric so an orchestrator can verify
non-root). It owns `/var/log/skeid/events` (jsonlog) and `/var/lib/skeid` (sqlite) and nothing
else; `/opt/skeid` is root's and read-only to it. A named volume mounted on either directory
takes that ownership, a bind mount keeps the host's — the directory must be writable, and a
mounted `skeid.yaml` readable, for uid 10001. The compose stack writes nothing locally (usage
goes to PostgreSQL) and mounts its config `:ro`.

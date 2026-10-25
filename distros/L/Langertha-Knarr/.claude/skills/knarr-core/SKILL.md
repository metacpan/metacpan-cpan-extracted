---
name: knarr-core
description: "Use when working inside the Langertha-Knarr distribution — the two roads every request takes (raw passthrough vs. routed), the handler chain and its decorators, the six client protocols and their paths, the auth phases, the Moose/Moo module split, the config surface, the test layout and the release wiring. Knarr is the LLM proxy; the caller guide for core is perl-ai-langertha."
---

# Knarr core — the invariants behind the proxy

Knarr is an LLM proxy: it accepts requests in **OpenAI, Anthropic, Ollama, A2A, ACP or
AG-UI** format, routes them to any **Langertha** backend engine, and traces them via
**Langfuse** when Langfuse keys are set. It `requires 'Langertha'` — never the other way
round; core does not know Knarr exists.

This skill is the map and the invariants. The module-by-module list, the full config
example and the CLI reference live in `CLAUDE.md`; the config keys themselves are documented
per attribute in `Config.pm`'s POD, with an annotated example in `share/example-config.yaml`.

## Every request takes exactly one of two roads

The decision happens **before any body parse**, and it is the most important invariant in the
repo:

- **Routed** — the model is configured (or discoverable), so the request is normalized into
  a `Langertha::Knarr::Request`, handled by the engine, and answered as a `Response` or a
  `Stream`. Protocol translation lives here and only here.
- **Raw passthrough** — the model is unknown to the routing table and its protocol declares
  a `passthrough:` upstream, so **all HTTP bytes go 1:1 to the upstream** with the client's
  own headers and key. Traced, but not request-logged.

Everything else is decoration on those two roads. A change that touches both at once is a
change that needs the routing rules read first.

### The passthrough is bytes, not messages

Passthrough exists to preserve what a re-serialization would destroy: `tool_use`, `usage`,
`cache_control`, SSE framing. A "cleanup" that parses and re-serializes on that path looks
harmless and passes the fake-backed tests — but it silently strips real-provider metadata,
and the fake upstream never notices. **Translation belongs in `Protocol::*` on the routed
path only.**

On the way out, Knarr's own `proxy_api_key` is removed from `Authorization` / `x-api-key`
element by element (`Knarr::_without_proxy_key`, every forwarding path); a header left empty
is dropped. Ollama `/api/generate` goes to the upstream's `/api/generate`. `passthrough: true`
means OpenAI + Anthropic only — Ollama needs an explicit URL, and A2A / ACP / AG-UI never
pass through.

### How a model gets onto the passthrough road

`auto_discover` feeds the model lists. A model known only from discovery goes raw
passthrough when the client protocol's upstream is the endpoint that listed it (same
scheme/host/port/path, a trailing `/v1` ignored) **and** the request still carries a
provider key once the proxy key is stripped. Otherwise it is routed. If that raw
passthrough gets a **401** from the upstream (a placeholder key), the status is inspected
before any byte reaches the client and the request is answered through the handler chain
instead — one upstream call, one trace, with the metadata `passthrough_fallback: 401`. Other
statuses and unknown models' 401s pass through. Models listed under `models:` are always
routed.

## The handler chain and its decorators

```
[RequestLog] → [Tracing] → Handler::Router → Handler::Engine | Handler::Raider | …
```

`Tracing` and `RequestLog` are **decorators**: they wrap any handler and are composed
*around* it, so "the handler" is never a single class. A new handler is not automatically
traced or logged — decide where it sits in the chain. `Handler::Code` takes a coderef and
exists for tests and fakes.

The router resolves the model to an engine (`Handler::Router`), with `Handler::Passthrough`
for the raw road, `Handler::TokenRoutes` for token-auth routing by the token's provider, and
`Handler::Engine` / `Handler::Raider` for the actual call.

## The protocols and their paths

| Protocol | Paths |
|---|---|
| OpenAI | `/v1/chat/completions`, `/v1/models` |
| Anthropic | `/v1/messages` |
| Ollama | `/api/chat`, `/api/generate`, `/api/tags`, `/api/version`, `/api/show` |
| A2A | `GET /.well-known/agent.json`, `POST /` (Google Agent2Agent JSON-RPC) |
| ACP | `GET /agents`, `POST /runs` (BeeAI / Linux Foundation ACP) |
| AG-UI | `POST /awp` (CopilotKit) |

**The error shape is the protocol's.** Every error Knarr answers itself (401, 404, 500,
502–504) goes through `Knarr::_error_answer` → the protocol's `format_error_response`; with
no protocol (unknown path, manifest) it is `{"error":{"message"}}`. A routed stream sends its
200 with its first chunk — a failure before that is a status, not a 200.

## Auth runs in two phases

`Knarr->authorizer` is a Moose role with `identify_f` / `identify` (401 / 503) and
`authorize` (403). `identify_f` runs **after the route match, before the not-configured
check and before any body parse**, so an unauthenticated client learns no 400, no 404 and no
model name. `authorize` runs once action and model are known. Model lists go through
`visible_models`.

The default is `Authorizer::StaticKey` (the proxy key). Under `token_auth:` the
`Authorizer::Token` runs against a `TokenStore` (`::Pg`, `::Memory` for tests): the Bearer
token is hashed, compared against the view's hash column, and the model must match
(`match_model`). Unknown or expired → 401, wrong model → 403, store down → 503 — the whole
thing **fails closed**. The hit cache is dropped on the `NOTIFY` channel and on connection
loss. The identity rides on `Request->grant` (model, provider, expiry) — never the token and
never its hash.

`token_auth` is exclusive: it excludes `proxy_api_key`, `models`, `default`, `passthrough`,
`auto_discover` and `remote_config`, and under it there is no raw passthrough, no key is
forwarded, and the manifest is 403.

## The Moose / Moo split is the house pattern, not a free choice

- **Moose** — the server, the Handler and Protocol roles and all their implementors,
  `Role::UpstreamHTTP`, and the value objects `Request`, `Response`, `Session`, `Stream`,
  `Manifest`, `PSGI`, `Reasoning`, `PassthroughUsage`, `Stack`, `Admin`, the `Authorizer`
  role with `Authorizer::*` and the `TokenStore` role with `TokenStore::*`.
- **Moo** — `CLI`, `Config`, `Router`, `Tracing`, `RequestLog`. The CLI is `MooX::Cmd` +
  `MooX::Options`, and its side of the house is deliberately lightweight.
- **Plain** — `Image` only.

A new module picks its framework from the area it lives in. Do not "modernize" the split in
either direction.

## Configuration and environment

The reference is `Config.pm`'s POD (one `=attr` per key, each with its env var); the
annotated example is `share/example-config.yaml`. `Config` validates at start: `listen`
defaults to two local ports, `passthrough` is off unless configured, `auto_discover` is off
by default (on under `--from-env` and in `knarr init`).

The environment is namespaced `KNARR_*` (`KNARR_API_KEY`, `KNARR_ADMIN_KEY`,
`KNARR_REMOTE_CONFIG`, `KNARR_WORKERS`, `KNARR_LANGFUSE_*`, `KNARR_UPSTREAM_TIMEOUT`, …);
provider keys for `--from-env` and `knarr init` come from `Config.pm`'s `@ENGINE_DEFS` with
the precedence `LANGERTHA_*` > bare > `TEST_LANGERTHA_*`.

`remote_config` starts the proxy **without models**: every other route answers 503 until a
`PUT /knarr/admin/config` arrives. The admin push is a runtime layer over the start config,
validated and applied in one step — invalid input changes nothing.

## The test layout

`t/` is numbered by area: `00` load, `10` config and protocols, `20` handlers and router,
`25`–`34` request fields, `30`/`31` all-protocols and control params, `40`–`47` streaming,
`50` translator, `60`/`65` PSGI and manifest, `70`–`74` passthrough and tracing,
`75`–`79` the CLI, `80`–`99` the long tail, `100`–`122` admin, auth and token store.
`t/scenarios/*.yml` are the scenario fixtures the protocol tests replay; `t/lib/Test/` holds
the test helpers.

**The `*_live.t` tests need no API keys**: they start a real server on a local port with
`Handler::Code` fakes. Keep them key-free — nothing in `t/` may hit an external service.
The exception is the PostgreSQL live tests (`114_token_store_pg_live.t`,
`120_token_auth_pg_live.t`): they need `KNARR_TEST_PG_DSN`, `KNARR_TEST_PG_USER` and
`KNARR_TEST_PG_PASS`, and each makes and drops its own schema.

## Release wiring

`dist.ini` is the `[@Author::GETTY]` bundle plus what this repo adds:

- `gather_exclude_match = ^assets/` — the README and POD images stay out of the CPAN tarball.
- `docker_image = raudssus/langertha-knarr` with `docker_tags = latest %V %v` — the release builds and pushes the image. It talks to the container engine at `DOCKER_HOST` over the Engine HTTP API (no docker binary; rootless Podman works) and builds in *every* build — `dzil build`, `dzil test` and `dzil release` alike. `DZIL_DOCKER_API_SKIP=1 dzil build` skips the engine contact; `dzil release` refuses to run with that variable set.
- `GitHub::CreateRelease` publishes the GitHub release once the tag is pushed: the Changes section as notes, the CPAN tarball attached, the token from `~/.github-identity`. **Never create the release from `run_after_release`** — that hook runs before the tag exists, so `gh` puts the tag on the old remote head and `Git::Push` then fails on it.
- No build arguments are passed to the image; `KNARR_DOCKER_BUILD_ARGS` is gone and the Dockerfile has no source ARG. Do not use GitHub source archives (`/archive/refs/*`) for dzil dists.

## Repo mechanics

- **`.claude/` is git-ignored except for a whitelist.** The root `.gitignore` ignores
  `.claude/*` and re-admits `settings.json`, `agents/`, `skills/`, `rules/` — a *new*
  directory under `.claude/` stays invisible to git until it is whitelisted there. Verify
  with `git status --short` after creating one; `.claude/worktrees/` is ignored explicitly.
- **Two kinds of skill live under `.claude/skills/`.** The ones `skilletor` installs carry a
  `.gitignore` holding `*` in their own directory — build artifacts, overwritten by the next
  `skilletor sync`; change them in their source, never here. The repo-owned ones are
  tracked by git: `knarr-core` is the only one here, and it is the file to extend when the
  rules grow too long.
- **An untracked file does not exist as far as dzil is concerned.** `Git::GatherDir`
  collects only what git knows: a file that was never `git add`-ed is skipped while
  gathering, so `prove` runs it and passes while the release tarball silently omits it.
  `git add` new files as soon as they exist.
- **Work in a worktree inside the repo, never in `/tmp`** — `/tmp` does not survive a
  reboot. `git worktree add .claude/worktrees/<name> -b feature/<name>`; `/.claude/worktrees/`
  is git-ignored.

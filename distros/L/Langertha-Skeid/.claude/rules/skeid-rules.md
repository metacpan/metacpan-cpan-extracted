# Langertha::Skeid House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Langertha::Skeid — dynamic routing control plane for multi-node LLM serving with normalized
metrics and cost accounting. Read first: `lib/Langertha/Skeid.pm` is 3000 lines of control
plane and `Proxy.pm` calls into most of it — read the callers before adding beside them.

## Agent team

The lane table lives in `CLAUDE.md`. Read-only research, audit or gap analysis goes to
`skeid-worker` ("read-only, change nothing"). The orchestrator's non-behavioral docs here are
`README.md`, `CONTEXT.md`, ADRs and `docs/`.

Behavior-relevant = anything under `lib/`, `bin/`, `share/`, `t/`, `bench/`, the `Dockerfile`,
`examples/service/*.sh|*.yml`, `cpanfile`, `dist.ini`. POD inside `lib/` goes to a worker too —
it ships in the module.

In prose a card is `k12`, never `#12`.

## Release

`prove -lr t/` is fine anytime. The dzil release uploads to CPAN **and** pushes
`raudssus/langertha-skeid` Docker images (bundle `docker_image`) and creates the GitHub
release — the go-ahead covers all three.

## Deviations from the house rules

- **Public tracker (`Getty/langertha-skeid`) — not even reading on your own initiative.** No
  listing, reading, commenting or closing unless the user names a specific issue.

## Project-specific hazards

- **The request path is async-only** (ADR 0005). No `sleep`/`usleep`, no callback-less
  `$ua->start`, no synchronous HTTP or DB on a request path — it stalls every in-flight stream
  in the process, and single-request tests stay green. Wait with `Mojo::IOLoop->timer`.
- **A secret never reaches disk or a message** (ADR 0003). Config, logs, errors, usage events
  and test fixtures carry key *references* only. `examples/service/.env` is untracked; only
  `.env.example` with placeholders is committed.
- **Every `request.start` needs its `request.finish`** on every exit path, error and
  client-abort included — otherwise the node leaks capacity until restart.
- **Tests are offline by construction.** `Test::Mojo` against `build_app` with an inline fake
  upstream: no network, no OpenBao, no real PostgreSQL. Plain `prove -l t/` is non-recursive —
  always `prove -lr t/`.
- **Benchmarks: one at a time, never in the background, never fanned out** — small shared box
  with other people's services. `nice -n 19 ionice -c3`, `fakellm` on `127.0.0.1`, kill what
  you started. A performance claim without a `bench/` measurement is not a claim.
- **A new tracked top-level directory ships to CPAN** unless `dist.ini` excludes it
  (`Git::GatherDir` + `gather_exclude_match`).
- **Shared skills are skilletor-managed** (`.claude/skilletor.json`, gitignored copies): change
  them in their source and `skilletor sync`, never in `.claude/skills/`. The `skeid-*` skills
  and agents are this repo's own tracked files.

## Specifics — reference, don't restate

Architecture and invariants: `skeid-core`, `skeid-routing`, `skeid-protocols`,
`skeid-relay-routes`, `skeid-service-stack`, `skeid-benchmark`, `skeid-profiling`. Perl, Moo,
POD and release conventions: `getty-perl-core`, `getty-perl-moo`, `getty-perl-pod`,
`getty-perl-release-author-getty`. Vocabulary: `CONTEXT.md`. Decisions: `docs/adr/`.

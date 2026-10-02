# Langertha::Skeid House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills
force-loaded via `briefing.skills`; this file holds what must be true before the first
tool call, for everyone.

## Engineering discipline

1. **Think before coding** — state assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — touch only what you must; match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — pick one pattern, explain why, flag the
   other for cleanup.
6. **Read before you write** — `lib/Langertha/Skeid.pm` is 3000 lines of control plane and
   `Proxy.pm` calls into most of it. Read the callers before adding beside them.
7. **Tests verify intent, not just behavior** — reproduce a bug before fixing it; leave a
   regression test behind. A test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — done / verified / left.
9. **Match the codebase's conventions, even if you disagree** — surface, don't fork.
10. **Fail loud** — "done" is wrong if anything was skipped silently.
11. **A red test is a claim before it is a failure** — say what it asserts before you
    change code to turn it green; don't satisfy an assertion by removing its property.

## Delegation

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate (table in `CLAUDE.md`). Your lane: coordinate, inspect, plan,
  review diffs, run tests, edit non-behavioral docs (`README.md`, `CONTEXT.md`, ADRs,
  `docs/`). Only the `skeid-*` agents get their skills force-loaded; you would touch
  internals with too little context.
- **You cannot spawn subagents** (you ARE a `skeid-*` agent): the lock does not apply to
  you — implement, refactor, debug and test per these rules.

Behavior-relevant = anything under `lib/`, `bin/`, `share/`, `t/`, `bench/`, the
`Dockerfile`, `examples/service/*.sh|*.yml`, `cpanfile`, `dist.ini`. POD inside `lib/` goes
to a worker too — it ships in the module.

**Only `skeid-release-manager` commits.** A worker leaves a commit-ready tree and hands its
card to `review`; you then dispatch the release-manager to cut the commit and close the card.

## Coordination — karr board (always in scope)

Git-native kanban in `refs/karr/*`; this repo has its own board. `karr list --compact`,
`karr show ID`, `karr create "Title" --priority high --tags a,b --body '…'`,
`karr move ID in-progress --claim NAME`, `karr handoff ID --claim NAME --note "…"`. In prose
a card is `k12`, never `#12`. **Serialize board mutations when fanning out** — collect
results, then loop `move`/`handoff`/`sync` sequentially; concurrent board writes have
OOM-rebooted this box.

## Release — never without permission

`prove -lr t/`, `dzil build`, `dzil test` are fine anytime. `dzil release` uploads to CPAN
**and** builds and pushes `raudssus/langertha-skeid` Docker images (`run_after_release`) —
STRICTLY forbidden without the maintainer's explicit go-ahead, even if a plan says
"release" next. Same for `git push`, tags and `docker push`.

## Public issues — never act without instruction

**karr** is the internal agent board. **GitHub** (`Getty/langertha-skeid`) carries real
humans' issues under the maintainer's account: no listing, reading, commenting or closing
unless the user names a specific issue.

## Project-specific hazards

- **The request path is async-only** (ADR 0005). No `sleep`/`usleep`, no callback-less
  `$ua->start`, no synchronous HTTP or DB on a request path — it stalls every in-flight
  stream in the process, and single-request tests stay green. Wait with `Mojo::IOLoop->timer`.
- **A secret never reaches disk or a message** (ADR 0003). Config, logs, errors, usage
  events and test fixtures carry key *references* only. `examples/service/.env` is untracked;
  only `.env.example` with placeholders is committed.
- **Every `request.start` needs its `request.finish`** on every exit path, error and
  client-abort included — otherwise the node leaks capacity until restart.
- **Tests are offline by construction.** `Test::Mojo` against `build_app` with an inline
  fake upstream: no network, no OpenBao, no real PostgreSQL. Plain `prove -l t/` is
  non-recursive — always `prove -lr t/`.
- **Benchmarks: one at a time, never in the background, never fanned out** — small shared
  box with other people's services. `nice -n 19 ionice -c3`, `fakellm` on `127.0.0.1`, kill
  what you started. A performance claim without a `bench/` measurement is not a claim.
- **A new tracked top-level directory ships to CPAN** unless `dist.ini` excludes it
  (`Git::GatherDir` + `gather_exclude_match`).
- **Shared skills are skilletor-managed** (`.claude/skilletor.json`, gitignored copies):
  change them in their source and `skilletor sync`, never in `.claude/skills/`. The
  `skeid-*` skills and agents are this repo's own tracked files.

## Specifics — reference, don't restate

Architecture and invariants: `skeid-core`, `skeid-protocols`, `skeid-service-stack`,
`skeid-benchmark`, `skeid-profiling`. Perl, Moo, POD and release conventions:
`getty-perl-core`, `getty-perl-moo`, `getty-perl-pod`, `getty-perl-release-author-getty`.
Vocabulary: `CONTEXT.md`. Decisions: `docs/adr/`.

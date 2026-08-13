# IO::K8s House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work. Subagents get their conventions from the skills force-loaded via
`briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; ask rather than guess. Push back when a
   simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgically applied** — Minimum code that solves the problem, nothing
   speculative. Touch only what you must; don't "improve" adjacent code or formatting.
3. **Goal-driven execution** — Define success criteria, loop until verified.
4. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more recent
   / more tested), explain why, flag the other. Don't blend.
5. **Read before you write** — Before new code, read `lib/IO/K8s/Resource.pm`,
   `APIObject.pm` and the role you're about to touch. The `k8s` DSL, the attribute registry
   and serialization are one mechanism; "looks orthogonal" is dangerous here.
6. **Tests verify intent, not just behavior** — A test that only checks accessors cannot
   fail when serialization breaks, which is the failure that actually reaches Kubernetes.
   Reproduce a bug before fixing it; leave the regression test behind.
7. **A red test is a claim before it is a failure** — Before changing code to turn a test
   green, say what the test asserts and whether your fix keeps that claim or replaces it.
8. **Checkpoint and fail loud** — Summarize done / verified / left after each significant
   step. "Done" is wrong if anything was skipped silently; "tests pass" is wrong if any
   were skipped — say so.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.

## Delegation

Depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  manage git, edit `Changes`/`README`. When in doubt, delegate. Why: only the `io-k8s-*`
  agents get their skills force-loaded via `briefing.skills`; you get no briefing and would
  touch the DSL and role mesh with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` | `io-k8s-worker` (default) |
  | Write or extend tests in `t/` | `io-k8s-test-writer` |
  | POD, on the core or the API classes | `io-k8s-doc-writer` |
  | Pre-release audit | `io-k8s-release-checker` |

- **You cannot spawn subagents** (you ARE an `io-k8s-*` agent): the lock does not apply —
  implement, refactor, debug and test per these rules.

Behavior-relevant = everything under `lib/`, the `k8s` DSL, the role mesh, types,
serialization, resource maps, AutoGen, and the tests. Prose in `README.md` and `Changes`
bullets are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Git-native kanban; state lives in `refs/karr/*` in this
repo (single distribution, one board, no cross-repo handoff).

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` · `karr edit ID -a "note"`
  · `--claim NAME` · `--block "why"` · `karr move ID in-progress` — full surface: skill `karr`

Record drift and follow-up work as tickets rather than growing the current change.
**Serialize board mutations when fanning out** — parallel implementation is fine, but collect
results and then loop `karr move`/`handoff`/`sync` sequentially.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without explicit go-ahead — even if a plan lists "release" as the next step.
This distribution is **co-maintained**: `authority = cpan:JLMARTIN`, the remote is
`github.com/pplu/io-k8s-p5`, Getty is a co-author. Releasing is not a unilateral call.

## Public issues (GitHub) — never act without instruction

`github.com/pplu/io-k8s-p5` is a **public tracker on someone else's repository**. Never act
on an issue or PR there on your own initiative — not even to read it. No listing, viewing,
commenting, editing, closing or creating unless explicitly told to handle a specific item.
Every write publishes under the maintainer's account.

## Hazards specific to this distribution

- **`prove -l t/` is not recursive** and silently skips subdirectory tests, exiting 0. Use
  `dzil test` or `prove -lr t/` (~16s for the full suite). Reserve non-`-r` for a single
  named file.
- **`our $VERSION` in every module is correct here** — do not "clean it up" to the main
  module only. The `[@Author::GETTY]` bundle narrows `version_finder` to `:MainModule` only
  for `no_cpan` dists; this one ships to CPAN, so every package needs its own version for
  PAUSE indexing. The trap: the usual house rule says the opposite, and a grep "confirms" it.
- **There is no codegen step.** The API classes are checked in and hand-maintained; there is
  no generator to re-run. `IO::K8s::AutoGen` builds classes in memory at runtime and only
  when the caller passed an `openapi_spec` — it never writes files and never fills a gap in
  the shipped surface.
- **A mass edit across `lib/` hits ~850 files at once.** Upstream API syncs legitimately work
  that way, but one wrong pattern lands everywhere and `t/02_compile_all.t` only proves the
  files still load. Always follow a sweep with the full suite plus
  `t/26_build_verify.t` / `t/25_real_world.t`, which check both serialization directions.
- **Removing public API is a breaking change with a protocol**: the old name gets a
  redirect stub in the separate `IO::K8s::Deprecated` distribution (its own CPAN dist, not
  a module in this repo), and `Changes` states the changed failure mode. See the 1.105
  `*List` removal.

## Perl conventions — reference, don't restate

Module loading, Moo patterns, dependency pinning and house style live in skills `perl-core`,
`perl-moo`, `io-k8s-core` and `perl-release-author-getty` (force-loaded per lane via
`briefing.skills` — `.claude/agents/` defines which agent briefs which). Do not duplicate
that content here.

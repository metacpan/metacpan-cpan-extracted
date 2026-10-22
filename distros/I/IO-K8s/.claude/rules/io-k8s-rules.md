# IO::K8s House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work. Subagents get their conventions from the skills force-loaded via
`briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions; ask rather than guess. Push back when a
   simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgically applied** — minimum code, nothing speculative; touch only what you must, don't "improve" adjacent code or formatting.
3. **Goal-driven execution** — Define success criteria, loop until verified.
4. **Surface conflicts, don't average them** — pick one (more recent / more tested), explain why, flag the other. Don't blend.
5. **Read before you write** — read `lib/IO/K8s/Resource.pm`, `APIObject.pm` and the role
   you're about to touch; the `k8s` DSL, the attribute registry and serialization are one
   mechanism — "looks orthogonal" is dangerous here.
6. **Tests verify intent, not just behavior** — a test that only checks accessors cannot fail
   when serialization breaks. Reproduce a bug before fixing it; leave the regression test.
7. **A red test is a claim before it is a failure** — say what the test asserts and whether
   your fix keeps that claim or replaces it.
8. **Checkpoint and fail loud** — done / verified / left after each significant step. "Done"
   is wrong if anything was skipped silently; "tests pass" is wrong if any were skipped.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant code yourself —
  delegate. Your lane: coordinate, inspect, plan, review diffs, run tests, edit `Changes`/`README`. When in
  doubt, delegate — only `io-k8s-*` agents get their skills force-loaded via `briefing.skills`; you get no
  briefing and would touch the DSL and role mesh with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug anything under `lib/` | `io-k8s-worker` (default) |
  | Write or extend tests in `t/` | `io-k8s-test-writer` |
  | POD, on the core or the API classes | `io-k8s-doc-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `io-k8s-release-manager` |

- **You cannot spawn subagents** (you ARE an `io-k8s-*` agent): the lock does not apply — work per these rules.

Behavior-relevant = everything under `lib/`, the `k8s` DSL, the role mesh, types, serialization,
resource maps, AutoGen, and the tests. Prose in `README.md` and `Changes` bullets are not.

**Only `io-k8s-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `io-k8s-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the skill first, just use it. Git-native kanban; state lives in `refs/karr/*` in this
repo (single distribution, one board, no cross-repo handoff).

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail · `karr create
  "Title" --priority high --tags a,b --body '…'` · `karr edit ID -a "note"` · `--claim NAME`
  · `--block "why"` · `karr move ID in-progress` — full surface: skill `kanban-issues-karr-coordination`

Record drift and follow-up work as tickets rather than growing the current change.
**Serialize board mutations when fanning out** — parallel implementation is fine, but collect
results and then loop `karr move`/`handoff`/`sync` sequentially.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without explicit go-ahead — even if a plan lists "release" as the next step. The dist
is **co-maintained** (`authority = cpan:JLMARTIN`): releasing is no unilateral call.

## Public issues (GitHub) — never act without instruction

`github.com/pplu/io-k8s-p5` is a **public tracker on someone else's repository**. Never act on
an issue or PR there on your own initiative — not even to read it: no listing, viewing,
commenting, editing, closing or creating unless explicitly told to handle a specific item.
Every write publishes under the maintainer's account.

## Hazards specific to this distribution — mechanics in skill `io-k8s-core`

- **`prove -l t/` is not recursive** and silently skips subdirectory tests, exiting 0. Use
  `dzil test` or `prove -lr t/` (~16s for the full suite); reserve non-`-r` for one named file.
- **`our $VERSION` in every module is correct here** — do not "clean it up" to the main module; every package needs its own version for PAUSE indexing.
- **There is no codegen step** — the API classes are hand-maintained; `IO::K8s::AutoGen` never writes files.
- **A mass edit across `lib/` hits ~850 files at once** — always follow a sweep with the full
  suite plus `t/26_build_verify.t` / `t/25_real_world.t` (both serialization directions).
- **Removing public API is a breaking change with a protocol** — the old name gets a redirect
  stub in the separate `IO::K8s::Deprecated` distribution, and `Changes` states the changed mode.

## Perl conventions — reference, don't restate

House style, module loading, Moo patterns and pinning live in skills `getty-perl-core`,
`getty-perl-moo`, `io-k8s-core` and `getty-perl-release-author-getty` (per lane via
`briefing.skills`) — do not duplicate that content here.

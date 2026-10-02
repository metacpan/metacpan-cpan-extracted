# Langertha House Rules

Apply to every task in the Langertha distribution unless explicitly overridden. Bias: caution
over speed on non-trivial work; use judgment on trivial tasks.

## Engineering discipline

1. **Think before coding** — State assumptions explicitly. When uncertain, ask rather than
   guess. Present multiple interpretations when ambiguous. Push back when a simpler approach
   exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code, comments,
   or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other for cleanup. Don't blend.
6. **Read before you write** — Before new code, read exports, immediate callers, shared
   roles. "Looks orthogonal" is dangerous, especially across the engine/role mesh.
7. **Tests verify intent, not just behavior** — Tests encode WHY behavior matters. A test
   that can't fail when business logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left. Don't
   continue from a state you can't describe back.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste. Surface
   a harmful convention; don't fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong
    if any were skipped (the env-gated live tests `t/8x` skip without keys — say so).
    Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  Langertha code yourself — delegate to `langertha-worker` or the specialist whose lane it is
  (table in `CLAUDE.md`). Your lane: coordinate, inspect,
  plan, review diffs, run tests, write/curate ADRs and non-behavioral docs. When
  in doubt, delegate. Why: the `langertha-*` agents get their skills force-loaded via
  `briefing.skills` (perl-ai-langertha, getty-perl-moose, …); the bare main agent gets no briefing
  and would touch the engine/role internals with too little context.
- **You cannot spawn subagents** (you ARE `langertha-worker` or similar): The delegation lock
  does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, public API, engine request/response handling, the tool
wire-translation seam (`tool_wire_format` + the Tool/ToolCall/ToolResult/ToolChoice value
objects), the capability registry, the Raider loop, streaming, async, MCP integration, error
handling, tests, performance. Pure prose docs, ADRs, and `Changes` notes are not.

**Only `langertha-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `langertha-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban; board state lives in
`refs/karr/*` in this repo (Langertha is a single distribution — one board, no cross-repo
handoff). Day-to-day:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

Use karr to record decisions worth solidifying, drift to reconcile, and follow-up work that
should not block the current change. Full command surface: skill `kanban-issues-karr-coordination`.

## Public issues (GitHub) — never act without instruction

Two trackers, two universes. **karr** is the AI/agent work board — internal, ours, churned
freely (see above). **GitHub issues** (`gh` CLI, `github.com/Getty/langertha`) are the
**public tracker: real humans' bug reports and feature requests**, outward-facing and written
under the maintainer's account.

Security rule: **never act on a GitHub issue or PR on your own initiative — not even to read
it.** No listing, viewing, commenting, editing, closing, or creating unless the user
explicitly tells you to handle a specific public item. Incoming user tickets are NOT a queue
the agent drains; they are touched only on direct instruction, and every write is confirmed
first because it publishes under the maintainer's name. Full `gh` usage + guardrails: skill
`langertha-github-issues`.

## Live tests & real spend — never arm by accident

The env-gated live tests (`t/8x`) spend the maintainer's real money at every keyed provider.
`prove` / `dzil test` themselves are fine anytime — the danger is arming them by accident:

- **Never source `.env` (or set any `TEST_LANGERTHA_*`) in the same shell command as `prove`,
  `dzil test`, or anything recursive over `t/`.** One such command exports every key into the
  run and fires the *whole* live suite against *every* keyed provider — real spend, no approval.
  (Not hypothetical: a single `set -a && . ./.env && … && prove -lr t/` once did exactly that
  across ~16 providers, image generation included.)
- Key or fixture checks that need `.env` run in their **own** command — a subshell that ends
  before any `prove`. Before a suite run, assert the environment is clean:
  `[ "$(env | grep -c TEST_LANGERTHA)" = 0 ]`, or isolate it:
  `env -i PATH="$PATH" HOME="$HOME" prove -lr t/`.
- **Never print the process environment** (`env`, `printenv`, a fall-through `env -u …`): it
  carries the provider keys. Count, never list: `env | grep -c TEST_LANGERTHA`.
- Live calls otherwise need explicit approval (AKI.IO is the standing exception). When you
  dispatch a worker or subagent, pass this hard rule on — it inherits your keys, not your care.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without the maintainer's explicit go-ahead — even if a plan or TODO lists "release"
as the next step. The `[@Author::GETTY]` bundle bumps `$VERSION` and tags on release; for
anything heading toward release: stop and ask.

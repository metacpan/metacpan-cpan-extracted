# Raider House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills force-loaded
via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Present alternatives when ambiguous. Push back when a simpler approach exists. Stop when
   confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code,
   comments, or formatting. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — Contradicting patterns: pick one (more
   recent / more tested), explain why, flag the other for cleanup. Don't blend.
6. **Read before you write** — Before new code, read `CONTEXT.md`, the relevant ADRs in
   `docs/adr/`, the karr ticket, and the nearest analogous module in `langertha-knarr` or
   `langertha-skeid`.
7. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave a
   regression test behind. A test that can't fail when the logic changes is wrong.
8. **Checkpoint after every significant step** — Summarize: done / verified / left.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.
   Surface a harmful convention; don't fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is
    wrong if any were skipped. Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  Raider code yourself — delegate to `raider-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, edit non-behavioral docs. When in doubt, delegate.
  Why: the `raider-*` agents get their skills force-loaded via `briefing.skills`
  (perl-ai-langertha, getty-perl-moose, perl-mcp, …); you get no briefing and would touch
  the agent-engine/CLI internals with too little context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `raider-worker` (default) |
  | Write/extend tests | `raider-test-writer` |
  | Commits, `Changes`, card → done, pre-release audit | `raider-release-manager` |

- **You cannot spawn subagents** (you ARE a `raider-*` agent): The delegation lock does not
  apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, public API, the agent loop, MCP tool calling, CLI/
Hall/ACP behavior, tests, performance. Pure prose docs and `Changes` notes are not.

**Only `raider-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `raider-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't
invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban; board state lives in
`refs/karr/*` in this repo (own board; the sibling Langertha repos each have their own —
cross-repo work is a ticket on that repo's board, never a direct edit). Day-to-day:

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr edit ID -a "note"` · `--claim NAME` · `--block "why"` — update
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

**Serialize board mutations when fanning out.** Keep implementation parallel, then loop
`karr move`/`handoff`/`sync` sequentially — N of them landing at once has OOM-rebooted a
host before.

## Public issues (GitHub) — never act without instruction

**karr** is the internal agent board, churned freely. The public tracker for this project
(`github.com/Getty/langertha-raider`; the old `Getty/raider` is archived) is written under
the maintainer's name. **Never act on
a public issue or PR on your own initiative — not even to read it.** No listing, viewing,
commenting, editing, closing, or creating unless the user explicitly says to handle a
specific item, and every write is confirmed first.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime once they exist. `dzil release` is STRICTLY
forbidden without the maintainer's explicit go-ahead — the old `raider` repo's release
chain also created a GitHub release and pushed a Docker Hub image, and that automation is
expected to carry over. Same lock applies to standalone `docker push` and `gh release`.
For anything heading toward release: stop and ask.

## Raider-specific hazards

- **Decided means an ADR.** Do not invent architecture beyond what `docs/adr/` records —
  flag gaps as karr tickets or questions instead of guessing. Work in the small slices the
  tickets describe; no big-bang rewrite.
- **Dependency direction is one-way** (Raider → Langertha core, never back) — see
  `raider-worker`'s agent body for the exact modules. Don't move core tool-calling
  foundation (`Role::Tools`, `Plugin.pm`, `Chat.pm`, …) into this repo; it's shared, not
  Raider-specific.
- **Naming is resolved:** `Langertha::Raider` = engine + main_module, the CLI is
  `Langertha::Raider::CLI`. Old `App::Raider*` names are reserved stubs only — never put
  code back there.

## Perl specifics — reference, don't restate

Module loading, Moose house patterns, cpanfile versioning, POD directives, MCP protocol
details, and commit style live in the briefed skills (`getty-perl-core`,
`perl-ai-langertha`, `getty-perl-moose`, `perl-io-async-future`, `perl-mcp`,
`getty-perl-release-author-getty`, `getty-git-commit-style`). Do not duplicate that
content here.

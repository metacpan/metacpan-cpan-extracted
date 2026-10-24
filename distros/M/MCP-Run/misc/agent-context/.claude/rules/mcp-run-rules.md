# MCP-Run House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution
over speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at
launch (same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — state assumptions; when uncertain, ask rather than guess.
   Push back when a simpler approach exists.
2. **Simplicity first** — minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — touch only what you must. Match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — pick one (more recent / more tested),
   flag the other for cleanup. Don't blend.
6. **Read before you write** — read exports, immediate callers, the
   `MCP::Run`/`MCP::Run::Bash`/`MCP::Run::Compress` triad. "Looks orthogonal" is
   dangerous across two products sharing one codebase.
7. **Tests verify intent, not just behavior** — a test that can't fail when the logic
   changes is wrong. Reproduce a bug before fixing it; leave a regression test behind.
8. **Checkpoint after every significant step** — summarize: done / verified / left.
   Don't continue from a state you can't describe back.
9. **Match conventions** — conformance > taste. Surface a harmful convention; don't
   fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped. "Tests pass" is wrong if
    any were skipped. Surface uncertainty.
11. **A red test is a claim before it is a failure** — before changing code to turn a test green,
    say out loud what the test asserts. A fix that satisfies the assertion by removing the
    property it was sampling proves nothing. If the claim is wrong, fix the claim and say so.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  MCP-Run code yourself — delegate to `mcp-run-worker`. Your lane: coordinate, inspect,
  plan, review diffs, run tests, edit non-behavioral docs. When in doubt, delegate. Why:
  only the `mcp-run-*` agents get their skills force-loaded via `briefing.skills`; you get
  no briefing and would touch internals with too little context.

- **You cannot spawn subagents** (you ARE `mcp-run-worker` or similar): The delegation
  lock does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the MCP tool wire-format contract, IPC::Open3
execution, the `allowed_commands` / `validator` gates, timeout handling, the compression
pipeline, the hook (PostToolUse compression + PreToolUse Co-Authored-By), tests,
performance. Pure prose docs and `Changes` notes are not.

**Only `mcp-run-release-manager` commits.** A worker leaves a commit-ready tree and hands its card
to `review`; you then dispatch `mcp-run-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't invoke
`kanban-issues-karr-coordination` first, just use it. Git-native kanban, state in `refs/karr/*`;
single distribution — one board, no cross-repo handoff. Use it to record decisions worth
solidifying, drift to reconcile, and follow-up work that shouldn't block the current change.
Full command surface: skill `kanban-issues-karr-coordination`.

**Serialize board mutations when fanning out.** Keep implementation parallel if you like,
but collect results and loop `karr move`/`handoff`/`sync` sequentially — N landing at once
is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any CPAN upload
or Docker Hub push are STRICTLY forbidden without the maintainer's explicit go-ahead — even
if a plan, TODO or `Changes` notes "release" as the next step. The `[@Author::GETTY]` bundle
bumps `$VERSION` and tags on release; for anything heading toward release: stop and ask.

## Public issues — never act without instruction

Two trackers, two universes. **karr** is the internal agent board (churned freely). **GitHub
issues / CPAN RT** are the public tracker: real humans' reports under the maintainer's name.
**Never act on a public issue on your own initiative — not even to read it.** No listing,
viewing, commenting, editing, closing, or creating unless the user explicitly names a
specific public item to handle. Incoming tickets are not a queue.

## MCP-Run hazards and specifics — reference, don't restate

Two products share one codebase but ship independently; the sharp edges that follow live in skill
`mcp-run-core`, briefed into every `mcp-run-*` agent — the `allowed_commands` non-sandbox, the
`working_directory` as `cd '$dir' && ...`, the two intentional compression defaults, PostToolUse
compression, the hook's no-permission rule, `format_result` threading `$command`. The
orchestrating agent delegates behaviour-relevant work to them; don't restate them here.

Module loading, Moo patterns, cpanfile pinning: skill `getty-perl-core`. `[@Author::GETTY]`
bundle, POD, `{{$NEXT}}`: skill `getty-perl-release-author-getty`. dist.ini mechanics:
`perl-release-dist-ini`. MCP server setup: `perl-mcp`. Don't duplicate.

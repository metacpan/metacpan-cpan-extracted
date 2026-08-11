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
11. **A red test is a claim before it is a failure** — before changing code to turn a
    test green, say out loud what the test asserts. A fix that satisfies the assertion
    by removing the property it was sampling proves nothing. If the claim is wrong,
    fix the claim and say so.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  MCP-Run code yourself — delegate to `mcp-run-worker`. Your lane: coordinate, inspect,
  plan, review diffs, run tests, manage git, edit non-behavioral docs. When in doubt,
  delegate. Why: only the `mcp-run-*` agents get their skills force-loaded via
  `briefing.skills`; you get no briefing and would touch internals with too little
  context.

- **You cannot spawn subagents** (you ARE `mcp-run-worker` or similar): The delegation
  lock does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the MCP tool wire-format contract, IPC::Open3
execution, the `allowed_commands` / `validator` gates, timeout handling, the compression
pipeline, the hook's command-rewriting logic, Co-Authored-By handling, tests,
performance. Pure prose docs and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `karr` skill first, just use it. Git-native kanban; state lives in
`refs/karr/*`; this repo is a single distribution — one board, no cross-repo handoff.
Day-to-day: `karr list --compact` / `karr board` for open work; `karr show ID` for
detail; `karr create/edit/move/handoff` for the usual workflow; mutating commands
auto-sync, `karr sync --pull|--push` for explicit exchange. Use karr to record
decisions worth solidifying, drift to reconcile, and follow-up work that should not
block the current change. Full command surface: skill `karr`.

**Serialize board mutations when fanning out.** Keep implementation work parallel if
you like, but collect results and then loop `karr move`/`handoff`/`sync` sequentially
— N of them landing at once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any
CPAN upload or Docker Hub push are STRICTLY forbidden without the maintainer's explicit
go-ahead — even if a plan, TODO or `Changes` notes "release" as the next step. The
`[@Author::GETTY]` bundle bumps `$VERSION` and tags on release; for anything heading
toward release: stop and ask.

## Public issues — never act without instruction

Two trackers, two universes. **karr** is the internal AI/agent work board (churned
freely). **GitHub issues / CPAN RT** are the public tracker: real humans' reports,
written under the maintainer's name. **Never act on a public issue on your own
initiative — not even to read it.** No listing, viewing, commenting, editing,
closing, or creating unless the user explicitly tells you to handle a specific
public item. Incoming tickets are NOT a queue the agent drains.

## MCP-Run-specific hazards

Two products share one codebase but ship independently. Traps that will bite:

- **`allowed_commands` is NOT a sandbox** — first-word match only. `allowed_commands =>
  ['bash']` runs `bash -c 'rm -rf /'`. Don't widen the matcher silently; real sandboxing
  is a feature, surface as a ticket.
- **`working_directory` is `cd '$dir' && $command`** in lib/MCP/Run/Bash.pm, not chdir
  + open3. Single-quote escaping lives there. Don't "refactor" without auditing callers.
- **Two compression defaults, intentionally.** `bin/mcp-run-bash` ON; `MCP::Run` module
  attribute OFF. Not drift — bin is user-facing default, module is library default.
  Do not align.
- **`--b64` hardcodes 1800s** in bin/mcp-run-compress. No env-var. If changed, also
  update `.claude/skills/mcp-run-core/SKILL.md` env-vars section and the README.
- **Hook does NOT enforce permissions.** It rewrites Bash → `mcp-run-compress --b64`.
  Permission is Claude Code's job. Permission logic in the hook = layering violation.
- **`format_result($tool, $result, $compress, $command)`:** overriding subclasses MUST
  thread `$command` through — command-specific filters only match when they see it.
- **`transform_command` (Co-Authored-By) ≠ `compress()` (output filtering)** — different
  functions, different inputs. Do not merge.
- **`MCP_RUN_COMPRESS_NO_CO_AUTHORED` ≠ `CO_AUTHORED_BY`** — first disables, second
  replaces. Not aliases.

## Perl specifics — reference, don't restate

Module loading, Moo patterns, cpanfile pinning: skill `perl-core`. `[@Author::GETTY]`
bundle, POD, `{{$NEXT}}`: skill `perl-release-author-getty`. dist.ini mechanics:
`perl-release-dist-ini`. MCP server setup: `perl-mcp`. Don't duplicate.
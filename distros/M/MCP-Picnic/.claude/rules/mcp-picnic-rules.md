# MCP::Picnic House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills force-loaded
via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions explicitly. When uncertain, ask rather than
   guess. Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative. No
   abstractions for single-use code.
3. **Surgical changes** — Touch only what you must. Don't "improve" adjacent code or
   formatting. Match the existing style.
4. **Read before you write** — Before adding a tool, read `_build_server` and an existing
   `$server->tool(...)` block plus its `_*_to_hash` helper. They are the template; conform.
5. **Fail loud** — "Done" is wrong if anything was skipped silently. "Tests pass" is wrong if
   any were skipped. Surface uncertainty, don't hide it.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `mcp-picnic-worker`. Your lane: coordinate, inspect, plan,
  review diffs, run tests, manage git, edit non-behavioral docs. When in doubt, delegate.
  Why: only the `mcp-picnic-*` agents get their skills force-loaded via `briefing.skills`;
  you get no briefing and would touch internals with too little context. Specialist lanes:

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `mcp-picnic-worker` (default) |
  | Write / extend tests | `mcp-picnic-test-writer` |
  | Write or improve POD | `mcp-picnic-pod-writer` |
  | Pre-release audit | `mcp-picnic-release-checker` |

- **You cannot spawn subagents** (you ARE an `mcp-picnic-*` agent): The delegation lock does
  not apply to you — implement, refactor, debug, and test per these rules and your skills.

Behavior-relevant = the tool registry in `_build_server`, the `_ensure_auth`/2FA state
machine, `WWW::Picnic` delegation, the `_*_to_hash` projections, JSON encoding, the three
`bin/` entry points, tests. Pure prose docs and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — just
use it. Git-native kanban; state lives in `refs/karr/*`; this repo has its own board.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; full command surface: skill `kanban-issues-karr-cli`.

**Serialize board mutations when fanning out.** Keep implementation parallel if you like, but
collect the results and then loop `karr move`/`handoff`/`sync` sequentially — N of them
landing at once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without the maintainer's explicit go-ahead — even if a plan lists "release" as the
next step. For anything heading toward release: stop and ask. Use the
`mcp-picnic-release-checker` agent for the pre-release audit.

## Project-specific hazards

- **English only in shipped strings.** All POD, MCP tool `description`s, result messages and
  error text are English — this ships to CPAN and to assistants worldwide. The one exception
  is `bin/mcp-picnic-setup`, which has an `en`/`de` translation table; keep `en` complete and
  primary. (The historic 0.001 code carried German prose — new and edited code is English.)
- **`$self` vs `$tool` in handlers.** A tool handler's first arg is the `MCP::Tool` instance,
  NOT `MCP::Picnic`; `$self` comes from the enclosing closure. A green test suite does not
  catch a handler that rebinds `$self` and only breaks against the live API.
- **Tests must stay network-free.** Never hit the real Picnic API or send a real 2FA SMS from
  `t/`. Stub the `picnic` attribute; drive `_auth_state` directly.
- **Version lives in one place.** `our $VERSION` is only in `lib/MCP/Picnic.pm` (no sibling
  modules); `bin/` reads `$MCP::Picnic::VERSION`. Never hand-edit a version line —
  `[@Author::GETTY]` owns it.

## Perl / architecture specifics — reference, don't restate

Moo patterns, the tool-handler shape, the auth/2FA gate, `WWW::Picnic` delegation and the
`_*_to_hash` projection convention live in skill `mcp-picnic-core`; generic MCP::Server
mechanics in `perl-mcp`; house Perl style in `getty-perl-core` / `getty-perl-moo`; the
build/POD/release workflow in `getty-perl-release-author-getty` / `perl-release-dist-ini`.
All force-loaded for `mcp-picnic-*` agents. Do not duplicate that content here.

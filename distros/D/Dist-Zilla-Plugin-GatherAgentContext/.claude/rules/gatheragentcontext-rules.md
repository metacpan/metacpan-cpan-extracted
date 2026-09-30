# Dist::Zilla::Plugin::GatherAgentContext — House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills force-loaded
via `briefing.skills`; this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — state assumptions, ask rather than guess, push back when a
   simpler approach exists, stop when confused and name what's unclear.
2. **Simplicity first** — minimum code that solves the problem; nothing speculative.
3. **Surgical changes** — touch only what you must; don't "improve" adjacent code; match
   existing style.
4. **Read before you write** — read the module, its callers and the tests before changing
   behavior.
5. **Tests verify intent** — reproduce a bug before fixing it; leave a regression test.
6. **Fail loud** — "Done" is wrong if anything was skipped; "tests pass" is wrong if any
   were skipped.

## Delegation

- **You can spawn subagents** (orchestrating main agent): do NOT touch behavior-relevant
  code yourself — delegate to `gatheragentcontext-worker`. Your lane: coordinate, inspect,
  plan, review diffs, run tests, edit prose docs. Commits go through
  `gatheragentcontext-release-manager`, never through you or the worker. Why: only the
  `gatheragentcontext-*` agents get their skills force-loaded via `briefing.skills`; you get
  no briefing and would touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug / test the plugin | `gatheragentcontext-worker` (default) |
  | Commits, `Changes`, pre-release audit | `gatheragentcontext-release-manager` |

- **You cannot spawn subagents** (you ARE a `gatheragentcontext-*` agent): the lock does not
  apply — implement, refactor, debug, and test per these rules.

Behavior-relevant = the gathered/excluded/pruned file set, the public attributes, UTF-8 and
symlink handling, and the tests. Pure prose (README.md, POD prose) is not.

## Project hazards — the mechanism, not the moral

- **The plugin reads the working directory, not git.** Deliberate: it captures
  skilletor-installed, git-ignored context. Never "fix" it to read from git.
- **Excluded dirs are pruned before descent.** `.claude/worktrees/` is thousands of files; a
  walk-then-filter rewrite re-introduces a full stat-walk on every build.
- **UTF-8 decode is strict** (`Encode::FB_CROAK`) so binary content fails loud. A lenient
  `:encoding(UTF-8)` layer would silently substitute — do not.
- **Test with `dzil test --all`, not `prove`.** `prove -l t/` skips the woven author tests
  (`pod-syntax`, `changes_has_content`) that gate a release.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release`, `git push`, tags and any upload
are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan lists
"release" as the next step. Stop and ask.

## Perl specifics — reference, don't restate

Module loading, Moose classes, attributes, dependency pinning and house style live in skills
`getty-perl-core` and `getty-perl-moose` (force-loaded for
`gatheragentcontext-*` agents). Do not duplicate that content here.

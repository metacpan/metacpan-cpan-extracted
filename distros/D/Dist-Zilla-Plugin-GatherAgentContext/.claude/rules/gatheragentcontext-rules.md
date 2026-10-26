# Dist::Zilla::Plugin::GatherAgentContext — House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Snapshot the agent context (`.claude`/`.codex`/`CLAUDE.md`/`AGENTS.md`/…) into the build for
provenance. Read first: the module, its callers and the tests.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug / test the plugin | `gatheragentcontext-worker` (default) |
| Commits, `Changes`, pre-release audit | `gatheragentcontext-release-manager` |
| Read-only research, audit, gap analysis | `gatheragentcontext-worker` ("read-only, change nothing") |

Behavior-relevant = the gathered/excluded/pruned file set, the public attributes, UTF-8 and
symlink handling, and the tests. Pure prose (README.md, POD prose) is not.

## Hazards — the mechanism, not the moral

- **The plugin reads the working directory, not git.** Deliberate: it captures
  skilletor-installed, git-ignored context. Never "fix" it to read from git.
- **Excluded dirs are pruned before descent.** `.claude/worktrees/` is thousands of files; a
  walk-then-filter rewrite re-introduces a full stat-walk on every build.
- **UTF-8 decode is strict** (`Encode::FB_CROAK`) so binary content fails loud. A lenient
  `:encoding(UTF-8)` layer would silently substitute — do not.
- **Test with `dzil test --all`, not `prove`.** `prove -l t/` skips the woven author tests
  (`pod-syntax`, `changes_has_content`) that gate a release.

## Perl specifics — reference, don't restate

Module loading, Moose classes, attributes, dependency pinning and house style live in skills
`getty-perl-core` and `getty-perl-moose` (force-loaded for `gatheragentcontext-*` agents).

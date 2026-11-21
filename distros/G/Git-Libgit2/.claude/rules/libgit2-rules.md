# Git::Libgit2 House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Low-level FFI::Platypus bindings to libgit2, via Alien::Libgit2.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `libgit2-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `libgit2-release-manager` |
| Read-only research, audit, gap analysis | `libgit2-worker` ("read-only, change nothing") |

Behavior-relevant = anything under `lib/`, the tests under `t/`, the set of bound functions and
the README bound-surface list that names them. `TODO.md`, the wording of `README.md` and
`Changes` are not.

## Deviations from the house rules

- **A finding from a public issue becomes an internal card**; the dispatching agent files it.

## Hazards

- **A new dependency needs a real justification.**

## Perl specifics — reference, don't restate

Skill content is never restated here: the skills are the source, the agents get them
force-loaded via `briefing.skills` (`libgit2-core` and the shared Perl skills).

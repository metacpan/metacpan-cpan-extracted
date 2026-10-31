# IO::K8s House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Objects representing things found in the Kubernetes API. Read first:
`lib/IO/K8s/Resource.pm`, `APIObject.pm` and the role you're about to touch; the `k8s` DSL,
the attribute registry and serialization are one mechanism — "looks orthogonal" is dangerous
here.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` | `io-k8s-worker` (default) |
| Write or extend tests in `t/` | `io-k8s-test-writer` |
| POD, on the core or the API classes | `io-k8s-doc-writer` |
| Commits, `Changes`, card → done, pre-release audit | `io-k8s-release-manager` |
| Read-only research, audit, gap analysis | `io-k8s-worker` ("read-only, change nothing") |

Behavior-relevant = everything under `lib/`, the `k8s` DSL, the role mesh, types,
serialization, resource maps, AutoGen, and the tests. Prose in `README.md` and `Changes`
bullets are not. Single distribution, one board, no cross-repo handoff.

## Release

The dist is **co-maintained** (`authority = cpan:JLMARTIN`): releasing is no unilateral call.

## Deviations from the house rules

- **Public tracker on someone else's repository:** `github.com/pplu/io-k8s-p5` — issues and PRs
  there are off limits unless explicitly told to handle a specific item.

## Hazards specific to this distribution — mechanics in skill `io-k8s-core`

- **Tests that only check accessors** cannot fail when serialization breaks — test the
  serialization.
- **`prove -l t/` is not recursive** and silently skips subdirectory tests, exiting 0. Use
  `dzil test` or `prove -lr t/` (~70s for the full suite); reserve non-`-r` for one named file.
- **`our $VERSION` in every module is correct here** — do not "clean it up" to the main module;
  every package needs its own version for PAUSE indexing.
- **There is no codegen step** — the API classes are hand-maintained; `IO::K8s::AutoGen` never
  writes files.
- **A mass edit across `lib/` hits ~850 files at once** — always follow a sweep with the full
  suite plus `t/26_build_verify.t` / `t/25_real_world.t` (both serialization directions).
- **Removing public API is a breaking change with a protocol** — the old name gets a redirect
  stub in the separate `IO::K8s::Deprecated` distribution, and `Changes` states the changed mode.

## Perl conventions — reference, don't restate

House style, module loading, Moo patterns and pinning live in skills `getty-perl-core`,
`getty-perl-moo`, `io-k8s-core` and `getty-perl-release-author-getty` (per lane via
`briefing.skills`).

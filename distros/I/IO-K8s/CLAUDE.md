# CLAUDE.md — IO::K8s

Perl object model of the Kubernetes API (tracking upstream v1.36). Moo + Type::Tiny; the
~850 API and CRD classes under `lib/IO/K8s/` are checked in and hand-maintained — there is
no build-time codegen step.

Build and test: `dzil build`, `dzil test`, `dzil clean`. While iterating: `prove -lr t/`
(**`-r` is required** — plain `prove -l t/` is not recursive). Never `dzil release` without
explicit permission; this distribution is co-maintained (`authority = cpan:JLMARTIN`).

## Checking coverage against upstream

`maint/spec-drift-check.pl` diffs a real Kubernetes `swagger.json` against what `lib/IO/K8s/`
actually ships (the `k8s()` attribute registry) and reports missing Kinds/types/fields —
the repeatable version of the manual sweep behind karr #4-#8. Run with no arguments for a
coverage report against the latest stable release, or `--from TAG --to TAG` to diff two
upstream releases directly (the "is upgrading worth it" question). It never edits `lib/` and
never creates karr tickets — deciding what a reported gap is worth is a human/agent call, not
the script's.

Settled non-gaps (dropped `*List` kinds, old back-compat API tracks, apimachinery
scalar barewords, Kinds whose upstream docs no longer live at the v1.36 URL) are filtered
via the maintained `maint/spec-drift-exceptions.yaml`, not hardcoded. When making a
deliberate "we don't ship this" decision — a removed Kind, an upstream-removed field kept
for back-compat, an API track intentionally not backported — add a categorised entry to
that file with a one-line reason. New entries should reference the karr ticket or commit
that established the call. `maint/spec-drift-check.pl --verbose` lists what is currently
suppressed; the exception file is the source of truth, not the script's runtime memory.

`maint/spec-drift-check.pl --help` for the full flag list.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lanes and this repo's hazards are in `.claude/rules/io-k8s-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug anything under `lib/` | `io-k8s-worker` (default) |
| Write or extend tests in `t/` | `io-k8s-test-writer` |
| POD, on the core or the API classes | `io-k8s-doc-writer` |
| Pre-release audit | `io-k8s-release-checker` |

`io-k8s-doc-writer` is this repo's documentation lane.

The agents carry their conventions via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live in `.claude/skills/` —
`io-k8s-core` holds the distribution internals, `perl-kubernetes-classes` the consumer-facing
API. Work is tracked on the local `karr` board.

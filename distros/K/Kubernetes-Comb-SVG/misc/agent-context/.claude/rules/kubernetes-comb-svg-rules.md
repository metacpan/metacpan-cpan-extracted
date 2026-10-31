# Kubernetes::Comb::SVG House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Renders Kubernetes::Comb custom resources as an SVG honeycomb. Read first: `SPEC.md`, then the
seam you touch (`Cell` reads, `Layout` places, `SVG` draws) — "looks orthogonal" is dangerous.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `kubernetes-comb-svg-worker` (default) |
| Write/extend tests, fixtures under `t/data/` | `kubernetes-comb-svg-test-writer` |
| POD in the house format (`=attr`/`=method`) | `kubernetes-comb-svg-pod-writer` |
| Commits, packaging (`dist.ini`, `Changes`, `LICENSE`, CI, `.gitignore`), card → done, pre-release audit | `kubernetes-comb-svg-release-manager` |
| Read-only research, audit, gap analysis | `kubernetes-comb-svg-worker` ("read-only, change nothing") |

Behavior-relevant = anything under `lib/`, `bin/`, `t/`, `examples/`: reading the CR, layout,
drawing, escaping, the theme, the CLI. Packaging belongs to the release-manager; `cpanfile`
lines arrive with the code that needs them. The main agent edits `SPEC.md`/`CLAUDE.md` prose
only with the maintainer: `SPEC.md` changes are design changes — only the maintainer's call.

## Hazards — what actually goes wrong here

- **Unescaped CR values.** Names, messages and label values come from a cluster and end up in a
  web page — one value interpolated without the escape function is an injection hole, so
  review every new string that reaches the output.
- **Hash order.** Perl randomises it per process; an unsorted `keys` on the way to the output
  makes the picture, and the tests, flaky.
- **Stale `examples/demo.svg`.** It is committed and shown in the README; a change to the
  picture without regenerating it fails the suite.
- **Shared, memory-tight host.** loadguard refuses heavy commands (`prove`, `dzil`, new
  `claude -p`) under memory pressure. A refusal means wait and retry as its message says —
  never bypass it, never fan out parallel suite runs; a refused run is not a passed run.
  `loadguard status` shows why.
- **Comb gaps are tickets there.** A gap in `Kubernetes::Comb` (for example a field the picture
  needs and the CR does not carry) is a ticket on *that* repo's board (`../p5-kubernetes-comb`),
  never a workaround here.

## Perl specifics — reference, don't restate

Architecture and invariants: skill `kubernetes-comb-svg-core`. House style, module loading,
pinning: `getty-perl-core`, `getty-perl-moo`; POD: `getty-perl-pod`; release:
`getty-perl-release-author-getty`, `perl-release-dist-ini`. Force-loaded for the
`kubernetes-comb-svg-*` agents.

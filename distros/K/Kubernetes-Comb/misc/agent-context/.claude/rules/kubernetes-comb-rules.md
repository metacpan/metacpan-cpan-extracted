# Kubernetes::Comb House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

A self-contained micro collection of Kubernetes parts as a live Perl instance. Read first: the
`SPEC.md` section, then the base class `lib/Kubernetes/Comb.pm` and the client seam.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `kubernetes-comb-worker` (default) |
| Write/extend tests, grow the `t/lib/` fake client | `kubernetes-comb-test-writer` |
| POD in the house format (`=attr`/`=method`) | `kubernetes-comb-pod-writer` |
| Commits, packaging (`dist.ini`, `Changes`, `LICENSE`, CI, `.gitignore`), card → done, pre-release audit | `kubernetes-comb-release-manager` |
| Read-only research, audit, gap analysis | `kubernetes-comb-worker` ("read-only, change nothing") |

Behavior-relevant = anything under `lib/`, `t/`, `examples/`: lifecycle and reconcile, upstream
resolution, bridge, stubs, CR classes, clients, error and Future semantics. Packaging files
belong to the release-manager; `cpanfile` lines arrive with the code that needs them. The main
agent edits `SPEC.md`/`CLAUDE.md` prose only with the maintainer: `SPEC.md` changes are design
changes — the maintainer's call.

## Hazards — what actually goes wrong here

- **Integration tests mutate a real cluster.** With `TEST_KUBERNETES_COMB_KUBECONFIG` set,
  tests create and delete real resources in whatever cluster it points to. Never set it (or
  `TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT`) on your own initiative; unset, the suite is
  unit-only — always report which mode was green.
- **Shared, memory-tight host.** loadguard refuses heavy commands (`prove`, `dzil`, new
  `claude -p`) under memory pressure. A refusal means wait and retry as its message says —
  never bypass it, never fan out parallel suite runs; a refused run is not a passed run.
  `loadguard status` shows why.
- **Getty-dist version trap.** `IO::K8s`, `Kubernetes::REST`, `Net::Async::Kubernetes` repos
  run one version ahead of CPAN — pin `cpanfile` to the released version (rule in skill
  `getty-perl-core`).
- **Sibling gaps are tickets there.** A gap in `IO::K8s`, `Kubernetes::REST` or
  `Net::Async::Kubernetes` is a ticket on *that* repo's board, never a workaround here.

## Perl specifics — reference, don't restate

Architecture and invariants: skill `kubernetes-comb-core`. House style, module loading,
pinning: `getty-perl-core`, `getty-perl-moo`. Futures: `perl-io-async-future`. K8s API:
`perl-kubernetes-rest`, `perl-io-k8s-kubernetes-classes`. POD: `getty-perl-pod`. Release:
`getty-perl-release-author-getty`, `perl-release-dist-ini`. All force-loaded for
`kubernetes-comb-*` agents.

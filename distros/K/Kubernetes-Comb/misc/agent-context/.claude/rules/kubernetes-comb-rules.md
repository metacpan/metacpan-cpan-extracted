# Kubernetes::Comb House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Present alternatives when ambiguous. Push back when a simpler approach exists.
2. **Simplicity first** — Minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — Touch only what you must. Match existing style.
4. **Goal-driven execution** — Define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — pick one, say why, flag the other.
6. **Read before you write** — `SPEC.md` section first, then the base class
   `lib/Kubernetes/Comb.pm` and the client seam. "Looks orthogonal" is dangerous.
7. **Tests verify intent** — reproduce a bug before fixing it; leave a regression test.
8. **Checkpoint after every significant step** — done / verified / left.
9. **Fail loud** — "Tests pass" is wrong if any were skipped or the run was refused.
10. **A red test is a claim before it is a failure** — say what it asserts and whether
    your fix keeps that claim or replaces it.

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate to `kubernetes-comb-worker`. Your lane: coordinate, inspect,
  plan, review diffs, run tests, edit `SPEC.md`/`CLAUDE.md` prose with the maintainer.
  When in doubt, delegate. Why: only the `kubernetes-comb-*` agents get their skills
  force-loaded via `briefing.skills`; you would touch internals with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `kubernetes-comb-worker` (default) |
  | Write/extend tests, grow the `t/lib/` fake client | `kubernetes-comb-test-writer` |
  | POD in the house format (`=attr`/`=method`) | `kubernetes-comb-pod-writer` |
  | Commits, packaging (`dist.ini`, `Changes`, `LICENSE`, CI, `.gitignore`), card → done, pre-release audit | `kubernetes-comb-release-manager` |

  **Only `kubernetes-comb-release-manager` commits.** A worker hands its card to
  `review` and reports; you then dispatch the release-manager to cut the commit.

- **You cannot spawn subagents** (you ARE a `kubernetes-comb-*` agent): the delegation
  lock does not apply to you — work per these rules.

Behavior-relevant = anything under `lib/`, `t/`, `examples/`: lifecycle and reconcile,
upstream resolution, bridge, stubs, CR classes, clients, error and Future semantics.
Packaging files belong to the release-manager; `cpanfile` lines arrive with the code that
needs them. `SPEC.md` changes are design changes — the maintainer's call.

## Coordination — karr board (always in scope)

`karr` is always in scope — just use it (full surface: skill
`kanban-issues-karr-coordination`). State lives in `refs/karr/*`; this repo has its own
board. `karr list --compact` / `karr board` · `karr show ID` · `karr create "Title"
--priority high --tags a,b --body '…'` · `karr edit ID -a "note"` · `karr move ID
in-progress --claim NAME` · `karr handoff ID --claim NAME --note "…"`.

Card life cycle: you claim and hand out → the worker notes and ends at `review` → the
release-manager commits and moves it to `done`. A gap in `IO::K8s`, `Kubernetes::REST`
or `Net::Async::Kubernetes` is a ticket on *that* repo's board, never a workaround here.

**Serialize board mutations when fanning out** — parallel work is fine, but loop
`karr move`/`handoff`/`sync` sequentially afterwards.

## Release — never without permission

`dzil build` / `dzil test` / `prove` are fine anytime. `dzil release` and any CPAN upload
are STRICTLY forbidden without the maintainer's explicit go-ahead — even if a plan lists
"release" as the next step. Stop and ask.

## Hazards — what actually goes wrong here

- **Integration tests mutate a real cluster.** With `TEST_KUBERNETES_COMB_KUBECONFIG`
  set, tests create and delete real resources in whatever cluster it points to. Never
  set it (or `TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT`) on your own initiative; unset, the
  suite is unit-only — always report which mode was green.
- **Shared, memory-tight host.** loadguard refuses heavy commands (`prove`, `dzil`,
  new `claude -p`) under memory pressure. A refusal means wait and retry as its message
  says — never bypass it, never fan out parallel suite runs. `loadguard status` shows why.
- **Getty-dist version trap.** `IO::K8s`, `Kubernetes::REST`, `Net::Async::Kubernetes`
  repos run one version ahead of CPAN — pin `cpanfile` to the released version (rule in
  skill `getty-perl-core`).

## Perl specifics — reference, don't restate

Architecture and invariants: skill `kubernetes-comb-core`. House style, module loading,
pinning: `getty-perl-core`, `getty-perl-moo`. Futures: `perl-io-async-future`. K8s API:
`perl-kubernetes-rest`, `perl-io-k8s-kubernetes-classes`. POD: `getty-perl-pod`.
Release: `getty-perl-release-author-getty`, `perl-release-dist-ini`. All force-loaded
for `kubernetes-comb-*` agents — do not duplicate here.

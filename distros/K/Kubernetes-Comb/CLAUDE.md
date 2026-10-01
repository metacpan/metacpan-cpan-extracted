# CLAUDE.md

## Project

**Kubernetes::Comb** — a Comb is a self-contained "micro collection of Kubernetes
parts" that runs as a live Perl instance: it deploys itself, reports its status,
publishes its endpoints, and can borrow its service from an upstream layer
(`getty → dev → prod`) or be replaced by a stub.

The full, approved design is in `SPEC.md` — read it before changing anything.
An open-source CPAN distribution: no site-specific policy (no namespace
conventions, no secret-store integration, no fixed labels or API group) — all of
that is configuration or a subclass.

## Build

Dist::Zilla with `[@Author::GETTY]`, dependencies in `cpanfile`.

```bash
prove -lr t/        # unit tests, no cluster needed
dzil test
```

Integration tests only run with `TEST_KUBERNETES_COMB_KUBECONFIG` set — never
read production env vars in tests.

## Invariants

- **The Comb instance is the boundary.** Controlling code calls Comb methods only;
  all Kubernetes work lives inside the Comb class.
- **Every lifecycle method returns a `Future`.** Sync client → already-done Futures.
  `Future` is the only hard async dependency; `IO::Async`,
  `Net::Async::Kubernetes`, `Future::AsyncAwait` are *recommends*. No `async sub`
  in core code.
- **No manager/daemon in this dist.** `examples/*.pl` show how to drive Combs.
- **No singleton registry.** Dependencies come through the injected `resolver`.
- **`reconcile` never dies** — errors become `phase: Error`.
- Upstream shortcuts (`K8s`, `+Class`) are Perl helpers only; the CR always holds
  the fully qualified class name.
- Never credentials in the CR — only kube context names.
- Bugs or missing features in `IO::K8s`, `Kubernetes::REST` or
  `Net::Async::Kubernetes` are fixed upstream, never worked around here.

## Conventions

- Moo. Inline POD per `[@Author::GETTY]` PodWeaver (`=attr`, `=method`,
  `=seealso`), `# ABSTRACT:` on every `.pm`.
- `use Module;` to load; `require` only for genuine runtime plugin loading
  (optional async client, upstream/stub classes from the CR).
- Default CR group `comb.internal/v1`, kind `Comb`, plural `combs`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
principle and lane are in `.claude/rules/kubernetes-comb-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `kubernetes-comb-worker` (default) |
| Write/extend tests, `t/lib/` fake client | `kubernetes-comb-test-writer` |
| POD in the house format | `kubernetes-comb-pod-writer` |
| Commits, packaging (`dist.ini`, `Changes`, `LICENSE`, CI), card → done, pre-release audit | `kubernetes-comb-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Architecture and invariants live in the
project skill `.claude/skills/kubernetes-comb-core/`; the shared house skills are
installed by skilletor from `.claude/skilletor.json` (gitignored build artifacts —
change them in their source repo, never here).

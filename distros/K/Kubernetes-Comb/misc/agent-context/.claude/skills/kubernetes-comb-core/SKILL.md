---
name: kubernetes-comb-core
description: Use before editing or testing Kubernetes::Comb — the Comb contract and lifecycle, reconcile, upstream/layering and the bridge, stubs, the Comb CR classes (Kubernetes::Comb::CRD::*), Client::Sync/Async, endpoints, the fake-client test harness.
---

# Kubernetes::Comb — core

`SPEC.md` is the approved design and the authority. This skill is the map and
the traps; before touching a building block, read its SPEC section (§ numbers
below). Code and SPEC disagree → stop and report it; the SPEC changes first,
with the maintainer, never silently in code.

## Vocabulary

| Term | Means |
|---|---|
| Comb | one live Perl instance managing a self-contained set of K8s parts; the boundary — callers use its methods only |
| contract | what a Comb class overrides: `name`, `depends_on`, `endpoints`, `manifests`, `check`, `bridge_manifests`, `stub_class`, optional `upstream` |
| lifecycle | `reconcile`, `status`, `healthy`, `logs`, `deploy`, `restart`, `stop`, `describe`, `endpoint($name)` — all return a `Future` |
| upstream | where a Comb borrows its service instead of running it (§5) — a **state** of the instance, not a subclass |
| stub | a **subclass** that keeps the contract and swaps the implementation (§9) |
| bridge | the local Service a borrowing Comb creates so consumers keep using `name:port` (§7) |
| resolver | injected coderef `name → Comb instance`; the only dependency lookup |
| manager | the caller that watches CRs and drives `reconcile` — documented and shown in `examples/`, never shipped (§11) |

## Module map (§3)

`lib/Kubernetes/Comb.pm` base class · `Comb/Client/{Sync,Async}.pm` ·
`Comb/Endpoint.pm` value object · `Comb/Role/Upstream.pm` ·
`Comb/Upstream/{K8s,Static}.pm` · `Comb/Static.pm` (manifests from
`.pk8s`/YAML) · `Comb/CRD/*` (IO::K8s classes: Comb, CombSpec, CombStatus,
CombCondition, CombResource, CombEndpoint, CombUpstreamStatus) ·
`examples/{sync,async}.pl` · `t/lib/` fake client.

## Futures — one error path

- Every lifecycle method returns a `Future`; `Client::Sync` returns
  already-done ones, so `$comb->status->get` never waits on a loop.
- A method that returns a Future never throws: wrap sync work so an exception
  becomes a failed Future. A `die` before the first Future exists escapes every
  `->else` downstream.
- Plain `->then`/`->else` chains in `lib/`; `async sub` only in user code and
  examples, so `Future::AsyncAwait` stays a recommend.
- `Client::Async` loads `IO::Async` and `Net::Async::Kubernetes` with `require`
  at runtime and dies naming the missing module. That, the upstream class from
  the CR and the stub class are the only `require`s; everything else is `use`.

## reconcile — one step, never fails (§7)

Order: resolve upstream → enabled? (`Disabled`) → dependencies healthy via
resolver? (`Blocked`) → `check` hook (`NeedsConfig`) → local path (healthy →
`Running`, else deploy + prune → `Pending`) or upstream path (upstream
status/endpoints, optional `replicate_into`, bridge deploy + prune; bridge ok
and upstream `Running` → `Running`) → write status.

- Any failure anywhere becomes `phase: Error` with a message — the returned
  Future is always done, never failed.
- Pruning diffs the fresh manifest set against `status.managedResources`: an
  orphan is something this Comb recorded and no longer renders.
- With a CR the status goes through `update_status`; without one it stays in
  memory. Same code path otherwise.

## Upstream resolution (§5) — "exists", not "true"

First source that **exists** decides, and its answer is final even if it is
"local": constructor coderef → CR `spec.upstream` → class `upstream` method →
local. Test with `exists`, not truthiness: `spec.upstream: null` is an explicit
"local" that stops the lookup; an empty return from coderef or method is also
"local".

- `K8s => (...)` and `'+Full::Class' => (...)` are Perl-side shortcuts only;
  whatever is written into the CR carries the fully qualified class name.
- The CR names a kube **context**, never credentials.
- `Upstream::K8s` is read-only on the peer Comb CR. Missing or inaccessible
  context → `reachable: false` → this Comb goes `Blocked` with the reason; it
  is not an exception.
- The upstream picks the reachable address: same API server → `cluster`,
  otherwise `external`; none reachable → unreachable. Chains work because each
  Comb publishes already-resolved endpoints in `status.endpoints` (`via` lists
  the layers).

## Bridge

Per endpoint, the Service that would exist locally, pointing at the upstream:
hostname → `type: ExternalName`; IP → selector-less Service + EndpointSlice.
`bridge_manifests` is an ordinary overridable method.

## Stubs (§9)

`stub_class` defaults to `"${class}::Stub"` if it loads. The contract check
runs at construction: a stub lacking any endpoint name of its original dies
immediately, naming the missing endpoints. A stub normally has no upstream.

## The CR (§6)

Default group `comb.internal/v1`, kind `Comb`, plural `combs`, namespaced,
status subresource. IO::K8s fixes `api_version` at `use` time, so another group
means a user subclass of the CR class passed as `crd_class` — never a runtime
group switch. The CustomResourceDefinition comes from a method taking `group`
and returning an IO::K8s object, not a shipped YAML file.

## No site policy

An open-source dist: label prefix, namespace and API group are configuration,
secrets belong to the Comb class or its `config`. Anything a particular site
wants on top — naming schemes, a secret store, fixed labels — is a subclass or
the `check` hook, never core code.

## Upstream bugs stay upstream

A gap in `IO::K8s`, `Kubernetes::REST` or `Net::Async::Kubernetes` (for example
a missing `update_status`, `ensure`, client-cert verification) is fixed in that
repo — record it as a ticket for that repo's board and stop at the gap. No
shim, subclass or monkeypatch here.

## Tests (§12)

- Unit tests need no cluster: the fake client in `t/lib/` records `ensure`
  calls and returns canned pods/CRs. Every `reconcile` transition gets a test
  (Disabled, Blocked, NeedsConfig, Pending, Running, Error, pruning).
- `Upstream::Static` covers replica, bridge and multi-level `via` chains
  without a second cluster; the stub contract check has its own test.
- Integration runs only with `TEST_KUBERNETES_COMB_KUBECONFIG` (plus
  `TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT` for upstream tests) and mutates that
  cluster.

## Open design points

SPEC §14 lists decisions not yet made. Meeting one during implementation →
surface it with a proposal; the maintainer decides.

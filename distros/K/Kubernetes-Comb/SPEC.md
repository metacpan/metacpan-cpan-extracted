# Kubernetes::Comb — Design Spec

Status: approved design (2026-09-26), implemented for 0.001 (2026-09-27).
Where the implementation settled a point the design left open, the section
says so; the module POD is the reference for the API.

## 1. Idea

A **Comb** is one cell of a honeycomb: a named, self-contained
"micro collection of Kubernetes parts" (Deployments, Services, ConfigMaps, …)
that knows how to deploy itself, what it offers, what it needs, and how to
answer "are you running?", "show me your logs".

Every Comb is a **live Perl instance**. Whoever manages Combs sees a `Comb`
custom resource in the cluster, builds the Comb instance from it and from then
on only talks to the instance. All Kubernetes work happens inside the Comb
class — the managing code never touches Kubernetes objects itself.

On top of that, Combs can be **layered**: a developer runs only the Comb they
work on and borrows every other Comb from another environment (dev, prod, …),
or replaces it with a small **stub**. Layers chain: `getty → dev → prod`.

## 2. Goals and non-goals

Goals:

- A Comb is extremely self-contained. It works alone in a test, without a
  registry singleton, without a manager, without a specific event loop.
- One API, usable fully synchronous or fully async.
- Default path is Kubernetes; Docker or plain-process setups are possible
  "on your own terms" by consuming resolved endpoints.
- Layering (upstream) and stubs are first-class, but every piece of policy is
  overridable per Comb class or per controlling script.
- No site-specific policy: no namespace conventions, no secret-store
  integration, no fixed labels or API group.

Non-goals (deliberately left open, must not be designed out):

- **No manager/controller daemon.** The dist documents what a manager must
  do; `examples/*.pl` demonstrate it. Users drive Combs from their own
  (async) environment.
- **No intercept** (Telepresence-style redirection of upstream traffic into a
  dev instance). Traffic only flows consumer → provider. An intercept could
  later be a separate upstream/bridge type.
- **No Docker runtime.** Only resolved endpoints are exposed for outside
  consumers.
- No per-service replication helpers (DB snapshot, S3 mirror, …) in the core;
  only the hook for them.
- No port-forward helper in the core (possible later, via
  `Net::Async::Kubernetes->port_forward`).

## 3. Building blocks

```
Kubernetes::Comb                    base class: contract + lifecycle, returns Futures
  contract (overridden in subclasses)
    name, depends_on, endpoints, manifests, check, optional,
    bridge_manifests, stub_class
    upstream (optional plain method)
  lifecycle
    reconcile, status, healthy, logs, deploy, restart, stop, describe
    endpoint($name)                 address, redirected when an upstream is active
  attributes
    k8s        Kubernetes::Comb::Client::{Sync,Async}   default: Sync
    resolver   coderef: name → Comb instance (dependency lookup)
    upstream   coderef or spec, see §5
    crd        the Comb custom resource object (optional)
    crd_class  CR class, default Kubernetes::Comb::CRD::Comb
    namespace, config               default: from the CR
    label_prefix, managed_by        the labels of §7, default comb.internal/
    max_upstream_depth              cap on an upstream chain, see §5
    cluster_domain, io_k8s

Kubernetes::Comb::Role::Client      the request surface every Comb goes through
Kubernetes::Comb::Client::Sync      wraps Kubernetes::REST, returns done Futures
Kubernetes::Comb::Client::Async     wraps Net::Async::Kubernetes (optional deps)
Kubernetes::Comb::Endpoint          value object: name, protocol, port, cluster, external
Kubernetes::Comb::Role::Upstream    requires status, endpoints; optional replicate_into
Kubernetes::Comb::Upstream::K8s     read-only: reads the peer Comb CR in another kube context
Kubernetes::Comb::Upstream::Static  fixed endpoints, no cluster (Docker, vendors, tests)
Kubernetes::Comb::Static            optional: manifests loaded from .pk8s / YAML files
Kubernetes::Comb::Role::Static      the same as a role, for the stub of an existing class
Kubernetes::Comb::CRD::*            IO::K8s classes: Comb, CombSpec, CombStatus,
                                    CombCondition, CombResource, CombEndpoint,
                                    CombUpstreamStatus
examples/sync.pl, examples/async.pl
```

Rules:

- **The instance is the boundary.** Controlling code calls Comb methods only.
- **Mode is state, not class hierarchy.** A replicated Comb is the same class
  with an active upstream. A stub is a subclass fulfilling the same contract.
- **No singleton registry.** Dependencies are looked up through the injected
  `resolver` coderef, supplied by the controlling code.

## 4. Sync and async

- Every lifecycle method returns a `Future`.
- `Client::Sync` (default) uses `Kubernetes::REST`; its Futures are already
  done, so `->get` never waits on a loop. Fully synchronous use is just
  `$comb->status->get`.
- `Client::Async` uses `Net::Async::Kubernetes` on an `IO::Async` loop.
- Hard dependency: `Future` only. `IO::Async`, `Net::Async::Kubernetes` and
  `Future::AsyncAwait` are **recommends**. `Client::Async` loads them at
  runtime and dies with a clear message naming the missing module.
- Core code uses plain `->then` chains, no `async sub`, so
  `Future::AsyncAwait` stays optional. User Comb classes may use it freely.
- Missing features in `Net::Async::Kubernetes` are fixed
  **upstream in Net::Async::Kubernetes**, never worked around in this dist.
  `update_status`, `patch_status` and `ensure` arrived there with 0.009,
  which is the version `Client::Async` needs.

## 5. Upstream (layering)

An upstream is where a Comb borrows its service from instead of running it.

### Resolution

The effective upstream is resolved in this order. The first source that
**exists** decides — its answer is final, even if that answer is "local":

1. **Controlling code** — `upstream => sub { my ($comb) = @_; ... }` passed
   to the constructor / `from_crd`. This is where layers live: plain code in
   the controlling script.
2. **Custom resource** — `spec.upstream`.
3. **Class** — an optional plain method `sub upstream { ... }` in the Comb
   class (general case, e.g. "GeoIP always comes from the vendor").
4. **Nothing** — the Comb runs locally.

"Exists" means: the coderef was passed; the CR has a `spec.upstream` key
(an explicit `null` means local); the class has an `upstream` method. An empty
return from the coderef or the class method means "local".

Stub and upstream are independent: a stub is a class choice (§9), the upstream
is resolved on whatever instance was built. A stub normally has no upstream.

### Return values (Perl helpers)

```perl
return;                                             # local
return K8s => (context => 'dev', namespace => 'platform');
                                  # Kubernetes::Comb::Upstream::K8s->new(...)
return '+MyApp::Upstream::Catalog' => (url => ...); # '+' = full class name
return $object;                                     # anything doing Role::Upstream
```

The short names (`K8s`, `+Foo`) are **Perl code helpers only**. In the custom
resource the class is always the fully qualified name:

```yaml
upstream: { class: Kubernetes::Comb::Upstream::K8s, context: dev, namespace: platform }
```

### Role::Upstream

```perl
requires 'status';     # Future → { reachable, phase, via => [...], ... }
requires 'endpoints';  # Future → [ Kubernetes::Comb::Endpoint, ... ]
# optional: replicate_into($comb) — data/snapshot replication, class-specific
```

- `Upstream::K8s` reads the peer Comb CR **read-only** (RBAC:
  `get/list/watch combs` is enough). The CR only names the kube context;
  credentials live locally with whoever runs the Comb.
- If the context is missing or not accessible, that is not an error of the
  dist — the upstream reports `reachable: false` and the Comb goes `Blocked`
  with the reason.
- Because every Comb publishes its **already resolved** endpoints in
  `status.endpoints`, chains of any depth work without a layer knowing the
  one above its upstream.
- A chain whose `via` names more than `max_upstream_depth` layers (default
  16) is taken for a loop: `Blocked`, the recorded `via` cut to that length.
  Kube context names cannot tell a loop, since layers may share one context
  (namespaces of one cluster).

## 6. Custom resource

Default group `comb.internal/v1` (`.internal` is reserved by ICANN for private
use, so it never collides with a real domain). Kind `Comb`, plural `combs`,
namespaced, with the status subresource.

```yaml
apiVersion: comb.internal/v1
kind: Comb
metadata: { name: nats, namespace: platform }
spec:
  class: MyApp::Comb::NATS          # Perl class; a stub is just another class
  dependsOn: [db]                   # "name" or "namespace/name"
  config: { ... }                   # free-form config for the class
  enabled: true                     # undef = auto, false = off, true = on
  upstream:                         # optional
    class: Kubernetes::Comb::Upstream::K8s
    context: dev
    namespace: platform             # default: same namespace
    name: nats                      # default: same name
status:
  phase: Running                    # Running | Pending | Blocked | NeedsConfig |
                                    # Disabled | Error | Stopped | NotDeployed
  conditions: [ { type, status, reason, message, lastTransitionTime } ]
  managedResources: [ { apiVersion, kind, namespace, name } ]
  endpoints:
    - { name: client, protocol: tcp, port: 4222,
        cluster: nats.platform.svc:4222, external: nats.example.com:4222 }
  upstream:                         # only when an upstream is active
    class: Kubernetes::Comb::Upstream::K8s
    context: dev
    reachable: true
    phase: Running
    via: [dev, prod]
    observedAt: 2026-09-26T12:00:00Z
  observedGeneration: 3
```

- Never any credentials in the CR.
- A different API group: IO::K8s fixes `api_version` at `use` time, so a user
  writes a three-line subclass of the CR class and passes it as `crd_class`.
- The CustomResourceDefinition itself is produced by a method taking `group`
  as a parameter (returns an IO::K8s `CustomResourceDefinition` object), not
  shipped as a fixed YAML file.
- Secrets are not part of the CR schema: they belong to the class / `config`.
  A subclass that needs a secret store wires it in through the `check` hook.

## 7. Lifecycle: `reconcile`

`$comb->reconcile` performs **one step** and returns a Future of the new
status. It **never fails**: any error becomes `phase: Error` with a message.
The Comb writes its own status into its CR (`update_status`); without a CR the
status lives only in memory.

```
1. resolve upstream            controlling code > CR > class > local
2. enabled?                    no → Disabled
3. dependencies                via resolver: all healthy? no → Blocked
4. check (hook)                class reports missing prerequisites → NeedsConfig
5a. local                      healthy and applied as rendered? → Running
                               else manifests → deploy → prune orphans
                               (diff against status.managedResources) → Pending
5b. upstream                   upstream->status + upstream->endpoints
                               optional upstream->replicate_into($self)
                               bridge_manifests → deploy → prune
                               bridge ok AND upstream Running → Running
6. write status                phase, conditions, endpoints, upstream, managedResources
```

### The bridge

For each endpoint, the Comb creates in its own namespace **the Service that
would exist locally** (e.g. `nats`), pointing at the upstream:

- hostname → Service `type: ExternalName`
- IP → selector-less Service + EndpointSlice

Consumers in the cluster keep talking to `nats:4222` and transparently reach
dev or prod. `bridge_manifests` is a normal method; classes override it when
their service needs more.

**The upstream decides which address is reachable.** `Upstream::K8s` returns
the cluster address when both kube contexts point at the same API server,
otherwise the `external` address. No reachable address → upstream counts as
unreachable → `Blocked` with the reason.

### Deploy details

- Every managed resource gets identifying labels (configurable prefix):
  the Comb name, the Comb namespace and `app.kubernetes.io/managed-by`. Name
  and namespace together tell same-named Combs of different namespaces
  apart -- the layers of one cluster.
- Pruning deletes only namespaced resources that still carry both labels of
  this Comb. A cluster-scoped orphan (a Namespace, a
  CustomResourceDefinition) is never deleted: it is dropped from the record,
  left in place, and the status message says so.
- **Applied digest.** `deploy` puts an annotation on every resource
  (`<prefix>applied-digest`) holding a digest of the manifest as the Comb
  rendered it. `reconcile` compares it with the digest of what the Comb
  renders now: a healthy Comb with a resource whose digest differs, or that
  carries none, is deployed again and is `Pending` until the next step finds
  it healthy. So a new image in the Comb class and a changed `spec.config`
  both reach the cluster, without the manager calling `deploy`.
  - The digest is of the rendered manifest, never of the live object: what
    the API server defaults or a controller writes does not count as a
    change, and neither does the restart annotation.
  - A change made to the live object by hand is not detected; only what the
    Comb renders is compared.
  - A resource the client does not replace once it exists (a
    PersistentVolumeClaim, a Job that runs or has succeeded) keeps the digest
    it was created with and never triggers a deploy by it.
  - A resource that a same-named Comb of another namespace applied last
    (it carries that Comb's namespace label) never triggers a deploy by its
    digest -- the same ownership rule as pruning. Counted, both Combs would
    deploy it back and forth every step.
- `status` is derived from pods: Waiting/Terminated reasons, restart counts,
  scheduling failures (`PodScheduled=False`) end up in conditions/messages.
- `logs` falls back to the previous container on CrashLoop.
- `restart`: rolling restart via pod template annotation; Jobs are deleted.
- `stop`: Deployments/StatefulSets to 0 replicas, CronJobs suspended, Jobs
  deleted.
- Namespace is taken from the CR / an attribute — no scope-string mapping.

## 8. Endpoints and outside consumers

- `endpoints` (class) declares what the Comb offers: name, protocol, port.
- `$comb->endpoint($name)` returns a `Kubernetes::Comb::Endpoint` with the
  resolved `cluster` and `external` addresses (redirected when an upstream is
  active).
- Docker / process consumers use these addresses. `examples/` shows writing
  them to an env file. Everything else is up to the user.

## 9. Stubs

A stub is a **subclass** that inherits the contract and swaps the
implementation:

```perl
package MyApp::Comb::Mailer::Stub;
use Moo; extends 'MyApp::Comb::Mailer';   # inherits endpoints → same contract
sub manifests { ... }                      # e.g. a Mailpit container
```

- `stub_class` defaults to `"${class}::Stub"` if that class loads; overridable.
- Selected by the controlling code
  (`from_crd($crd, stub => sub { $_[0]->name eq 'mailer' })`) or by pointing
  `spec.class` at the stub class.
- **The contract is checked at construction**: a stub missing any endpoint
  name of its original dies immediately with a clear message. That holds
  however the stub was selected: a class named `Foo::Stub` that is a `Foo`
  is checked against `Foo` when `spec.class` names it directly, too.
- Stubs are often just a `.pk8s` file via `Kubernetes::Comb::Static`.

## 10. Manifests

- `manifests` returns IO::K8s objects or hashrefs.
- `Kubernetes::Comb::Static` loads manifests from `.pk8s` (IO::K8s Perl DSL)
  or YAML files via `IO::K8s->load` / `load_yaml`, e.g. from the share dir of
  a Comb distribution.
- IO::K8s roles/classes (`Routable`, `CertManaged`, `NetworkPolicy`,
  GatewayAPI, CertManager, …) may be used inside Comb classes; the core does
  not depend on them.

## 11. What a manager must do (documented, not shipped)

1. Watch/list `Comb` CRs.
2. Build instances via `Kubernetes::Comb->from_crd($crd, %opts)` — `%opts`
   carries `k8s`, `resolver`, `upstream`, `stub`.
3. Order by `depends_on` (topological sort, cycle detection).
4. Call `reconcile` per Comb, repeatedly (timer and/or on CR change).
5. Show/act on status; call `restart`, `stop`, `logs` on request.

`examples/sync.pl` and `examples/async.pl` do exactly this for three Combs —
**nats** local, **db** replicated (`Upstream::Static` or `Upstream::K8s`),
**mailer** as stub — and print every state transition.

## 12. Testing

- Unit tests need no cluster: a fake client in `t/lib/` records `ensure`
  calls and returns canned pods/CRs. Every `reconcile` transition is covered
  (Disabled, Blocked, NeedsConfig, Pending, Running, Error, pruning).
- `Upstream::Static` enables replica and bridge tests, including multi-level
  chains (`via`), without a second cluster.
- Stub contract check has its own test.
- Integration tests run only with `TEST_KUBERNETES_COMB_KUBECONFIG`
  (and `TEST_KUBERNETES_COMB_UPSTREAM_CONTEXT` for upstream tests).

## 13. Dependencies

`cpanfile` is the reference; it names released versions only.

- requires: `Moo`, `Future`, `IO::K8s` (>= 1.109, quotes YAML 1.1
  booleans in `to_yaml`), `Kubernetes::REST` (>= 1.109, has
  `update_status`/`patch_status`/`ensure` and `delete` with
  `propagationPolicy`), `Module::Runtime`,
  `JSON::MaybeXS`, `Path::Tiny`, `Types::Standard` and
  `Types::Common::Numeric` (Type::Tiny), `namespace::autoclean`
- recommends: `IO::Async`, `Net::Async::Kubernetes` (>= 0.009),
  `Future::AsyncAwait`
- test: `Test::More`

## 14. Open points

Settled by the implementation:

- Label key prefix: `comb.internal/`, the attribute `label_prefix`.
- The client is a role, `Kubernetes::Comb::Role::Client`, plus the two
  classes.
- `update_status`, `patch_status` and `ensure` are in
  `Net::Async::Kubernetes` 0.009.
- `delete` takes `propagationPolicy` in `Kubernetes::REST` 1.109 and
  `Net::Async::Kubernetes` 0.009: `restart`, `stop` and pruning delete with
  `Background`, so the Pods of a Job go with it.

Decided after the first implementation (2026-09-29):

- `reconcile` deploys a healthy Comb again when what it renders changed,
  told by a digest per resource (§7). `metadata.generation` against
  `status.observedGeneration` was the alternative; it would miss a new
  version of the Comb class with the custom resource untouched.

Open:

- A stub selected through `spec.class` is checked against its original but
  has no `stub_of`; whether it should.

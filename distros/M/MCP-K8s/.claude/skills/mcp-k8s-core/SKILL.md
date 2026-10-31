---
name: mcp-k8s-core
description: Load before editing p5-mcp-k8s — the RBAC-aware stdio MCP server, SelfSubjectRulesReview discovery, the generic tools, resource plural lookup, the auth tiers.
user-invocable: false
model: inherit
---

# mcp-k8s-core

MCP::K8s is a stdio MCP server that gives an LLM access to a Kubernetes cluster.
The core of the idea: **RBAC is the only authorization layer.** The server
asks the cluster via `SelfSubjectRulesReview` what the connected ServiceAccount may do,
and shapes the tool descriptions from that. There is **no** application-side
permission filtering — whatever RBAC allows, the LLM may do.

Here are the architecture and the rules; the reasons and prohibitions sit alongside in `mcp-k8s-hazards`.

## Vocabulary

| Term | Meaning |
|---|---|
| **tool** | One of the 10 MCP tools (`k8s_list`, `k8s_get`, …), registered in `_register_tools` |
| **discovery** | `SelfSubjectRulesReview` per namespace → internal permission map. Lazy, not at `new` |
| **plural** | RBAC name of a resource (`Pod` → `pods`). RBAC speaks only plural, the API speaks kind |
| **verb** | RBAC verb (`list`, `get`, `create`, `patch`, `delete`) — the key of every check |
| **cluster scope** | Namespace `''` — its own row in the permission map, its own discovery call |
| **desc map** | `_tool_desc_map`: `[$tool, $base_description, $verb]` per tool, for rewriting the descriptions afterwards |

## Layer Map

```
bin/mcp-k8s                   # Entry point: MCP::K8s->run_stdio
lib/MCP/K8s.pm                # Server (extends MCP::Server), Tools, Formatting, Auth, Plurals
lib/MCP/K8s/Permissions.pm    # RBAC discovery + can_do/allowed_* /summary
lib/MCP/Kubernetes.pm         # Empty subclass of MCP::K8s, only for CPAN discoverability
examples/*.yaml               # RBAC examples (readonly / deployer / full-ops)
examples/raider-configmap-demo.pl  # Live demo with Langertha::Raider
```

`MCP::K8s` **inherits** from `MCP::Server` (since 0.002); it no longer composes it.
`sub server { $_[0] }` exists only as backward compatibility for code that passes
`$k8s->server` to `Net::Async::MCP` — the documented Raider path in the README.

## Core invariants

- **Discovery is lazy, and that is a promise.** `BUILD` only registers tools;
  the first RBAC call happens in `ensure_discovered`, triggered by a
  tool call or `run_stdio`. That makes `MCP::K8s->new` constructible without a cluster,
  which half the test suite relies on. Don't move anything into `BUILD` that touches `->api`.
- **Every tool call checks `can_do` first.** No tool calls the API without a
  prior permission check. Reason: `mcp-k8s-hazards`.
- **`can_do` matches on the plural, not on the kind**, and all four wildcard branches
  (explicit verb, wildcard verb on the resource, wildcard resource with verb, `*`/`*`)
  are live. Whoever calls `can_do('list', 'Pod')` silently gets `0` — always
  `_resource_plural` first.
- **Per-namespace discovery errors are not fatal.** An unreachable namespace
  is warned about and skipped, the others are discovered anyway. That also
  applies to the cluster-scope call.
- **Tool descriptions are rewritten afterwards**, exactly once, in
  `_update_tool_descriptions` (guard: `_descriptions_updated`). They hang off
  `_tool_desc_map`; a newly registered tool without an entry there keeps its
  static description forever. They are part of the functionality, not cosmetics.

## Resource plurals — 4-Tier Lookup

`_resource_plural($kind)`, in this order:

1. **Static `%RESOURCE_PLURALS` map** — fast, no I/O
2. **`IO::K8s` class** via `expand_class` + `resource_plural()` — covers CRD classes
3. **API discovery** (`/api/v1` and `/apis` + `/apis/$groupVersion`), cached once
   in `_resource_plurals_cache`. Subresources (`name` contains `/`) are
   skipped
4. **Heuristic** — lowercase, append `s`, `ys` → `ies`

Tier 3 silently swallows all errors: if discovery fails, the cache stays empty
and tier 4 takes over. The price: a wrong pluralization looks like a
permission denied — on a "Permission denied" that should not happen, always check the
plural first. CRD support depends on tiers 2+3; that is exactly why Cilium & co. work without
configuration.

## Auth — 3-Tier, in this order

| Tier | Trigger | Endpoint |
|---|---|---|
| 1 | `MCP_K8S_TOKEN` set | `MCP_K8S_SERVER`, otherwise in-cluster default |
| 2 | `/var/run/secrets/kubernetes.io/serviceaccount/token` exists | same |
| 3 | Fallback | `Kubernetes::REST::Kubeconfig` with `MCP_K8S_CONTEXT` |

Tiers 1 and 2 attach `ssl_ca_file` **when** the in-cluster CA file exists — even
with an explicit token. The paths are file-scoped `my` variables in `MCP/K8s.pm`; tests
have to force them via the filesystem or via attributes.

## Namespaces

`_build_namespaces`: `MCP_K8S_NAMESPACES` → in-cluster namespace file (then an attempt to list
all, with the mounted one as fallback) → auto-discovery via `list('Namespace')` →
`['default']`. Every API use in there is wrapped in `eval`; there is no path on
which `_build_namespaces` dies.

`_resolve_namespace` fills in the namespace only when exactly one namespace is reachable,
otherwise `undef` — the tool has to handle the case itself. Reason: `mcp-k8s-hazards`.

## The 10 tools

`k8s_permissions` (always allowed, calls `summary`), `k8s_list`, `k8s_get`, `k8s_create`,
`k8s_patch`, `k8s_delete`, `k8s_logs`, `k8s_events`, `k8s_rollout_restart`, `k8s_apply`.

- **`k8s_rollout_restart`** patches the pod template annotation
  `kubectl.kubernetes.io/restartedAt` with a timestamp — the same mechanism as
  `kubectl rollout restart`; it needs `patch`, not `update`.
- **`k8s_apply`** tries `create` and on 409/AlreadyExists falls back to a
  strategic merge patch. Error detection is a regex on
  `/409|AlreadyExists/i` against the error string — reason and limits: `mcp-k8s-hazards`.

**Why 10 generic tools instead of hundreds of specific ones:** Kubernetes has 50+ built-in types
plus arbitrary CRDs; generic tools with a `resource` parameter mirror `kubectl get <resource>`
and keep the tool list manageable for MCP clients. Adding a `list_pods` tool is
a change of direction, not a feature.

## Output format

`_format_resource_summary` deliberately returns a **compact** summary for the
LLM context (metadata, kind, status phase/replicas/conditions, containers/ports/type);
for everything else there is `k8s_get` with `output => 'json'|'yaml'`. Whoever bloats the summary
pays for it in every `k8s_list` with N items.

## Tests

Everything runs against hand-written mock packages in the respective test file (`MockK8sAPI`,
`MockSSRR`, `MockK8sObject`, …) — no test needs a cluster, and none may
need one. The mocks implement the surface `Kubernetes::REST` uses
(`new_object`, `create`, `list`, `get`, `delete`, `patch`, `expand_class`, `_request`).

| File | Covers |
|---|---|
| `t/00-load.t`, `t/06-kubernetes-alias.t` | Loadability of the three modules; `MCP::Kubernetes` is `MCP::K8s` |
| `t/01-permissions.t` | RBAC discovery, `can_do` wildcards, `allowed_*`, `summary` |
| `t/02-resource-plurals.t` | 4-tier pluralization |
| `t/03-namespace-resolution.t` | Auto-fill with exactly one namespace |
| `t/04-format-helpers.t` | Summary/list formatting |
| `t/05-server-tools.t` | Tool registration and execution incl. `force_409` path of `k8s_apply`, `k8s_patch` status path, `IO::K8s::Unstructured` |
| `t/07-auth-alternatives.t` | Token/in-cluster/kubeconfig tiers |
| `t/08-resource-discovery.t` | API discovery endpoints, subresource filter, tier 2 without a request |

`prove -l t/` is the run. The suite needs `Kubernetes::REST` and `IO::K8s`
installed — if they are missing, *all* files fail with exit 2 and no plan: an environment problem,
not a test failure.

## Env vars

| Variable | Default | Effect |
|---|---|---|
| `KUBECONFIG` | `~/.kube/config` | Kubeconfig path (tier 3) |
| `MCP_K8S_CONTEXT` | current-context | Kubeconfig context |
| `MCP_K8S_TOKEN` | — | Bearer token, enables auth tier 1 |
| `MCP_K8S_SERVER` | in-cluster default | API server URL |
| `MCP_K8S_NAMESPACES` | Auto-discovery | Comma-separated namespace list |

There are **no** command-line flags — configuration is entirely
env-based, so that it can be expressed in MCP client JSON. Reason: `mcp-k8s-hazards`.

## Conventions

POD consistently follows the declaration, not the other way round: `sub foo {` followed by
`=method foo` … `=cut`, then the body; `has bar => (…)` followed by `=attr bar`
… `=cut`. That is this distribution's `[@Author::GETTY]` style — don't move it
up. `$VERSION` is in all three modules and is maintained by the release bundle.
Release: `getty-perl-release-author-getty`, dist.ini: `perl-release-dist-ini`,
Moo: `getty-perl-moo`, MCP server: `perl-mcp`.

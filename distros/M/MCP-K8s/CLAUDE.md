# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

MCP::K8s is a stdio MCP server that gives an LLM access to a Kubernetes cluster.
The core of the idea: **RBAC is the only authorization layer.** On the first tool call
the server asks via `SelfSubjectRulesReview` what the connected ServiceAccount may do,
and shapes the tool descriptions from that. A read-only account gets read-only tools, a
cluster-admin gets everything. There is **no** application-side permission filtering —
whatever RBAC allows, the LLM may do.

On CPAN under two names: `MCP::K8s` (canonical) and `MCP::Kubernetes` (empty
subclass, only for discoverability).

## Project structure

```
p5-mcp-k8s/
├── bin/mcp-k8s                   # Entry point: MCP::K8s->run_stdio
├── lib/MCP/
│   ├── K8s.pm                    # Server (extends MCP::Server), Tools, Auth, Plurals, Formatting
│   ├── K8s/Permissions.pm        # RBAC discovery + can_do/allowed_*/summary
│   └── Kubernetes.pm             # Empty subclass, CPAN discoverability only
├── examples/                     # 3 RBAC manifests + Langertha::Raider demo
├── t/                            # Tests, all against inline mocks
└── dist.ini                      # [@Author::GETTY]
```

## Key Commands

```bash
prove -l t/                 # Tests
prove -l t/01-permissions.t # Single test
dzil build                  # Build the distribution
dzil test                   # Test with dzil
```

If **every** test file dies with exit 2 and "No plan found in TAP output", a
dependency is missing, not code: `perl -Ilib -MMCP::K8s -e1` shows which one, `cpanm --installdeps .`
installs it.

## Architecture

**MCP::K8s** (lib/MCP/K8s.pm) **inherits** from `MCP::Server` (since 0.002); it no longer
composes it. `sub server { $_[0] }` is backward compatibility for the documented
`Net::Async::MCP->new(server => $k8s->server)` path in the README — do not remove it.
The path is verified against MCP 0.15 + Net::Async::MCP 0.004; 0.003 fails on
the stateless revision 2026-07-28 (`-32602 Missing protocol version`). For a
finding at this spot, **check the installed Net::Async::MCP version first.**

**Discovery is lazy, and that is a promise.** `BUILD` only registers tools; the
first RBAC call happens in `ensure_discovered`, triggered by a tool call or
`run_stdio`. That makes `MCP::K8s->new` constructible without a cluster — which the
test suite and every embedding rely on. Don't move anything into `BUILD` that touches `->api`.

**Every tool call checks `can_do` first.** No tool calls the API without a prior
permission check, not even when the API would return 403 anyway. The check is what
gives the LLM a readable refusal instead of a stack trace.

**Tool descriptions are functionality, not cosmetics.** They are triggered via
`_tools` — the method inherited from `MCP::Server` that **every** transport goes through on
`tools/list` and `tools/call`. The override calls
`_update_tool_descriptions` and then delegates to `SUPER::_tools`, so that the list copy and
`emit('tools', ...)` don't drift apart. Up to 0.003 the call sat only in
`run_stdio`, so the README path via `Net::Async::MCP`, an embedded `to_stdio`
and the HTTP transport `to_action` delivered the static descriptions. Whoever moves the
call back into `run_stdio` breaks exactly these three paths without breaking a test
in `t/05` — except the one that drives `tools/list` through `handle`.
`_update_tool_descriptions` rewrites them exactly once (guard `_descriptions_updated`), along `_tool_desc_map`
(`[$tool, $base_desc, $verb]` per tool). Result: "List Kubernetes resources. Available:
default: pods, deployments; production: pods". With >10 resources it is truncated to 10 + `...`,
with a wildcard it says "all resources". A newly registered tool without an entry in
the map keeps its static description forever.

### The 10 tools

`k8s_permissions` (always allowed), `k8s_list`, `k8s_get`, `k8s_create`, `k8s_patch`,
`k8s_delete`, `k8s_logs`, `k8s_events`, `k8s_rollout_restart`, `k8s_apply` — all in
`_register_tools`. Three have peculiarities:

- **`k8s_patch`** takes an optional `subresource` parameter (`enum: ['status']`,
  plus a runtime check for clients that ignore the schema). With `status` the
  call goes to `patch_status()` instead of `patch()` and the patch type default flips to
  **merge** instead of strategic — custom resources answer a strategic merge with
  415. An explicitly passed `patch_type` wins. This is no convenience feature:
  without the subresource path the API server strips any status from a write to the
  main endpoint and **still answers 2xx** — the tool reported "patched" and nothing
  was stored. The RBAC gate checks `<plural>/status`, not `<plural>`; a
  main-endpoint patch does not give away a status write.

- **`k8s_rollout_restart`** patches the pod template annotation
  `kubectl.kubernetes.io/restartedAt` with a timestamp — the same mechanism as
  `kubectl rollout restart`. Needs `patch`, not `update`.
- **`k8s_apply`** tries `create` and on 409/AlreadyExists falls back to a
  strategic merge patch. Conflict detection sits in `_is_conflict_error`
  and decides via `Kubernetes::REST::APIError->is_conflict` (client 1.109
  throws typed errors). Only an error that is not an APIError object (a string
  from an older client/wrapper) falls back to the regex `/409|AlreadyExists/i`.

**Why 10 generic tools instead of hundreds of specific ones:** Kubernetes has 50+
built-in types plus arbitrary CRDs. Generic tools with a `resource` parameter mirror
`kubectl get <resource>` and keep the tool list manageable for MCP clients. Adding a
`list_pods` tool is a change of direction, not a feature.

### Resource Plurals — 4-Tier

RBAC speaks plural (`pods`), the API speaks kind (`Pod`). `_resource_plural`
translates: (1) static `%RESOURCE_PLURALS` map, (2) `IO::K8s` class via
`expand_class`+`resource_plural()`, (3) API discovery via `/api/v1` and `/apis`,
cached once, subresources (`name` contains `/`) skipped, (4) heuristic
(lowercase, `s`, `ys`→`ies`).

**Since 1.108, tier 2 answers every built-in kind.** IO::K8s 1.108 carries the
upstream plurals on the classes, and `Kubernetes::REST::expand_class` resolves names from the
built-in map without a request — also with `resource_map_from_cluster` (still
default 1). A guard in front of it, as up to 0.003, saves nothing anymore: right
after, the tool call itself calls `list/get/...($kind)` with the same `expand_class`. An unknown kind
costs the client an aggregated discovery (`GET /api`, `/apis`, no `/openapi/v2`
anymore) and ends up as `IO::K8s::Unstructured` or as a class name that cannot be loaded —
both without `resource_plural`, so on to tier 3. **CRDs without a class thus come
from tier 3**, CRD provider classes with their own `resource_plural` from tier 2. The
floors `IO::K8s`/`Kubernetes::REST` 1.108 in the cpanfile stand for exactly this
contract; `t/08` pins it against the real client (0 requests).

Since Kubernetes::REST 1.108 a CRD without a class comes back as `IO::K8s::Unstructured`
instead of failing: `output=json`/`yaml` are complete, the summary shows
only metadata and `kind` (no `spec`/`status` accessor).

Tier 3 silently swallows all errors — on purpose, so that a cluster without discovery rights
does not kill the server. The price: **a wrong pluralization looks like a
permission denied.** On an unexpected "Permission denied", always check the plural
first.

### Auth — 3-Tier

| Tier | Trigger | Endpoint |
|---|---|---|
| 1 | `MCP_K8S_TOKEN` set | `MCP_K8S_SERVER`, otherwise in-cluster default |
| 2 | `/var/run/secrets/kubernetes.io/serviceaccount/token` exists | same |
| 3 | Fallback | `Kubernetes::REST::Kubeconfig` with `MCP_K8S_CONTEXT`, optional `kubeconfig_path` (constructor only, no env) |

Tiers 1 and 2 attach `ssl_ca_file` when the in-cluster CA file exists — even with an
explicit token. The paths are file-scoped `my` variables in `MCP/K8s.pm`.

### Namespaces

`_build_namespaces`: `MCP_K8S_NAMESPACES` → in-cluster namespace file → auto-discovery
via `list('Namespace')` → `['default']`. Every API use in there is in `eval`; there is
no path on which it dies.

`_resolve_namespace` fills in **only** when exactly one namespace is reachable, otherwise
`undef`; the tool handles that case itself.

### Permissions (lib/MCP/K8s/Permissions.pm)

`discover` sends one `SelfSubjectRulesReview` per namespace **plus one with an
empty namespace for cluster-scoped resources** — the `''` key in the map is the
cluster scope. Per-namespace errors are warned about and skipped, not propagated.

`can_do($verb, $plural, $ns)` matches via four branches: explicit verb, wildcard verb
on the resource, wildcard resource with verb, wildcard/wildcard. All four are live —
whoever optimizes one away breaks cluster-admin without breaking a narrow-role test.

**Subresources are in the map**, the way the API server reports them (`pods/log`,
`deployments/status`). RBAC treats them as resources of their own — `patch` on
`deployments` grants **no** `patch` on `deployments/status` —, so the
caller asks with the full name: `can_do('patch', 'deployments/status', $ns)`. A collision
with a base plural is impossible, that never contains a `/`. Filtering happens on
the presentation side: `allowed_resources` leaves them out so that the tool descriptions
stay with the main endpoints. (`summary` shows them — it always did
for `pods/log`.)

Up to 0.003 `_discover_namespace` threw away subresources other than `pods/log`. Consequence: a
correctly narrow status-writer role got a **false refusal**. Side effect
of the fix: a namespace whose only rights are subresources now shows up in
`allowed_namespaces` — `discover` stores only when `keys %$ns_rules`. That can
keep `_resolve_namespace` from auto-filling if it makes more than one namespace
reachable. The right direction (ask instead of guess), but a real
behavior change.

## Env vars

| Variable | Default | Effect |
|---|---|---|
| `KUBECONFIG` | `~/.kube/config` | Kubeconfig path (tier 3) |
| `MCP_K8S_CONTEXT` | current-context | Kubeconfig context |
| `MCP_K8S_TOKEN` | — | Bearer token, enables auth tier 1 |
| `MCP_K8S_SERVER` | in-cluster default | API server URL |
| `MCP_K8S_NAMESPACES` | Auto-discovery | Comma-separated namespace list |

There are **no** command-line flags. Configuration is entirely env-based,
so that it can be expressed in MCP client JSON (`.mcp.json`, Claude Desktop). Adding a flag
breaks that promise.

## Testing Notes

All tests run against hand-written mock packages in the respective test file
(`MockK8sAPI`, `MockSSRR`, `MockK8sObject`, …) that mimic the
`Kubernetes::REST` surface in use: `new_object`, `create`, `list`, `get`,
`delete`, `patch`, `expand_class`, `_request`. **No test needs a cluster, and
none may need one.**

| File | Covers |
|---|---|
| `t/00-load.t` | Loadability of the three modules |
| `t/01-permissions.t` | RBAC discovery, `can_do` wildcards, subresources, `allowed_*`, `summary` |
| `t/02-resource-plurals.t` | 4-tier pluralization |
| `t/03-namespace-resolution.t` | Auto-fill with exactly one namespace |
| `t/04-format-helpers.t` | Summary/list formatting |
| `t/05-server-tools.t` | Tool registration and execution, `force_409` path of `k8s_apply`, `k8s_patch` status path, `IO::K8s::Unstructured` |
| `t/06-kubernetes-alias.t` | `MCP::Kubernetes` is `MCP::K8s` |
| `t/07-auth-alternatives.t` | Token/in-cluster/kubeconfig tiers |
| `t/08-resource-discovery.t` | API discovery endpoints, subresource filter, tier 2 without a request against the real client |
| `t/09-auth-regression.t` | Predicate traps of the auth tiers (env-only, empty string) |
| `t/10-kubeconfig-path.t` | `kubeconfig_path` wins over `KUBECONFIG`, fallback without the attribute unchanged |

Two mock details that, rebuilt wrong, silently test the wrong thing: the
`SelfSubjectRulesReview` is built via `new_object` and submitted via **`create`**
(not `get`), and the cluster scope is the **empty** namespace string.

## Release

```bash
dzil release
```

`[@Author::GETTY]` bumps `$VERSION`, tags and creates the GitHub release. Mechanics:
skill `getty-perl-release-author-getty`. Release only with the maintainer's explicit
go-ahead — see the shared rule `getty-publish-gate` (skilletor bundle
`getty-cpan-dist@getty`).

## Sharp Edges (for developers)

- **`can_do` takes the plural, not the kind.** `can_do('list', 'Pod')` silently returns `0`
  and looks like a missing permission.
- **YAML comes from `IO::K8s`, not from a dumper of our own.** `k8s_get output=yaml`
  calls `$obj->to_yaml` — that serializes `JSON::PP::Boolean` correctly as `true`/`false`.
  A home-made `YAML::XS::Dump($obj->TO_JSON)` wrote
  `!!perl/scalar:JSON::PP::Boolean 1` and so no manifest that `kubectl` accepts.
  `YAML::PP` comes as a hard `requires` via IO::K8s — no optional dependency, no
  silent fallback to JSON: whoever asks for YAML gets YAML or a refusal.
- **Subresources are RBAC resources of their own.** `can_do('patch', 'deployments/status')`
  is a different question from `can_do('patch', 'deployments')` — and that is not
  pedantry but the promise that a main-endpoint patch does not give away a status
  write. The plural cache does not help here: `_discover_resource_plurals`
  skips names with `/`; get the base plural via `_resource_plural` and
  append `/status` yourself.
- **RBAC is the only authorization layer, on purpose.** If the ServiceAccount can
  read secrets, so can the LLM. The answer to that is a narrower role, not a
  filter in the server.
- `_resolve_namespace` returns `undef` when several namespaces are reachable —
  "take the first one" would be a silent misoperation against a real cluster.
- Plural tier 3 swallows every error; a wrong plural and a missing permission are
  indistinguishable from the outside. Leave it silent, but don't build new silent fallbacks next to it.
- `k8s_apply`'s conflict detection is a regex against the error string. If the
  client layer changes its error format, apply silently degrades to "create failed".
- POD follows the declaration, not the other way round: `sub foo {`, then `=method foo` … `=cut`,
  then the body; `has` followed by `=attr`. `[@Author::GETTY]` style; don't move it
  up.
- `$VERSION` is in all three modules and must stay in sync.
- The tool list exists in four places: `lib/MCP/K8s.pm` POD, `bin/mcp-k8s` POD,
  `README.md` and `_register_tools`. That is the drift most likely to ship.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the delegation lock and the publish gate are shared house rules (skilletor bundle
`getty-cpan-dist@getty`); lanes and hazards are in `.claude/rules/mcp-k8s-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `mcp-k8s-worker` |
| Write or extend tests (mechanics) | `mcp-k8s-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `mcp-k8s-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/`.
The karr board (`refs/karr/*`) is the internal coordination channel — this repo does not
have one yet, `karr init` creates it.

## Links

- README.md — user documentation
- examples/ — RBAC manifests (readonly / deployer / full-ops) + Raider demo
- dist.ini — [@Author::GETTY] config

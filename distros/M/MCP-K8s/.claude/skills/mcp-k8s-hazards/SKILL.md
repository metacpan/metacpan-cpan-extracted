---
name: mcp-k8s-hazards
description: Load before editing p5-mcp-k8s behavior-relevant code — why each hazard exists: RBAC-only, lazy discovery, plural lookup, silent tier 3, 409 regex, env-only config.
user-invocable: false
model: inherit
---

# mcp-k8s-hazards

The ten prohibitions from `.claude/rules/mcp-k8s-rules.md` — this is the reason
behind them. The rules file carries the prohibition, this skill carries the mechanism and
what breaks on a violation. Read both: the prohibition without the reason gets
optimized away, the reason without the prohibition does not apply.

The architecture itself is in `mcp-k8s-core` — this skill does not replace it.

## 1. RBAC is the only authorization layer

The server does **not** filter on the application side. Whatever RBAC allows, the LLM may do.
That is on purpose: a second filter layer in the server would be a gap that has to be
maintained, while RBAC stays the truth at the cluster.

- **Don't build in application-side filtering.** Whoever wants to keep secrets away from the LLM
  narrows the role — that is a rollout, not a patch.
- **Every tool call checks `can_do` first — even when the API answer would be
  403 anyway.** The prior check is what gives the LLM a readable refusal
  instead of a stack trace; without it the error looks like a server defect.
- **A request like "hide secrets from the LLM in the server" is a ticket**, not a
  refactoring. It changes the security architecture and belongs in front of the
  maintainer.

## 2. `can_do` takes the plural, not the kind

RBAC speaks plural (`pods`), the API speaks kind (`Pod`). `can_do('list', 'Pod')`
silently returns `0` — that looks exactly like a missing permission and makes
the caller suspect "Permission denied" where the server merely pluralized
wrongly. **Always `_resource_plural` first**, then `can_do`.

An error that looks like a permission problem is almost always pluralization.

## 3. Discovery is lazy — and that is a promise

`MCP::K8s->new` is constructible without a cluster; half the test suite relies on that.
`BUILD` only registers tools, the first RBAC call happens in `ensure_discovered`,
triggered by a tool call or `run_stdio`.

- **Don't move anything into `BUILD` that touches `->api`.** That breaks the test suite
  (no cluster in CI) and every embedding that only builds the server.
- **The test needs no cluster and must not need one** — the mocks in
  `t/` are the surface code can be measured against.

## 4. Four wildcard branches in `can_do`, all live

Explicit verb · wildcard verb (`*` on the resource) · wildcard resource with
verb · `*`/`*`.

Whoever optimizes a branch away breaks cluster-admin without a
narrow-role test going red — the tests cover the narrow case, not the
wide one. The branches are cheap; the misconfiguration is expensive.

## 5. Tool descriptions are functionality

The descriptions tell the LLM "Available: default: pods, deployments;
production: pods", so it does not have to guess. They are rewritten exactly once,
in `_update_tool_descriptions` (guard `_descriptions_updated`),
via `_tool_desc_map`.

- **A newly registered tool without an entry in `_tool_desc_map` keeps its static
  description forever** — the tool exists but is invisible to the
  LLM.
- **Don't "tidy up" the descriptions**: with >10 resources they are truncated to 10 + `...`,
  with `*` they say "all resources".
- **The example they produce:** "Available: default: pods, deployments;
  production: pods" — that is how the LLM learns what it will find per namespace instead of guessing.

## 6. Plural tier 3 swallows every error — by design

If API discovery fails, the cache stays empty and tier 4 (heuristic)
takes over. A cluster without discovery rights must not kill the server.

- **Keep the case silent.** A wrong pluralization looks like a
  permission denied; that is exactly why nothing loud may happen here.
- **Don't put new silent fallbacks next to it.** Every further silent branch
  makes debugging worse, not better.

## 7. `_resolve_namespace` returns `undef` with several namespaces

The namespace is filled in only when **exactly one** is reachable. Otherwise
`undef` — the tool has to handle the case itself (ask or refuse).

- **Don't change it to "take the first one".** With several reachable namespaces
  that would be a silent misoperation with real consequences: the agent writes into
  the wrong namespace.

## 8. `k8s_apply` detects the create conflict via regex

`_is_conflict_error` checks `/409|AlreadyExists/i` against the error string.

- **Why a regex and not structured:** `Kubernetes::REST` croaks a
  plain string; only its deprecated v0 modules carry typed errors. There is
  nothing structured to check. Narrowing it to the current
  croak format would be worse — an upstream rewording then becomes a
  false negative.
- **Revisit when the client gets typed errors** — not before.
- **If you touch the path: leave the regression test in place.**

## 9. Env vars only, no command-line flags

Configuration is entirely env-based, so that it can be expressed in MCP client JSON
(`.mcp.json`, Claude Desktop).

- **Adding a flag breaks that promise.** Whoever needs an option has to put
  it into the env matrix (`MCP_K8S_*`, `KUBECONFIG`, `MCP_K8S_CONTEXT`) or into
  the client's configuration.

## 10. `sub server { $_[0] }` is documented API

Passing `$k8s->server` to `Net::Async::MCP` is the documented Raider path
in the README. That is backward compatibility, **not** dead code.

- **Verified against MCP 0.15 + Net::Async::MCP 0.004**; 0.003 fails with
  `-32602 Missing protocol version`. So before the next "dead code" report,
  check the installed `Net::Async::MCP` version.

## Cluster access — the reason behind the section in the rules file

The test suite needs no cluster. Everything else is a **real cluster of the
maintainer**: `kubectl` or a live API call in this repo hits production.

- **Read-only inspection to reproduce is fine** when the maintainer
  has pointed at a context.
- **Anything mutating — create, patch, delete, rollout restart — needs an explicit
  go-ahead for every single step.**
- **"Just a ConfigMap" is not an exception category.** A ConfigMap can
  trigger pods that replace a deployment; the category decides nothing,
  the effect does.

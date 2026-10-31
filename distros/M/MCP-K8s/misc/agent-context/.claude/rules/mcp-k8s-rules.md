# MCP-K8s House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

MCP server for Kubernetes with RBAC-aware dynamic tools. Read first: the tool's registration
block, `can_do` and `_resource_plural` — the three are one mechanism across two files.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `mcp-k8s-worker` (default) |
| Write/extend tests | `mcp-k8s-test-writer` |
| Commits, `Changes`, card → done, pre-release audit | `mcp-k8s-release-manager` |
| Read-only research, audit, gap analysis | `mcp-k8s-worker` ("read-only, change nothing") |

Behavior-relevant = runtime behavior, the MCP tool wire-format contract, RBAC discovery and
permission gates, plural and namespace resolution, auth tier selection, output formatting,
tests. Prose and `Changes` notes are not.

## Deviations from the house rules

- **One board, no cross-repo handoff.** The public tracker includes CPAN RT besides GitHub
  issues.
- **Cluster access — read the room before you touch one.** The test suite never needs a
  cluster and never may require one. Beyond the tests, a `kubectl` or live-API call reaches a
  **real cluster the maintainer runs**: read-only inspection to reproduce a bug is fine when
  the maintainer has pointed you at a context, but anything mutating — create, patch, delete,
  rollout restart — needs an explicit go-ahead for that specific action, every time. "It's
  just a ConfigMap" is not a category of exception.

## Hazards — one prohibition each, the background is in skill `mcp-k8s-hazards`

- **RBAC is the only authorization layer, deliberately** — no application-side filtering,
  and there must not be one; too-broad permissions need a narrower Role.
- **`can_do` takes the plural, not the Kind** — `can_do('list', 'Pod')` returns `0` silently
  and looks like a missing permission; route through `_resource_plural` first.
- **Discovery is lazy and must stay lazy** — `BUILD` only registers tools; nothing that
  touches `->api` belongs in `BUILD`.
- **All four wildcard branches in `can_do` are live** — removing one breaks cluster-admin
  without breaking a narrow-Role test.
- **Tool descriptions are functionality** — rewritten exactly once via `_tool_desc_map`; a
  new tool missing from that map keeps its static description forever.
- **Plural tier 3 swallows every error by design** — keep it silent; don't add new silent
  fallbacks beside it.
- **`_resolve_namespace` returns `undef` when several namespaces are reachable** — never
  auto-pick the first one.
- **`k8s_apply` recognizes the create-conflict by regex** (`/409|AlreadyExists/i`) —
  narrowing the match would be worse; revisit when the client grows typed errors, keep a
  regression test.
- **Env-vars only, no command-line flags** — the configuration surface must stay expressible
  inside MCP client JSON (`.mcp.json`, Claude Desktop config).
- **`sub server { $_[0] }` is documented API**, not dead code — the README's
  `Net::Async::MCP->new(server => $k8s->server)` path depends on it; check the installed
  Net::Async::MCP version before believing a finding here.

## Perl specifics — reference, don't restate

Module loading, cpanfile pinning: `getty-perl-core`; Moo attributes and builders:
`getty-perl-moo`; MCP server and tool registration: `perl-mcp`; `[@Author::GETTY]` bundle
(bumps `$VERSION` and tags on release), POD, `{{$NEXT}}`: `getty-perl-release-author-getty`;
dist.ini: `perl-release-dist-ini`; commit style: `getty-git-commit-style`.

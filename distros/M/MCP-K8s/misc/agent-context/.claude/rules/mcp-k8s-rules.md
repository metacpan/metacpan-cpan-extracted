# MCP-K8s House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution
over speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at
launch (same priority as `CLAUDE.md`). Subagents get their discipline from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent.

## Engineering discipline

1. **Think before coding** — state assumptions; when uncertain, ask rather than guess.
   Push back when a simpler approach exists.
2. **Simplicity first** — minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — touch only what you must. Match existing style.
4. **Goal-driven execution** — define success criteria, loop until verified.
5. **Surface conflicts, don't average them** — pick one (more recent / more tested),
   flag the other for cleanup. Don't blend.
6. **Read before you write** — read the tool's registration block, `can_do`, and
   `_resource_plural` before changing any of them. The three are one mechanism spread
   across two files.
7. **Tests verify intent, not just behavior** — a test that can't fail when the logic
   changes is wrong. Reproduce a bug before fixing it; leave a regression test behind.
8. **Checkpoint after every significant step** — summarize: done / verified / left.
   Don't continue from a state you can't describe back.
9. **Match conventions** — conformance > taste. Surface a harmful convention; don't
   fork silently.
10. **Fail loud** — "Done" is wrong if anything was skipped. "Tests pass" is wrong if
    any were skipped. Surface uncertainty.
11. **A red test is a claim before it is a failure** — before changing code to turn a
    test green, say out loud what the test asserts. A fix that satisfies the assertion
    by removing the property it was sampling proves nothing. If the claim is wrong,
    fix the claim and say so.

## Delegation

This rule depends on whether the Agent/Task tool is available to you.

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  MCP-K8s code yourself — delegate to `mcp-k8s-worker` (or `mcp-k8s-test-writer` for
  test mechanics, `mcp-k8s-release-manager` for a release audit). Your lane: coordinate,
  inspect, plan, review diffs, run tests, edit non-behavioral docs. When in
  doubt, delegate. Why: only the `mcp-k8s-*` agents get their skills force-loaded via
  `briefing.skills`; you get no briefing and would touch internals with too little
  context.

- **You cannot spawn subagents** (you ARE `mcp-k8s-worker` or similar): The delegation
  lock does not apply to you — implement, refactor, debug, and test per these rules.

Behavior-relevant = runtime behavior, the MCP tool wire-format contract, RBAC discovery
and permission gates, resource-plural resolution, namespace resolution, auth tier
selection, output formatting, tests. Pure prose docs and `Changes` notes are not.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban; state lives in
`refs/karr/*`; this repo is a single distribution — one board, no cross-repo handoff.
Day-to-day: `karr list --compact` / `karr board` for open work; `karr show ID` for
detail; `karr create/edit/move/handoff` for the usual workflow; mutating commands
auto-sync, `karr sync --pull|--push` for explicit exchange. Use karr to record
decisions worth solidifying, drift to reconcile, and follow-up work that should not
block the current change. Full command surface: skill `kanban-issues-karr-coordination`.

**Serialize board mutations when fanning out.** Keep implementation work parallel if
you like, but collect results and then loop `karr move`/`handoff`/`sync` sequentially
— N of them landing at once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` / `prove -l t/` are fine anytime. `dzil release` and any
CPAN upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if
a plan, TODO or `Changes` notes "release" as the next step. The `[@Author::GETTY]`
bundle bumps `$VERSION` and tags on release; for anything heading toward release: stop
and ask.

## Public issues — never act without instruction

Two trackers, two universes. **karr** is the internal AI/agent work board (churned
freely). **GitHub issues / CPAN RT** are the public tracker: real humans' reports,
written under the maintainer's name. **Never act on a public issue on your own
initiative — not even to read it.** No listing, viewing, commenting, editing,
closing, or creating unless the user explicitly tells you to handle a specific
public item. Incoming tickets are NOT a queue the agent drains.

## Cluster access — read the room before you touch one

The test suite never needs a cluster and never may require one. Beyond the tests, a
`kubectl` or live-API call in this repo reaches a **real cluster the maintainer runs**.
Read-only inspection to reproduce a bug is fine when the maintainer has pointed you at
a context. Anything mutating — create, patch, delete, rollout restart — needs an
explicit go-ahead for that specific action, every time. "It's just a ConfigMap" is not
a category of exception.

## MCP-K8s-specific hazards

- **RBAC is the only authorization layer, deliberately.** There is no application-side
  filtering and there must not be one. "Hide secrets from the LLM in the server" is a
  design change to surface as a ticket, not a patch. The answer is a narrower Role.
- **`can_do` takes the plural, not the Kind.** `can_do('list', 'Pod')` returns `0`
  silently and looks exactly like a missing permission. Always route through
  `_resource_plural` first.
- **Discovery is lazy and must stay lazy.** `MCP::K8s->new` is constructible without a
  cluster; `BUILD` only registers tools. Moving an `->api` access into `BUILD` breaks
  both the test suite and every embedding use.
- **Four wildcard branches in `can_do`, all live.** Explicit verb, `*` verb, `*`
  resource with verb, `*`/`*`. Removing one breaks cluster-admin without breaking a
  narrow-Role test.
- **Tool descriptions are functionality.** They tell the LLM which resources exist per
  namespace, are rewritten exactly once via `_tool_desc_map`, and a new tool missing
  from that map keeps its static description forever.
- **Plural tier 3 swallows every error by design** — a wrong plural is indistinguishable
  from a missing permission. Keep it silent; don't add new silent fallbacks beside it.
- **`_resolve_namespace` returns `undef` when several namespaces are reachable.**
  Auto-picking the first one would be a silent misfire against a live cluster.
- **`k8s_apply` recognizes the create-conflict by regex** (`/409|AlreadyExists/i`)
  against the error string, in `_is_conflict_error`. Not laziness: Kubernetes::REST
  1.108 croaks a plain string and only its deprecated v0 modules carry typed errors,
  so there is nothing structured to check. Narrowing the match to the current croak
  format would be worse — an upstream rewording becomes a false negative. Revisit when
  the client grows typed errors; leave a regression test if touched.
- **Env-vars only, no command-line flags.** The configuration surface must stay
  expressible inside MCP client JSON (`.mcp.json`, Claude Desktop config).
- **`sub server { $_[0] }` is documented API**, not dead code — the README's
  `Net::Async::MCP->new(server => $k8s->server)` path depends on it. Verified against
  MCP 0.15 + Net::Async::MCP 0.004; 0.003 fails it with `-32602 Missing protocol
  version`. Check the installed Net::Async::MCP version before believing a finding here.

## Perl specifics — reference, don't restate

Module loading, cpanfile pinning: skill `getty-perl-core`. Moo attributes, lazy builders,
`extends`: skill `getty-perl-moo`. MCP server and tool registration: skill `perl-mcp`.
`[@Author::GETTY]` bundle, POD, `{{$NEXT}}`: skill `getty-perl-release-author-getty`.
dist.ini mechanics: `perl-release-dist-ini`. Commits: only `mcp-k8s-release-manager` commits (it carries `getty-git-commit-style`).
Don't duplicate.

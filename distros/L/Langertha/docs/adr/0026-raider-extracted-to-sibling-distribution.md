# ADR 0026 — Raider/Raid extracted to the sibling distribution langertha-raider; renamed core-namespace packages kept as reserved stubs

- Status: accepted
- Date: 2026-09-20
- Tags: distribution, raider, raid, mcp, cpan, dependencies, public-api

## Context

The autonomous agent (`Langertha::Raider`, ~2200 lines) and the `Raid` orchestration layer
(`Langertha::Raid`, `Raid::Loop/Parallel/Sequential`, `Langertha::RunContext`,
`Langertha::Role::Runnable`) shipped inside the core `Langertha` distribution, but core never
hard-depended on them: the only couplings were a lazy `use_module('Langertha::Raider')` sugar
path in `Langertha.pm` (`use Langertha qw( Raider )`) and a runtime `->isa('Langertha::Raider')`
string check in `Plugin.pm` — everything else was POD cross-references. The standalone `raider`
app (`App::Raider`, its own repo) already `requires 'Langertha'` and imported `Langertha::Raider`
directly.

That is the exact shape of a sibling distribution: the agent depends on the framework, never the
reverse — the same relationship `langertha-knarr` and `langertha-skeid` already have to core. The
agent framework and the `App::Raider` CLI are being merged into one new distribution,
`langertha-raider`, which will carry the `raider` binary and own the `Langertha::Raider::*`
namespace. This ADR records the **core-side** decision (what leaves, what stays, and why); the
new distribution's own assembly is out of scope here.

## Decision

Extract the agent/orchestration layer from core into the `langertha-raider` sibling distribution,
partitioning every affected package by one rule:

- **Migrates 1:1 (same name in the sibling) → removed from core.** `Langertha::Raider`,
  `Langertha::Raider::Result`, `Langertha::Raid` and `Raid::Loop/Parallel/Sequential` keep their
  names in `langertha-raider`, so the name lives on there and core simply drops them.
- **Renamed on the way over, and previously published → a reserved-namespace stub stays in core
  under the old name.** `Langertha::Result` is folded into a now self-contained
  `Langertha::Raider::Result`; because the sibling no longer ships the `Langertha::Result` name and
  that name was published up to 0.502, core keeps a minimal `package Langertha::Result; 1;` stub
  (`lib/Langertha/Result.pm`) whose only job is to keep the name indexed to the `Langertha`
  distribution on PAUSE.
- **Renamed on the way over, but never published → simply dropped, no stub.** `Langertha::MCP::Client`
  becomes `Langertha::Raider::MCP` (a self-contained `Net::Async::MCP` subclass). It was added after
  0.502 and never released, so there is no PAUSE index entry to preserve and a stub would reserve
  nothing — core just removes it.
- **Dependency-free generic primitive → kept in core, not moved.** `Langertha::RunContext` (a
  structured run context) and `Langertha::Role::Runnable` (the `run_f` contract) pull nothing beyond
  Moose + the Perl core and carry no Raider coupling in their code (only POD mentions). They are
  generic primitives, so they stay in core as real modules with their POD generalised;
  `langertha-raider`'s Raid/Raider consume them cross-dist via `requires 'Langertha'`. A generic,
  dependency-free primitive is better kept in core than pushed into a sibling and depended back on.

Core deliberately **keeps** the seams the agent was built on, because they are used without it
(plain `Langertha::Chat` tool calling, the plugin system): `Langertha::Role::Tools` /
`chat_with_tools_f`, `Langertha::Role::PluginHost`, `Langertha::Plugin`, `Langertha::Result` (as a
stub). `mcp_servers` is retyped in POD as a duck-typed `ArrayRef` of any `Net::Async::MCP`-compatible
client (the attribute was always `isa => 'ArrayRef'`, never pinned to `Langertha::MCP::Client`), so
core tool calling needs no MCP client class of its own — its tests drive the loop through an
in-tree `t/lib/Test/MockMCP.pm`. The lazy `use Langertha qw( Raider )` sugar and the
`->isa('Langertha::Raider')` guard stay verbatim; both are no-ops until `langertha-raider` is
installed, at which point the sugar's `use_module` resolves.

Dependencies follow the code: `Net::Async::MCP` is dropped from core, and `IO::Async` +
`Net::Async::HTTP` are added as explicit `requires`. Both were used directly by core's async `_f`
path (`Role::Chat` `_build__async_loop` / `_build__async_http`, `Role::Runtime::MetricsPoll`,
`Role::Tools`) but were never declared — they reached the dependency closure only transitively via
`Net::Async::MCP`, so removing it without declaring them would break core async on a clean install.
`Math::Vector::Similarity` and `MooseX::NonMoose` stay (non-Raider core consumers).

## Rationale

The rule keeps CPAN tidy without over-stubbing. A 1:1-migrated name needs no stub — it is still
published, just from the sibling (`langertha-raider` owns the `Langertha::Raider::*` subtree plus
the `Langertha::Raid*` names it took along; `Langertha::Raid` under a sibling is untidy but
harmless). A stub is spent only where it buys something: a *published* name being renamed away
would otherwise vanish from the index, so a stub preserves continuity and reserves the name for
future core use; a name that was never published has no index entry to preserve, so it is dropped
outright. And a genuinely generic, dependency-free primitive is better kept in core than pushed
into a sibling and depended back on.

## Consequences

- **Breaking for the core distribution** (`feat!:`). Installing `Langertha` alone no longer gives
  you `Langertha::Raider`, `Langertha::Raid` et al.; install `langertha-raider`. `Langertha::Result`
  still loads but is an empty stub, and `Langertha::MCP::Client` is gone entirely — code that used
  either must move to `Langertha::Raider::Result` / `Langertha::Raider::MCP`. `Langertha::RunContext`
  and `Langertha::Role::Runnable` remain available in core, unchanged.
- Core's async and tool-calling features are unchanged and still first-class; the extraction does
  not touch core's hard dependency graph beyond the declared-dependency correction above.
- ADR 0007 (Raider session archive) and ADR 0008 (Raider self-tools) describe decisions whose code
  now lives in `langertha-raider`; they stay here as historical record of how Raider reached this
  shape. This ADR does not supersede them.
- Reusable partitioning rule for future extractions: a name that migrates 1:1 is removed (it lives
  on in the sibling); a renamed name leaves a stub only if it was already published; a name that was
  never published is dropped; a dependency-free generic primitive stays in core rather than moving.

## Future work

- `langertha-raider` assembly (rename, `dist.ini`/`cpanfile`, `App::Raider` merge, tests) is
  tracked on that repo's board — not core work.
- karr #172 (Raider session-history embeddings) targets code that now lives in `langertha-raider`
  and should move to that board.

## Update (k189 — 2026-09-25): `Langertha::Raider::MCP` was never built

The rename `MCP::Client` → `Langertha::Raider::MCP` recorded above did not happen on the raider
side: langertha-raider (as of f39ad50) has no such module and uses `Net::Async::MCP` directly
(its cpanfile requires it). Nothing changes for core — `mcp_servers` stays duck-typed on any
`Net::Async::MCP`-compatible client — but core docs must not name `Langertha::Raider::MCP` as an
example client.

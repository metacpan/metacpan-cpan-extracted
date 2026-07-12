---
name: dbio-perl-release
description: "Load when dist.ini contains [@DBIO] — DBIO bundle options, version strategy, PodWeaver conventions, dzil release workflow"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO uses `[@DBIO]` from `Dist::Zilla::PluginBundle::DBIO`. NOT `[@Author::GETTY]`.

## dist.ini

Drivers:
```ini
name = DBIO-DriverName

[@DBIO]
```
Bundle sets `author`, `license`, `copyright_holder`. No version/copyright_year.

Heritage distributions (code derived from DBIx::Class — most extracted drivers):
```ini
name = DBIO-DriverName

[@DBIO]
heritage = 1
```
`heritage = 1` switches to `Pod::Weaver::PluginBundle::DBIO::Heritage`, which adds
a DBIx::Class copyright/attribution block to the generated POD;
`copyright_holder` defaults to `DBIO & DBIx::Class Authors`.

Core (`core = 1`):
```ini
name = DBIO
copyright_year = 2005

[@DBIO]
core     = 1
heritage = 1
```
Core extras: VersionFromMainModule, MakeMaker::Awesome, ExecDir.

## Repository metadata

All distributions (drivers and core) get `[DBIO::CodebergMeta]`. It derives the
`repository` / `bugtracker` / `homepage` resources from the git `origin` remote —
fully offline, no API token, no network. `origin` must point at `codeberg.org`
(the DBIO family lives at `codeberg.org/dbio/<repo>`); if it does not, the plugin
adds nothing rather than emitting metadata for the wrong forge. Do NOT hardcode a
`[MetaResources]` block in `dist.ini` — the bundle handles it.

## Agent skills (share_skill)

Each distribution ships the agent skills it OWNS (is the source of truth for)
into its sharedir. The bundle wires `[DBIO::GatherSkills]` + `[ShareDir]`:
GatherSkills copies `.claude/skills/<name>/` → `share/skills/<name>/` at build
time (the `.claude/` sources never reach CPAN — dot-dir, untracked by
`Git::GatherDir`). Declare owned skills explicitly:

```ini
[@DBIO]
heritage = 1
share_skill = dbio-mssql
share_skill = dbio-mssql-database
```

- Each skill is shipped by exactly ONE dist (its home), never re-shipped from a
  linked-in copy. Drivers own `dbio-<driver>` + `dbio-<driver>-database`;
  derived dists (async/age/postgis/graphql) own only their own skill; the shared
  family skills + `karr` belong to `DBIO` core; `dbio-perl-release` belongs to
  `Dist-Zilla-PluginBundle-DBIO`.
- Async drivers use `[@Filter] -bundle = @DBIO`: put `share_skill` inside the
  `[@Filter]` section. It reaches the bundle as a plain scalar (Filter does not
  know it is multivalue) — the `share_skill` attr accepts scalar or arrayref.
- Omitting `share_skill` makes GatherSkills derive owned skills from the dist
  name — declare them anyway, so the set is deterministic.
- Runtime (in `DBIO` core): `DBIO::Skills` exposes the installed sharedir skills;
  `DBIO->skill($name)` / `$schema->skill($name)` retrieve them. A schema may
  override via its `skills` classdata — sugar `skills({...})` / `skill(k => v)`
  under `use DBIO 'Schema'`, or `->connect(..., { skills => {...} })`.
  `bin/dbio-skills -MMyApp::Schema --deploy` deploys them into `.claude/skills/`.

## Version

- Drivers: `@Git::VersionManager` (first_version = 0.900000). The **main module**
  carries a hardcoded `our $VERSION = '...'` directly under `# ABSTRACT:` — the
  bundle rewrites/bumps it around release. Do NOT remove it, do NOT treat it as
  a violation, and do NOT add `$VERSION` to sub-modules (only the main module
  is versioned).
- Core: `$VERSION` in lib/DBIO.pm via `[VersionFromMainModule]`.
Target: `1.000000` when stable.
- **Family alignment (soft rule):** keep the whole DBIO family on the *same*
  released version — bump laggards up to match, don't release a patchwork.
  Especially for a coordinated cross-repo train (a core change plus its
  driver/transport/extension shares): release every touched dist at one shared
  version so a given version of `X` always pairs with the same version across
  repos. E.g. the #70 storage-layer-composition train ships core + dbio-async +
  the drivers all as `0.900001`.

## PodWeaver

`# ABSTRACT:` required on every .pm. `=attr name` after `has`/`mk_group_accessors`
→ ATTRIBUTES. `=method name` after `sub` → METHODS. `=func name` after `sub`
→ FUNCTIONS (for non-method subs, e.g. `DBIO::Util`, `DBIO::Diff::Compare`).
Omit NAME, VERSION, AUTHORS, COPYRIGHT (auto-generated). POD inline — never a
block after the final `1;`. There is no `=seealso` directive — use a regular
`=head1 SEE ALSO` section. Cross-refs: `L<DBIO::Module>`.

## Dependencies

In `cpanfile`, not dist.ini. Bundle uses `[Prereqs::FromCPANfile]`.
Versioning rules for DBIO-family deps: see [[dbio-perl-syntax]] (incl. the
bootstrap exception while the family is not yet on CPAN).

## Release

```bash
dzil build && dzil test && dzil release
```

## Reference tests (dbio-dzil)

Two tests in `dbio-dzil` are the executable reference for the bundle — read them
when unsure what `[@DBIO]` does:

- `t/10-bundle.t` — resolves `[@DBIO]` via `Dist::Zilla::Tester` and pins the
  `core = 1` vs driver branches (both: DBIO::CodebergMeta, DBIO::GatherSkills +
  ShareDir; core-only: VersionFromMainModule + MakeMaker::Awesome + ExecDir;
  driver-only: `@Git::VersionManager`), the `share_skill` → GatherSkills
  passthrough, and the versioning policy (RewriteVersion/Bump patch only
  `:MainModule` — sub-modules stay unversioned).
- `t/30-codebergmeta.t` — pins how `DBIO::CodebergMeta` parses the git remote
  and assembles the repository/bugtracker/homepage resources.
- `t/20-podweaver.t` — weaves a sample through `@DBIO` / `@DBIO::Heritage` and
  pins how `# ABSTRACT:` → NAME and `=attr`/`=method` → ATTRIBUTES/METHODS, plus
  the DBIx::Class copyright the Heritage variant adds.

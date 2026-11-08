---
name: dbio-perl-release
description: Use when a dist.ini contains [@DBIO] and you prepare a release or change dist.ini — bundle options, versioning, dzil release flow.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO uses `[@DBIO]` from `Dist::Zilla::PluginBundle::DBIO`.

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

- Each skill is shipped by exactly ONE dist (its home), never re-shipped from an
  installed copy. Drivers own `dbio-<driver>` + `dbio-<driver>-database`;
  derived dists (async/age/postgis/graphql) own only their own skill; the shared
  family skills belong to `DBIO` core (the karr skills come from the karr tool via skilletor, no DBIO dist ships them); `dbio-perl-release` belongs to
  `Dist-Zilla-PluginBundle-DBIO`.
- The EV dists (`dbio-postgresql-ev`, `dbio-mysql-ev`) use `[@Filter] -bundle = @DBIO`
  (with `-remove = MakeMaker` and their own `[MakeMaker]`); `dbio-async`, `dbio-forked`
  and the extensions use plain `[@DBIO]`. In a `[@Filter]` dist put `share_skill` inside
  the `[@Filter]` section. It reaches the bundle as a plain scalar (Filter does not
  know it is multivalue) — the `share_skill` attr accepts scalar or arrayref.
- Omitting `share_skill` makes GatherSkills derive owned skills from the dist
  name — declare them anyway, so the set is deterministic.
- Runtime (in `DBIO` core): `DBIO::Skills` exposes the installed sharedir skills;
  `DBIO->skill($name)` / `$schema->skill($name)` retrieve them. A schema may
  override via its `skills` classdata — sugar `skills({...})` / `skill(k => v)`
  under `use DBIO 'Schema', -<driver>`, or `->connect(..., { skills => {...} })`.
  `bin/dbio-skills -MMyApp::Schema --deploy` deploys them into `.claude/skills/`.

## Version

- Every shipped `.pm` carries the same literal `our $VERSION` — the rule for
  writing it is in `dbio-perl-syntax`; the bundle mechanics that rewrite it:
- Drivers: `@Git::VersionManager` (first_version = 0.900000), with
  `RewriteVersion::Transitional` (`global = 1`, `finder = [:InstallModules]`) and
  `BumpVersionAfterRelease` (`finder = [:InstallModules]`) — the bundle rewrites
  and bumps every module in lockstep around release.
- Core: the dist version is read from `lib/DBIO.pm` via `[VersionFromMainModule]`
  (core does not use `@Git::VersionManager`), so the sub-module `$VERSION`s are
  stamped by hand in one sweep commit rather than by a plugin.
Target: `1.000000` when stable.
- **Family alignment (soft rule):** keep the whole DBIO family on the *same*
  released version — bump laggards up to match, don't release a patchwork.
  Especially for a coordinated cross-repo train (a core change plus its
  driver/transport/extension shares): release every touched dist at one shared
  version so a given version of `X` always pairs with the same version across
  repos. E.g. the core k70 storage-layer-composition train ships core + dbio-async +
  the drivers all as `0.900001`.

## PodWeaver

POD conventions of `[@DBIO]` (`=attr`/`=method`, `# ABSTRACT`, generated
sections): skill `dbio-perl-pod`.

The bundle also gathers `xt/author/pod-checker.t` (`[DBIO::PodCheckerTest]`):
`Pod::Checker` over the built, woven POD under `lib/` and `bin/`. Any error —
above all an unresolved internal `L<>` link — fails `dzil test` and
`dzil release`; warnings do not, and a plain install skips the test. Fix the
POD, never the gate.

## Dependencies

In `cpanfile`, not dist.ini. Bundle uses `[Prereqs::FromCPANfile]`.
Versioning rules for DBIO-family deps: see [[dbio-perl-syntax]] (incl. the
bootstrap exception while the family is not yet on CPAN).

## Changes — the change, not the card

Maintainer's rule (2026-10-31), in every DBIO distribution. An entry in `Changes` says
what changed for the user of the dist, in words; it carries no karr card number, neither
`(k103)` nor a board-qualified `(core k103)`. The card belongs in the commit message, in
the house form `kNN`. Codeberg issues are public and keep their notation, `(Codeberg #13)`.

The changelog section of the commit-style skill applies in full: one topic one entry,
the destination not the journey. Released blocks (everything below a version line) are
not touched.

## Release

```bash
skilletor sync && ../dbio/maint/capped-test dzil test   # core: maint/capped-test dzil test
```

`dzil release` and any CPAN upload only on the maintainer's explicit go-ahead (house rules,
*Release*); a plan that lists "release" as the next step is not
that go-ahead.

`skilletor sync` comes first. GatherSkills reads the skill dirs from disk, and a
dist may declare a `share_skill` it installs through skilletor rather than tracks
(`dbio-dzil` ships `dbio-perl-release`, whose source is core) — git-ignored, so a
fresh clone does not have it. A `share_skill` whose dir is missing is fatal; the
per-skill `.gitignore` skilletor writes is not gathered (ADR 0058 in core).

**Skilletor sources stay on `main`.** Every `.claude/skilletor.json` in the family
keeps `ref: "main"` for each source (`getty`, `karr`, `dbio-core`, `dbio-postgresql`,
`dbio-mysql`); `skilletor.lock.json` stays git-ignored. The family develops against
`main` together: a rule, agent or skill changed in core reaches every dist on its
next `skilletor sync`, and whoever synced last has the current state. A release does
not pin sources to tags and needs no tag on a source repository: the tarball carries
the tracked `.claude/` as it is, and `GatherAgentContext` records the full agent
context a release was built with, skilletor-installed skills included, under
`misc/agent-context/`.

## Also in the bundle

- The tarball holds everything tracked in git, dotfiles and agent setup included; only the files the build writes itself (`META.yml`, `META.json`, `MANIFEST`, `README`, `README.md`) are left out.
- `DBIO::LicenseFile` checks the committed `LICENSE`: the text from `dist.ini`, or with `heritage` the DBIx::Class text. A missing or stale file stops the build.
- `TestRelease`, `Test::ChangesHasContent` and `InstallRelease` (`cpanm .`) run before `ConfirmRelease`.
- `GatherAgentContext` snapshots `.claude/`, `CLAUDE.md` into `misc/agent-context/` of the tarball (provenance, not installed).
- `DBIO::CoverageTest` generates `xt/release/coverage.t` with `coverage_threshold`.
- `Git::CheckFor::CorrectBranch` — release only from `main`.
- `MetaResources` sets the family `x_IRC` channel.
- Core's `MetaNoIndex` keeps the test facades (`DBIO::Test::Conformance` & co.) indexed, they are public.

## Reference tests (dbio-dzil)

The tests in `dbio-dzil` are the executable reference for the bundle — read them
when unsure what `[@DBIO]` does:

- `t/10-bundle.t` — resolves `[@DBIO]` via `Dist::Zilla::Tester` and pins the
  `core = 1` vs driver branches (both: DBIO::CodebergMeta, DBIO::GatherSkills +
  ShareDir; core-only: VersionFromMainModule + MakeMaker::Awesome + ExecDir;
  driver-only: `@Git::VersionManager`), the `share_skill` → GatherSkills
  passthrough, and the versioning policy (RewriteVersion/Bump patch
  `:InstallModules` with `global = 1` — every module is versioned).
- `t/30-codebergmeta.t` — pins how `DBIO::CodebergMeta` parses the git remote
  and assembles the repository/bugtracker/homepage resources.
- `t/20-podweaver.t` — weaves a sample through `@DBIO` / `@DBIO::Heritage` and
  pins how `# ABSTRACT:` → NAME and `=attr`/`=method` → ATTRIBUTES/METHODS, plus
  the DBIx::Class copyright the Heritage variant adds.
- `t/40-bundle-coverage.t` — pins how the bundle wires `DBIO::CoverageTest` and
  its `coverage_threshold` (default 80, `0` = no-op skip).
- `t/50-gatherskills.t` — pins `DBIO::GatherSkills`: a declared `share_skill`
  whose dir is missing is fatal, skilletor's per-skill `.gitignore` is not shipped.
- `t/60-agentcontext.t` — pins the `misc/agent-context/` snapshot
  (`GatherAgentContext`).
- `t/70-bundle-podchecker.t` — pins the POD gate: an unresolved internal link in
  a built module turns the generated test red, naming file and link; without
  `AUTHOR_TESTING` it skips.

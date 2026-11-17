# CLAUDE.md — Dist::Zilla::PluginBundle::DBIO

The family skills, agents and house rules this file refers to (`dbio-*`, `karr-coordinator`,
`.claude/rules/.local.dbio-rules.md`) are not part of the checkout: skilletor installs them from
the `dbio` core repo and they are git-ignored. The family-wide house rules (discipline,
delegation, release) are auto-loaded by Claude Code for the main agent and all subagents.

**Fresh clone or worktree: run `skilletor sync` first.** Until then the installed skills, rules
and agents do not exist. It needs the skilletor plugin (`skilletor@getty`) and network access to the sources in `.claude/skilletor.json`
(`github.com/Getty/skills`, `github.com/Getty/karr`, `codeberg.org/dbio/dbio`). Never edit an
installed copy — change the source in core, then sync again.

## Delegation

Delegate behavior-relevant changes to the `[@DBIO]` bundle, the PodWeaver config, or the
version logic to this repo's `dbio-worker-dzil` instead of touching them yourself. Lane and
principle: `.claude/rules/.local.dbio-rules.md`. Repo agents: `dbio-worker-dzil` (default),
`dbio-adr-auditor`, `dbio-release-manager`, `karr-coordinator`.

## Project Vision

The standard Dist::Zilla plugin bundle for all DBIO distributions. Provides a fixed, no-configuration build/test/release workflow.

## Namespace

- `Dist::Zilla::PluginBundle::DBIO` — the `[@DBIO]` plugin bundle
- `Dist::Zilla::Plugin::DBIO::CodebergMeta` — repository/bugtracker/homepage META from the git remote (Codeberg, or a Forgejo instance via `host=`)
- `Dist::Zilla::Plugin::DBIO::CoverageGate` — test runner behind the build plugin: scores `cover_db/` after the whole suite
- `Dist::Zilla::Plugin::DBIO::GatherSkills` — ships the installed skills under `share/skills/`
- `Dist::Zilla::Plugin::DBIO::LicenseFile` — checks the committed `LICENSE` (fixed DBIx::Class text with `heritage = 1`, else the dist's Perl_5 license)
- `Dist::Zilla::Plugin::DBIO::PodCheckerTest` — generates the Pod::Checker gate test
- `Dist::Zilla::Plugin::DBIO::RequireCoreVersion` — before the release of every dist but core: the runtime prereq `DBIO` must ask for at least the dist's own version
- `Dist::Zilla::Plugin::DBIO::SetMeta` — sets author, copyright holder and license on the Dist::Zilla object
- `Dist::Zilla::Plugin::DBIO::VersionLockstepTest` — generates the version-lockstep gate test (`core = 1`)
- `Pod::Weaver::PluginBundle::DBIO` — the `@DBIO` PodWeaver config
- `Pod::Weaver::PluginBundle::DBIO::Heritage` — subclass that adds DBIx::Class copyright attribution

## Usage

```ini
# New DBIO distribution
name = DBIO-MyDriver

[@DBIO]
```

```ini
# Distribution derived from DBIx::Class code
name = DBIO-PostgreSQL

[@DBIO]
heritage = 1
```

```ini
# DBIO core
name           = DBIO
copyright_year = 2005

[@DBIO]
core     = 1
heritage = 1
```

## Key Behaviors

- **`author`**: set automatically — `heritage = 1` → `DBIO & DBIx::Class Authors`, otherwise → `DBIO Authors`. No `author =` needed in `dist.ini`.
- **`license`**: always `Perl_5` in META, set automatically. No `license =` needed in `dist.ini`. No `[License]` plugin — LICENSE file is committed in every repo and gathered from git.
- **`copyright_holder`**: set automatically — same logic as `author`. Override via `copyright_holder = ...` in the `[@DBIO]` section.
- **LICENSE file**: always committed in the repo and gathered by `Git::GatherDir`; `DBIO::LicenseFile` only checks it and fails the build when it is missing or deviates. Heritage repos must carry the fixed DBIx::Class license with DBIO attribution header (held in the plugin), non-heritage repos the standard Perl_5 license of the dist (`dzil genlicense`).
- **Tarball**: what is tracked in git ships (`Git::GatherDir` with dotfiles, no `PruneCruft`); only the six `exclude_filename` names stay out — the generated `META.yml`, `META.json`, `MANIFEST`, `README`, `README.md` and `.karr` — and there is no `exclude_match`. Same for core and drivers.
- **Release checks**: `TestRelease`, `Test::ChangesHasContent` and `InstallRelease` (`cpanm .`) run before `ConfirmRelease`. Drivers (not core) run `DBIO::RequireCoreVersion` first: the `cpanfile` line `requires 'DBIO', '<version>';` must be at least the version being released, else the release stops.
- **Scripts**: `ExecDir` (`bin/`) for every dist, core and drivers; without a `bin/` it changes nothing.
- **Copyright**: the COPYRIGHT AND LICENSE section of the woven POD carries the dist's `copyright_year` and `copyright_holder`; the DBIx::Class lines of a heritage dist are fixed.
- **Version**: core and drivers alike through `@Git::VersionManager` (the main module's `$VERSION`; the git tags only when it has none, `first_version = 0.900000`); every module under `lib/` carries its own `$VERSION`, rewritten in lockstep at the release and raised by `BumpVersionAfterRelease` right after it.
- **Coverage gate**: `DBIO::CoverageGate` is a `TestRunner` placed behind the build plugin (MakeMaker / MakeMaker::Awesome); for `dzil test` and `dzil release` it scores the `lib/` of the build directory from `cover_db/` once the whole suite has run, and merges the runs of a fresh `cover_db/` itself. `coverage_threshold` defaults to 80, `0` disables. Below threshold logs a warning, and aborts under `COVERAGE_STRICT=1` or `RELEASE=1`; no `cover_db/` (or no `Devel::Cover::DB`, no valid database, no measured `lib/` file) aborts under `RELEASE=1` and is only noted otherwise. No coverage test is generated.
- **POD gate**: `DBIO::PodCheckerTest` generates `xt/author/pod-checker.t`; any Pod::Checker error over the built `lib/` and `bin/` POD fails `dzil test` and `dzil release` (runs under `AUTHOR_TESTING`, skipped on a plain install).
- **Version gate (core only)**: `DBIO::VersionLockstepTest` generates `xt/author/version-lockstep.t`; for `core = 1` every `.pm` under the built `lib/` must carry a literal `$VERSION` equal to the main module's, else `dzil test`/`dzil release` fails and the test names the file. Non-core dists do not get it.
- **POD**: `@DBIO` for new distributions; `@DBIO::Heritage` for heritage (adds DBIx::Class copyright block).

## Build System

Uses itself via `[Bootstrap::lib]` for self-bootstrapping.

## Versioning — NEVER bump $VERSION manually

`$VERSION` in the modules is managed by `RewriteVersion::Transitional` (part of
`@Git::VersionManager`), for core and drivers alike. It is rewritten automatically
during `dzil release` to the main module's version. **Never edit `$VERSION` by hand.**
Between two releases the source carries the *next* version
(`BumpVersionAfterRelease` raises every module right after a release) — that is
correct and intentional.

Similarly, never add a version line to `Changes` — `{{$NEXT}}` is filled in by
`NextRelease` during `dzil release`. Just add bullet points under `{{$NEXT}}`.

## Standard Commands

```bash
dzil build                                  # build and check
../dbio/maint/capped-test dzil test         # run tests, capped (house rule 9)
dzil release                                # release to CPAN — must be run by the user, not by AI
```

## Tests

Offline only: the tests build small dists in a temp dir and touch no database; no database
server or `DBIO_TEST_*` variable is involved — there is no live suite here and no
test database of its own. Run everything through `capped-test` from core (path from this repo's
root), and recursively:

```bash
../dbio/maint/capped-test prove -lr t/      # the whole suite
../dbio/maint/capped-test dzil test         # build + suite + generated gate tests
prove -l t/10-bundle.t                      # a single file only, while developing
```

Never `prove -j`. Run against the local family checkouts, not an older `~/perl5`: put
`../dbio/lib` and the sibling repos' `lib` directories first in `PERL5LIB`.

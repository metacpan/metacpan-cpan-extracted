---
name: perl-release-author-getty
description: "Load when dist.ini contains [@Author::GETTY] — bundle options, POD conventions (=attr/=method/=opt), next-version semantics, dzil release workflow, copyright_year, Changes/{{$NEXT}}"
user-invocable: false
allowed-tools: Read, Grep
model: sonnet
---

When working with `[@Author::GETTY]` plugin bundle:

## Required Metadata

```ini
name = Distribution-Name
author = Name <email>
license = Perl_5
copyright_holder = Copyright Owner
```

## @Author::GETTY Options

### Feature Toggles (Boolean)
- `no_cpan` - Skip UploadToCPAN
- `no_podweaver` - Skip PodWeaver
- `no_changes` - Skip NextRelease
- `no_installrelease` - Skip InstallRelease
- `no_makemaker` - Skip MakeMaker
- `xs` - Use ModuleBuildTiny (for pure-Perl XS without Alien deps)
- `deprecated` - Add Deprecated plugin
- `adoptme` - Add x_adoptme metadata

### XS with Alien
- `xs_alien = Alien::Foo` - Auto-configures MakeMaker::Awesome for XS+Alien
- `xs_object = Name` - Override XS object name (default: derived from Alien name)

### Versioning
- `task = 1` - TaskWeaver + AutoVersion
- `manual_version = x.x` - Manual version
- `major_version = 2` - Major version for AutoVersion
- `version_finder = :MainModule` - restrict `$VERSION` rewrites/bumps to the main module only (see "version_finder = :MainModule — opt-in, not the default" below). Multi-value; forwarded to RewriteVersion::Transitional + BumpVersionAfterRelease (default path) and PkgVersion (task/manual_version path).

### Support
- `irc = #channel` - IRC channel
- `irc_server` - Server (default: irc.perl.org)
- `irc_user` - Username for SUPPORT section

### Git
- `release_branch` - Branch for releases (default: main)

### Alien (prefix `alien_`)

For wrapping C libraries with Alien::Base:

**Required:**
- `alien_repo` - URL to download releases from

**Library identification:**
- `alien_name` - Name of the alien package
- `alien_bins` - Executables to install (multi-value)

**Archive pattern matching:**
- `alien_pattern` - Full regex pattern for archive matching
- `alien_pattern_prefix` - Prefix (e.g., `mylib-`)
- `alien_pattern_version` - Version regex (default: `([\d\.]+)`)
- `alien_pattern_suffix` - Suffix (e.g., `\.tar\.gz`)

**Build configuration:**
- `alien_msys` - Use MSYS on Windows
- `alien_autoconf_with_pic` - Pass --with-pic to autoconf
- `alien_isolate_dynamic` - Isolate dynamic libraries
- `alien_version_check` - Command to check installed version

**Custom build commands (for non-autoconf projects):**
- `alien_build_command` - Custom build commands (multi-value, use `%s` for prefix)
- `alien_install_command` - Custom install commands (multi-value)
- `alien_test_command` - Custom test commands (multi-value)

**Dependencies:**
- `alien_bin_requires` - Build dependencies (multi-value)

### Run Hooks (prefix `run_`)
- `run_before_build`, `run_after_build`
- `run_before_release`, `run_after_release`
- `run_release`, `run_test`

## POD Commands (Pod::Elemental::Transformer::Author::GETTY)

### Section Commands (→ =head1)
- `=synopsis` → `=head1 SYNOPSIS`
- `=description` → `=head1 DESCRIPTION`
- `=seealso` → `=head1 SEE ALSO`

### Inline Commands (→ =head2)
- `=attr name` → `=head2 name`
- `=method method_name` → `=head2 method_name`
- `=func func_name` → `=head2 func_name`
- `=opt` - CLI options
- `=env` - Environment variables
- `=hook` - Hooks
- `=example` - Examples

**Auto-generated sections (do NOT write manually):**
NAME, VERSION, AUTHOR, SUPPORT, CONTRIBUTING, COPYRIGHT

## Versioning Convention — CRITICAL

**The version in the repository is always the NEXT release version, not the current one.**

Before a release, the files already contain the upcoming version:
- `dist.ini` or module `$VERSION` = e.g. `1.005`
- `Changes` has `{{$NEXT}}` as the placeholder for unreleased changes
- The currently released version on CPAN is `1.004`

After `dzil release` runs:
1. `{{$NEXT}}` in Changes is replaced with `1.005` + release date
2. The version is bumped to `1.006` (or next AutoVersion value)
3. A Git tag `v1.005` is created

**Do NOT treat the version in dist.ini as the released version.** If the user asks "what version is released?", check CPAN or git tags — not the current `$VERSION` in the files.

**Do NOT bump the version manually before a release** — `dzil release` handles this automatically.

### `version_finder = :MainModule` — opt-in, not the default

**Default across GETTY's distributions: `our $VERSION` in every `.pm` file**, rewritten/bumped
by `[@Git::VersionManager]` (RewriteVersion::Transitional + BumpVersionAfterRelease) on release.
Do not strip `$VERSION` from sibling modules unless the dist.ini says otherwise — this is the
normal case, not a legacy fallback.

A small number of distributions instead scope `$VERSION` to the main module only (`lib/Foo.pm`),
with no `$VERSION` line in sibling `.pm` files. This is strictly opt-in via:

```ini
[@Author::GETTY]
version_finder = :MainModule
```

**Do not add this option to a distribution's dist.ini on your own initiative** and do not
describe it as "the convention" — check the actual dist.ini before assuming either style applies.

How it works when set:
- `version_finder = :MainModule` scopes the RewriteVersion::Transitional/BumpVersionAfterRelease
  rewrite/bump to the main module, so sibling files are never touched.
- `[MetaProvides::Package] inherit_version=1, inherit_missing=1` (always in the bundle) fills
  `META.json` `provides` with the dist version for **every** package, so PAUSE/CPAN indexing
  stays correct even though the sibling `.pm` files have no `$VERSION` at runtime.
- Sibling modules resolve their version as `$MainModule::VERSION` at runtime
  (e.g. `$Foo::VERSION`) — there is no per-file `$VERSION` to read.
- On the `[PkgVersion]` path it also avoids the build-time failure when a sibling
  module already carries its own `$VERSION` — PkgVersion refuses to overwrite one.

Verify before touching a `:MainModule` distribution:
```bash
grep -n "version_finder" dist.ini   # confirm the option is actually set
grep -rl 'our $VERSION' lib         # should list ONLY the main module
```

## Release Workflow

```bash
# Before release: check Changes, ensure {{$NEXT}} section has entries
# Then:
dzil release        # Builds, tests, uploads to CPAN, bumps version, commits, tags
```

## Conventions

1. `copyright_year` IS used in dist.ini — GETTY has it in ALL distributions, do NOT remove it
2. No `=head1 SUPPORT/AUTHOR/COPYRIGHT` in POD
3. Use inline `=attr`/`=method` directly after code
4. Dependencies in `cpanfile`, not dist.ini
5. Changes file with `{{$NEXT}}` for unreleased
6. For XS+Alien modules: use `xs_alien = Alien::Foo` (auto-configures MakeMaker::Awesome)

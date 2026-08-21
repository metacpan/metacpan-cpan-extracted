---
name: getty-perl-release-author-getty
description: Load when a dist.ini contains [@Author::GETTY] — bundle options, POD conventions (=attr/=method/=opt), next-version semantics, the dzil release workflow.
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
- `no_cpan` - Skip UploadToCPAN; also defaults `version_finder` to `:MainModule`
- `no_podweaver` - Skip PodWeaver
- `no_changes` - Skip NextRelease
- `no_installrelease` - Skip InstallRelease
- `no_makemaker` - Skip MakeMaker
- `xs` - Use ModuleBuildTiny (for pure-Perl XS without Alien deps)
- `deprecated` - Add Deprecated plugin
- `adoptme` - Add x_adoptme metadata
- `no_github` - Skip GithubMeta and GitHub::CreateRelease, use Repository instead. Auto-set to 1 when `.git/config` has no github.com remote; set `no_github = 0` to force GitHub plugins on anyway
- `no_github_release` - Skip only GitHub::CreateRelease. Same auto-detection; when active, `dzil release` creates a GitHub Release and attaches the tarball, which needs `~/.github-identity` (login + token)
- `gitea` - Treat the remote host as Gitea/Forgejo (repository/bugtracker/homepage via GiteaMeta). Only needed for self-hosted instances — codeberg.org and the author's own are auto-detected. No effect when a GitHub remote exists
- `include_readme` - Ship README.md (excluded from the tarball by default)
- `no_install` - Resulting distribution can't be installed

### Identity & Metadata
- `author` - CPAN author name used for the authority
- `authority` - Override the authority, e.g. `authority = ETHER` when uploading modules owned by another author (default: the `author` value)

### XS with Alien
- `xs_alien = Alien::Foo` - Auto-configures MakeMaker::Awesome for XS+Alien
- `xs_object = Name` - Override XS object name (default: derived from Alien name)

### Versioning
- `task = 1` - TaskWeaver + AutoVersion
- `manual_version = x.x` - Manual version
- `major_version = 2` - Major version for AutoVersion
- `version_finder` - multi-value; forwarded as the `finder` option of RewriteVersion::Transitional + BumpVersionAfterRelease (default path) and PkgVersion (task/manual_version path). Defaults to `:MainModule` when `no_cpan` is set, otherwise unset.

### Build & Release
- `weaver_config` - PodWeaver `config_plugin` to use (default: the bundle's own)
- `installrelease_command` - Command used to install after release, instead of cpanm

### Docker
- `docker_image` - Image repository. Auto-adds one Docker::API plugin, which is a working Releaser on its own (no UploadToCPAN needed for non-CPAN dists)
- `docker_tags` - Whitespace-separated tag list (default: `latest %V %v`)
- `docker_local` - Build and tag the image, but don't push
- `docker_default` - Set to 0 to suppress the auto-added plugin when you configure builds exclusively through `[@Author::GETTY::Docker / name]` subsections

### Support
- `irc = #channel` - IRC channel
- `irc_server` - Server (default: irc.perl.org)
- `irc_user` - Username for SUPPORT section

### Git
- `release_branch` - Branch for releases (default: main)
- `tag_format` - Release tag format. Default `%v`, the bare `$VERSION` (`0.317`) — *not* a v-prefixed SemVer tag. Use `v%v.0` when the tag must satisfy strict vMAJOR.MINOR.PATCH (Perl's decimal `$VERSION` has only two parts, the `.0` supplies the patch part)
- `commit_files_after_release` - Multi-value; extra files folded into the release commit (via Git::Commit's `allow_dirty`). For artefacts a `run_before_release` hook rewrites, e.g. a sibling Python/JS version file

### Alien (prefix `alien_`)

- `alien_build = 1` - Alien::Build-based dist: adds AlienBuild (Makefile.PL driven by Alien::Build::MM), implies `no_makemaker`, expects an `alienfile` in the dist root

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

### Every file carries its own `$VERSION`

**Each file under `lib/` and `bin/` needs its own `our $VERSION = '...';`**, set to
the version that will be released NEXT — one higher than what is on CPAN (or
higher). A file without a `$VERSION` ships versionless and breaks consumers that
pin against it.

**Only the FIRST `our $VERSION` in a file gets rewritten.** RewriteVersion::Transitional
and BumpVersionAfterRelease both stop after the first match, so a file holding two
packages leaves the second one frozen at whatever version it was written with —
while MetaProvides::Update happily reports the real release version. The result is
a distribution whose META and whose code disagree, silently, for as many releases
as it takes someone to notice.

So: **one package per file.** If you find several `package` statements in one file,
split them out before releasing.

**Executables belong in `bin/`, never `script/`.** The bundle sets no `ExecDir`, so
Dist::Zilla's default of `bin` applies: files under `script/` are not installed as
executables and their `$VERSION` is never rewritten. A distribution with a `script/`
directory should have it renamed to `bin/` — otherwise none of the above takes
effect.

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

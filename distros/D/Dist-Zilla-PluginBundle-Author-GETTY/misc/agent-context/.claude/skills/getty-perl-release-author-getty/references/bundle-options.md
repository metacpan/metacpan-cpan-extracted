# `[@Author::GETTY]` options

Read when setting, reading or debugging an `[@Author::GETTY]` option in `dist.ini`.

## Feature Toggles (Boolean)
- `no_cpan` - Skip UploadToCPAN; also defaults `version_finder` to `:MainModule`
- `no_podweaver` - Skip PodWeaver
- `no_changes` - Skip NextRelease
- `no_installrelease` - Skip InstallRelease
- `no_makemaker` - Skip MakeMaker
- `xs` - Use ModuleBuildTiny (for XS without Alien deps)
- `deprecated` - Add Deprecated plugin
- `adoptme` - Add x_adoptme metadata
- `no_github` - Skip GithubMeta and GitHub::CreateRelease, use Repository instead. Auto-set to 1 when `.git/config` has no github.com remote; set `no_github = 0` to force GitHub plugins on anyway
- `no_github_release` - Skip only GitHub::CreateRelease. Same auto-detection; when active, `dzil release` creates a GitHub Release and attaches the tarball, which needs `~/.github-identity` (login + token)
- `gitea` - Treat the remote host as Gitea/Forgejo (repository/bugtracker/homepage via GiteaMeta). Only needed for self-hosted instances — codeberg.org and the author's own are auto-detected. No effect when a GitHub remote exists
- `include_readme` - Ship README.md (excluded from the tarball by default)
- `no_install` - Resulting distribution can't be installed
- `generate_license` - Go back to a generated LICENSE: `@Basic` keeps its License plugin, no LicenseFile check is added. Default 0 — the bundle expects a committed LICENSE

## Identity & Metadata
- `author` - CPAN author name used for the authority
- `authority` - Override the authority, e.g. `authority = ETHER` when uploading modules owned by another author (default: the `author` value)

## XS with Alien
- `xs_alien = Alien::Foo` - Auto-configures MakeMaker::Awesome for XS+Alien
- `xs_object = Name` - Override XS object name (default: derived from Alien name)

## Versioning
- `task = 1` - TaskWeaver + AutoVersion
- `manual_version = x.x` - Manual version
- `major_version = 2` - Major version for AutoVersion
- `version_finder` - multi-value; forwarded as the `finder` option of RewriteVersion::Transitional + BumpVersionAfterRelease (default path) and PkgVersion (task/manual_version path). Defaults to `:MainModule` when `no_cpan` is set, otherwise unset.

## Build & Release
- `weaver_config` - PodWeaver `config_plugin` to use (default: the bundle's own)
- `installrelease_command` - Command used to install after release, instead of cpanm

## Docker
- `docker_image` - Image repository. Auto-adds one Docker::API plugin, which is a working Releaser on its own (no UploadToCPAN needed for non-CPAN dists)
- `docker_tags` - Whitespace-separated tag list (default: `latest %V %v`)
- `docker_local` - Build and tag the image, but don't push
- `docker_default` - Set to 0 to suppress the auto-added plugin when you configure builds exclusively through `[@Author::GETTY::Docker / name]` subsections

## Binary
Standalone `pp` binaries of the dist's scripts as assets of the GitHub release. Only `binary` is needed. Packing itself (what `pp` misses, verify and smoke scripts): skill `perl-par-binary-release`.
- `binary` - Whitespace-separated names, repeatable; each is packed from `bin/NAME`. Turns the binary release on and forces the GitHub release: the bundle dies with `no_github`, `no_github_release` or no GitHub remote
- `binary_modules` - Extra modules packed into every binary (`-M`). `Foo::*` packs everything below `Foo/` but not `Foo.pm` itself; an empty namespace does not fail
- `binary_require` - Modules or `Namespace::*` globs that must be inside every finished binary, or the build fails
- `binary_pp_args` - Shell command whose output is added to the `pp` command line, one argument per line
- `binary_verify` - Shell command run after packing with the binary's path appended; runs without `PERL5LIB`, the packing perl's is in `DZIL_BINARY_PERL5LIB`
- `binary_smoke` - Like `binary_verify`, run by the workflow on every platform on a machine without Perl; neither `PERL5LIB` nor `DZIL_BINARY_PERL5LIB`
- `binary_platforms` - Out of `linux-x86_64 linux-arm64 macos-arm64 macos-x86_64 windows-x86_64` (default: all five). Dist-wide, refused in a subsection
- `binary_prepare` - Shell command run once per platform before the dependencies are installed; its first word must be a file of the dist. Dist-wide, refused in a subsection
- `binary_default` - Set to 0 to not add the binaries from `binary` and configure them through `[@Author::GETTY::Binary / name]` subsections
- `[@Author::GETTY::Binary / name]` - One binary configured on its own, e.g. `script` when it is not `bin/name`; inherits `binary_modules`, `binary_require`, `binary_pp_args`, `binary_verify`, `binary_smoke`
- Caller workflow - the dist's own `.github/workflows/binaries.yml` calls `Getty/p5-dist-zilla-pluginbundle-author-getty/.github/workflows/dzil-binary.yml@binary-v1` on `release: published`; `dzil release` is refused without that file. Full text in the bundle POD under "Binaries"
- `DZIL_BINARY_SKIP=1` - `dzil build` packs again as a local check and needs `pp` in the `PATH`; this skips it, including `binary_verify` and `binary_smoke`

## Support
- `irc = #channel` - IRC channel
- `irc_server` - Server (default: irc.perl.org)
- `irc_user` - Username for SUPPORT section

## Git
- `release_branch` - Branch for releases (default: main)
- `tag_format` - Release tag format. Default `%v`, the bare `$VERSION` (`0.317`) — *not* a v-prefixed SemVer tag. Use `v%v.0` when the tag must satisfy strict vMAJOR.MINOR.PATCH (Perl's decimal `$VERSION` has only two parts, the `.0` supplies the patch part)
- `commit_files_after_release` - Multi-value; extra files folded into the release commit (via Git::Commit's `allow_dirty`). For artefacts a `run_before_release` hook rewrites, e.g. a sibling Python/JS version file

## Alien (prefix `alien_`)

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

## Run Hooks (prefix `run_`)
- `run_before_build`, `run_after_build`
- `run_before_release`, `run_after_release`
- `run_release`, `run_test`

Use a run hook for the project-specific step that follows a release — a Docker
build and push, a deploy script — so it travels with `dzil release` instead of
living in someone's shell history. Never wire up a step the bundle already
performs; the hook is for what it does *not* know about.

```ini
[Run::Release]
run = docker build -t registry/app:%v %d && docker push registry/app:%v
```

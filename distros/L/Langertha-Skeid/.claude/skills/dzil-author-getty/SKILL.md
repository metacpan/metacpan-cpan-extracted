---
name: dzil-author-getty
description: "Explains @Author::GETTY plugin bundle configuration and conventions"
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

## Conventions

1. `copyright_year` IS used in dist.ini — GETTY has it in ALL distributions, do NOT remove it
2. No `=head1 SUPPORT/AUTHOR/COPYRIGHT` in POD
3. Use inline `=attr`/`=method` directly after code
4. Dependencies in `cpanfile`, not dist.ini
5. Changes file with `{{$NEXT}}` for unreleased
6. For XS+Alien modules: use `xs_alien = Alien::Foo` (auto-configures MakeMaker::Awesome)

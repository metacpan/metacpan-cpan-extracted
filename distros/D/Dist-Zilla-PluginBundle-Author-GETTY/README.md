# Dist::Zilla::PluginBundle::Author::GETTY

GETTY's Dist::Zilla and Pod::Weaver plugin bundle for CPAN distributions.

## Installation

```bash
cpanm Dist::Zilla::PluginBundle::Author::GETTY
```

## Usage

In your `dist.ini`:

```ini
name    = Your-Distribution
author  = Your Name <you@example.com>
license = Perl_5
copyright_holder = Your Name

[@Author::GETTY]
```

## Features

### Dist::Zilla Bundle

- Git-based version management with `@Git::VersionManager`
- GitHub metadata integration (repository, issues)
- Automatic changelog generation
- CPAN release workflow
- Optional IRC metadata support
- Alien distribution support
- Task distribution support

### Pod::Weaver Bundle

Custom POD commands that stay inline with your code:

| Command | Purpose |
|---------|---------|
| `=attr` | Document attributes |
| `=method` | Document methods |
| `=func` | Document functions |
| `=opt` | Document CLI options |
| `=env` | Document environment variables |
| `=event` | Document events |
| `=hook` | Document hooks |
| `=resource` | Document resources/features |
| `=example` | Document examples |
| `=seealso` | Document related modules |

Auto-generated sections: NAME, VERSION, SUPPORT, CONTRIBUTING, AUTHORS, LICENSE

## Configuration Options

### Basic Options

| Option | Default | Description |
|--------|---------|-------------|
| `author` | `GETTY` | CPAN author ID for Authority plugin |
| `release_branch` | `main` | Branch from which releases are allowed |
| `weaver_config` | `@Author::GETTY` | Pod::Weaver configuration plugin |

### Feature Toggles

| Option | Default | Description |
|--------|---------|-------------|
| `deprecated` | `0` | Mark distribution as deprecated |
| `no_github` | `0` | Use Repository instead of GithubMeta |
| `no_cpan` | `0` | Don't upload to CPAN |
| `no_changes` | `0` | Don't generate changelog entries |
| `no_podweaver` | `0` | Disable Pod::Weaver processing |
| `no_install` | `0` | Make distribution non-installable |
| `no_makemaker` | `0` | Don't use MakeMaker (auto-set for XS/Alien) |
| `no_installrelease` | `0` | Don't install after release |
| `xs` | `0` | Use ModuleBuildTiny for XS modules |

### Version Control

| Option | Default | Description |
|--------|---------|-------------|
| `manual_version` | - | Set a specific version instead of auto-versioning |
| `task` | `0` | Enable task distribution mode (uses AutoVersion) |
| `version` | `0` | Major version number for task distributions |

### Install Release

| Option | Default | Description |
|--------|---------|-------------|
| `installrelease_command` | `cpanm .` | Command to install after release |

### IRC Support

| Option | Default | Description |
|--------|---------|-------------|
| `irc` | - | IRC channel for SUPPORT section (e.g., `#perl`) |
| `irc_server` | `irc.perl.org` | IRC server hostname |

### Git::GatherDir Options

Options for controlling which files are gathered:

| Option | Default | Description |
|--------|---------|-------------|
| `gather_include_dotfiles` | `1` | Include dotfiles in distribution |
| `gather_include_untracked` | `0` | Include untracked files |
| `gather_exclude_filename` | - | Specific filenames to exclude (multi-value) |
| `gather_exclude_match` | - | Regex patterns to exclude (multi-value) |

### Run Hooks

Execute scripts at various points in the build/release cycle. All accept multiple values.

| Option | Description |
|--------|-------------|
| `run_before_build` | Run before building |
| `run_after_build` | Run after building |
| `run_before_release` | Run before releasing |
| `run_release` | Run during release |
| `run_after_release` | Run after releasing |
| `run_test` | Run during testing |

Each run option also has conditional variants:
- `run_if_trial_*` - Only run for trial releases
- `run_no_trial_*` - Only run for non-trial releases
- `run_if_release_*` - Only run during release testing
- `run_no_release_*` - Only run during non-release testing

**Placeholders:**
- `%s` - Distribution directory
- `%d` - Distribution directory
- `%a` - Archive filename
- `%n` - Distribution name
- `%v` - Version

### Alien Distribution Options

For building distributions that wrap external libraries:

| Option | Description |
|--------|-------------|
| `alien_repo` | URL to download releases from (required for Alien) |
| `alien_name` | Name of the alien package |
| `alien_bins` | Executables to install |
| `alien_pattern` | Full regex pattern for archive matching |
| `alien_pattern_prefix` | Prefix for archive pattern |
| `alien_pattern_version` | Version regex (default: `([\d\.]+)`) |
| `alien_pattern_suffix` | Suffix for archive pattern |
| `alien_msys` | Use MSYS on Windows |
| `alien_autoconf_with_pic` | Pass --with-pic to autoconf |
| `alien_isolate_dynamic` | Isolate dynamic libraries |
| `alien_version_check` | Command to check installed version |
| `alien_bin_requires` | Build dependencies (multi-value) |

## Examples

### Minimal Configuration

```ini
[@Author::GETTY]
```

### Custom Author

```ini
[@Author::GETTY]
author = YOURCPANID
```

### With IRC Support

```ini
[@Author::GETTY]
irc = #mychannel
irc_server = irc.libera.chat
```

### Private Distribution (No CPAN Upload)

```ini
[@Author::GETTY]
no_cpan = 1
no_installrelease = 1
```

### XS Module

```ini
[@Author::GETTY]
xs = 1
```

### Task Distribution

```ini
[@Author::GETTY]
task = 1
```

### Exclude Files from Distribution

```ini
[@Author::GETTY]
gather_exclude_filename = local_config.pl
gather_exclude_match = ^scratch_
```

### Run Scripts During Build

```ini
[@Author::GETTY]
run_before_build = script/generate_data.pl
run_after_build = script/validate.pl %d
run_after_release = script/announce.pl %n %v
```

### Alien Distribution

```ini
[@Author::GETTY]
alien_repo = http://example.org/releases
alien_name = mylib
alien_bins = mylib-config
alien_pattern_prefix = mylib-
alien_pattern_version = ([\d\.]+)
alien_pattern_suffix = \.tar\.gz
```

## Included Plugins

In default configuration, the bundle is equivalent to:

```ini
[Git::GatherDir]
include_dotfiles = 1

[@Filter]
-bundle = @Basic
-remove = GatherDir
-remove = PruneCruft

[MetaConfig]
[MetaJSON]
[PodSyntaxTests]

[GithubMeta]
issues = 1

[InstallRelease]
install_command = cpanm .

[Authority]
authority = cpan:GETTY
do_metadata = 1

[PodWeaver]
config_plugin = @Author::GETTY

[Git::CheckFor::CorrectBranch]
release_branch = main

[Prereqs::FromCPANfile]

[@Git::VersionManager]
; handles versioning, changelog, commits, tags, and push
```

## See Also

- [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)
- [Pod::Weaver](https://metacpan.org/pod/Pod::Weaver)
- [Dist::Zilla::PluginBundle::Git::VersionManager](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Git::VersionManager)
- [Dist::Zilla::Plugin::Alien](https://metacpan.org/pod/Dist::Zilla::Plugin::Alien)

## License

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

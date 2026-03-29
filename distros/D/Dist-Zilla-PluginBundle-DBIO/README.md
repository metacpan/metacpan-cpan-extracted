# Dist-Zilla-PluginBundle-DBIO

The standard [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin bundle
for all [DBIO](https://metacpan.org/pod/DBIO) distributions.

## Scope

- `Dist::Zilla::PluginBundle::DBIO` — the `[@DBIO]` plugin bundle
- `Pod::Weaver::PluginBundle::DBIO` — the `@DBIO` [Pod::Weaver](https://metacpan.org/pod/Pod::Weaver) config

## Usage

For new DBIO distributions:

```ini
name = DBIO-PostgreSQL-Async
author = DBIO Authors
license = Perl_5

[@DBIO]
```

For distributions derived from [DBIx::Class](https://metacpan.org/pod/DBIx::Class) code:

```ini
name = DBIO-PostgreSQL
author = DBIO Authors
license = Perl_5

[@DBIO]
heritage = 1
```

For DBIO core:

```ini
name = DBIO
author = DBIO Authors
license = Perl_5
copyright_holder = DBIO Contributors
copyright_year = 2005

[@DBIO]
core = 1
heritage = 1
```

## What It Does

- **Version**: From git tags via
  [@Git::VersionManager](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Git::VersionManager)
  for drivers (first release: 0.900000), from `$VERSION` via
  [VersionFromMainModule](https://metacpan.org/pod/Dist::Zilla::Plugin::VersionFromMainModule)
  for core
- **Changes**: [NextRelease](https://metacpan.org/pod/Dist::Zilla::Plugin::NextRelease)
  replaces `{{$NEXT}}` with version + date on release
- **POD**: [PodWeaver](https://metacpan.org/pod/Dist::Zilla::Plugin::PodWeaver) with
  `=attr` and `=method` collectors, auto-generated NAME, VERSION, AUTHORS, COPYRIGHT
- **Copyright**: `heritage = 0` (default) — DBIO Authors only;
  `heritage = 1` — adds DBIx::Class Authors attribution
- **GitHub**: Metadata and issue tracking via
  [GithubMeta](https://metacpan.org/pod/Dist::Zilla::Plugin::GithubMeta)
- **Build**: [MakeMaker](https://metacpan.org/pod/Dist::Zilla::Plugin::MakeMaker) for
  drivers, [MakeMaker::Awesome](https://metacpan.org/pod/Dist::Zilla::Plugin::MakeMaker::Awesome)
  for core
- **Release**: Git tag + push via
  [@Git::VersionManager](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Git::VersionManager)
- **Bootstrap**: Uses
  [Bootstrap::lib](https://metacpan.org/pod/Dist::Zilla::Plugin::Bootstrap::lib)
  to build itself

## Copyright

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

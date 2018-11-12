# NAME

Dist::Zilla::Plugin::Generate::ManifestSkip - Generate a MANIFEST.SKIP file for your distribution

# VERSION

version v0.1.5

# SYNOPSIS

In your `dist.ini` file:

```
[Generate::ManifestSkip]
:version = v0.1.3
```

# DESCRIPTION

This plugin will generate a `MANIFEST.SKIP` file for your
distribution, and then prune any files that match.

# ATTRIBUTES

## skipfile

This is the name of the file to generate. It defaults to `MANIFEST.SKIP`.

## add

This adds a regular expression to the ["skipfile"](#skipfile).

By defaut, the following files are added to the skipfile:

- `\.build/`
- `\.mailmap$`
- `{$dist_name}-.*/`
- `{$dist_name}-.*\.tar\.gz`
- `perltidy\.(LOG|ERR)'`
- `fatlib/`

where `$dist_name` is the name of the distribution.

If the distribution has an `alienfile`, then `_alien/` will be added,

If the distribution has a `cpanfile`, then `cpanfile\.snapshot$`
will be added.

## remove

This removes a regular expression from the ["skipfile"](#skipfile). Note that it
must exactly match the expression used by [Module::Manifest::Skip](https://metacpan.org/pod/Module::Manifest::Skip).

By default, the following files are already removed from the skipfile:

- `^MANIFEST\.SKIP$`
- `^dist\.ini$`
- `^weaver\.ini$`
- `^xt/`

If you want them to be excluded from your distribution, then specify
them with ["add"](#add).

# SEE ALSO

[Module::Manifest::Skip](https://metacpan.org/pod/Module::Manifest::Skip)

[Dist::Zilla::Plugin::ManifestSkip](https://metacpan.org/pod/Dist::Zilla::Plugin::ManifestSkip)

# SOURCE

The development version is on github at [https://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip](https://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip)
and may be cloned from [git://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip.git](git://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip/issues](https://github.com/robrwo/Dist-Zilla-Plugin-Generate-ManifestSkip/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of the code and tests have been borrowed from [Dist::Zilla::Plugin::InstallGuide](https://metacpan.org/pod/Dist::Zilla::Plugin::InstallGuide).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# NAME

Dist::Zilla::Plugin::UsefulReadme - generate a README file with the useful bits

# SYNOPSIS

In the `dist.ini`

```
[UsefulReadme]
type     = markdown
filename = README.md
phase    = build
location = build
section = name
section = synopsis
section = description
section = requirements
section = installation
section = bugs
section = source
section = author
section = copyright and license
section = see also
```

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla) plugin to filter the main module POD to generate a `README` file.  It allows developers to
determine which sections are incorporated into the `README` rather than dumping the entire main module documentation.

This also supports including special sections for showing the most recent entry in the `Changes` file, showing the
runtime requirements, and including installation instructions.

This was written as a successor to [Pod::Readme](https://metacpan.org/pod/Pod%3A%3AReadme) that works better with [Pod::Weaver](https://metacpan.org/pod/Pod%3A%3AWeaver).

# RECENT CHANGES

Changes for version v0.4.1 (2025-08-06)

- Tests
    - Fix prerequisites for tests.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [CPAN::Changes::Parser](https://metacpan.org/pod/CPAN%3A%3AChanges%3A%3AParser) version 0.500002 or later
- [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla) version 6.003 or later
- [Hash::Ordered](https://metacpan.org/pod/Hash%3A%3AOrdered) version 0.005 or later
- [List::Util](https://metacpan.org/pod/List%3A%3AUtil) version 1.33 or later
- [Module::Metadata](https://metacpan.org/pod/Module%3A%3AMetadata) version 1.000015 or later
- [Module::Runtime](https://metacpan.org/pod/Module%3A%3ARuntime)
- [Moose](https://metacpan.org/pod/Moose)
- [MooseX::MungeHas](https://metacpan.org/pod/MooseX%3A%3AMungeHas)
- [PPI::Token::Pod](https://metacpan.org/pod/PPI%3A%3AToken%3A%3APod)
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny)
- [Perl::PrereqScanner](https://metacpan.org/pod/Perl%3A%3APrereqScanner) version 1.024 or later
- [Pod::Elemental](https://metacpan.org/pod/Pod%3A%3AElemental)
- [Pod::Simple](https://metacpan.org/pod/Pod%3A%3ASimple) version 3.23 or later
- [Pod::Weaver::Role::Section](https://metacpan.org/pod/Pod%3A%3AWeaver%3A%3ARole%3A%3ASection)
- [Types::Common](https://metacpan.org/pod/Types%3A%3ACommon)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Dist::Zilla::Plugin::UsefulReadme
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme/issues](https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme](https://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme)
and may be cloned from [git://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme.git](git://github.com/robrwo/perl-Dist-Zilla-Plugin-UsefulReadme.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of this code was adapted from similar code in [Dist::Zilla::Plugin::ReadmeAnyFromPod](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AReadmeAnyFromPod) and
[Dist::Zilla::Plugin::Readme::Brief](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AReadme%3A%3ABrief).

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# SEE ALSO

[Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla)

[Pod::Weaver](https://metacpan.org/pod/Pod%3A%3AWeaver)

[Pod::Readme](https://metacpan.org/pod/Pod%3A%3AReadme)

[Dist::Zilla::Plugin::Readme::Brief](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AReadme%3A%3ABrief)

[Dist::Zilla::Plugin::ReadmeAnyFromPod](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AReadmeAnyFromPod)

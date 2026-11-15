# NAME

Dist::Zilla::Plugin::CodeOfConduct - add a Code of Conduct to a distribution

# SYNOPSIS

In the `dist.ini`:

```
[CodeOfConduct]
-version = v0.4.0
policy   = Contributor_Covenant_1.4
name     = Perl-Project-Name
contact  = author@example.org
filename = CODE_OF_CONDUCT.md
```

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla) plugin to add a Code of Conduct to a distribution, using [Software::Policy::CodeOfConduct](https://metacpan.org/pod/Software%3A%3APolicy%3A%3ACodeOfConduct).

# RECENT CHANGES

Changes for version v0.1.2 (2026-11-14)

- Documentation
    - Updated the SUPPORT section to clarify the minimum Perl version.
    - Added a SEE ALSO section for related modules.
    - Updated copyright year.
    - Updated maintainer email address.
    - Add doap.xml.
    - Fixed SOURCE URL in the README.
- Tests
    - Added author tests.
- Toolchain
    - Added a GitHub workflow to test the distribution.
    - Sign distributions with sigstore instead of Module::Signature.
    - Static installs are enabled.
    - Updated Dist::Zilla configuration.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Dist::Zilla::File::InMemory](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3AFile%3A%3AInMemory)
- [Dist::Zilla::Pragmas](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APragmas)
- [Dist::Zilla::Role::FileGatherer](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFileGatherer)
- [Dist::Zilla::Role::FilePruner](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFilePruner)
- [Dist::Zilla::Role::PrereqSource](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3APrereqSource)
- [Email::Address](https://metacpan.org/pod/Email%3A%3AAddress) version 1.910 or later
- [Moose](https://metacpan.org/pod/Moose)
- [MooseX::Types::Common::String](https://metacpan.org/pod/MooseX%3A%3ATypes%3A%3ACommon%3A%3AString)
- [MooseX::Types::Moose](https://metacpan.org/pod/MooseX%3A%3ATypes%3A%3AMoose)
- [MooseX::Types::Perl](https://metacpan.org/pod/MooseX%3A%3ATypes%3A%3APerl)
- [Software::Policy::CodeOfConduct](https://metacpan.org/pod/Software%3A%3APolicy%3A%3ACodeOfConduct) version v0.4.0 or later
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Dist::Zilla::Plugin::CodeOfConduct
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

This module requires Perl v5.20 or later, based on the minimum Perl supported by [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla).

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct/issues](https://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct](https://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct)
and may be cloned from [https://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct.git](https://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025-2026 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# SEE ALSO

[Dist::Zilla::Plugin::ContributorCovenant](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AContributorCovenant)

[Software::Policy::CodeOfConduct](https://metacpan.org/pod/Software%3A%3APolicy%3A%3ACodeOfConduct)

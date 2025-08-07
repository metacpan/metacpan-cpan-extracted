# NAME

Dist::Zilla::Plugin::Test::MixedScripts - author tests to ensure there is no mixed Unicode

# SYNOPSIS

In the `dist.ini` add:

```
[Test::MixedScripts]
; authordep Test::MixedScripts
script = Latin
script = Common
```

# DESCRIPTION

This generates an author [Test::MixedScripts](https://metacpan.org/pod/Test%3A%3AMixedScripts).

This is an extension of [Dist::Zilla::Plugin::InlineFiles](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AInlineFiles), providing the file `xt/author/mixed-unicode-scripts.t` for
testing against mixed Unicode scripts that are potentially confusing or malicious.

For example, the text for the domain names `оnе.example.com` and `one.example.com` look indistinguishable in many fonts,
but the first one has Cyrillic letters.  If your software interacted with a service on the second domain, then someone
can operate a service on the first domain and attempt to fool developers into using their domain instead.

This might be through a malicious patch submission, or even text from an email or web page that they have convinced a
developer to copy and paste into their code.

# RECENT CHANGES

Changes for version v0.2.0 (2025-08-06)

- Incompatible Changes
    - Increased the minimum Perl version to v5.20, since that is what Dist::Zilla now requires.
- Documentation
    - Fixed errors in README.
    - Removed separate INSTALL file.
    - Updated SYNOPSIS.
- Tests
    - Moved author tests into the xt directory.
- Toolchain
    - Undid some changes to Dist::Zilla configuration.
    - Set up GitHub workflow for testing.
    - Ensure local-lib is not included in distribution.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Data::Section](https://metacpan.org/pod/Data%3A%3ASection) version 0.004 or later
- [Dist::Zilla::File::InMemory](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3AFile%3A%3AInMemory)
- [Dist::Zilla::Role::FileFinderUser](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFileFinderUser)
- [Dist::Zilla::Role::FileGatherer](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFileGatherer)
- [Dist::Zilla::Role::FileMunger](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFileMunger)
- [Dist::Zilla::Role::PrereqSource](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3APrereqSource)
- [Dist::Zilla::Role::TextTemplate](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3ATextTemplate)
- [List::Util](https://metacpan.org/pod/List%3A%3AUtil) version 1.45 or later
- [Moose](https://metacpan.org/pod/Moose)
- [Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose%3A%3AUtil%3A%3ATypeConstraints)
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny)
- [Sub::Exporter::ForMethods](https://metacpan.org/pod/Sub%3A%3AExporter%3A%3AForMethods)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.20.0 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Dist::Zilla::Plugin::Test::MixedScripts
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

This module requires Perl v5.16 or later.  Future releases may only support Perl versions released in the last ten
years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts/issues](https://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts](https://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts)
and may be cloned from [git://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts.git](git://github.com/robrwo/perl-Dist-Zilla-Plugin-Test-MixedScripts.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

This code was based on [Dist::Zilla::Plugin::Test::EOL](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3ATest%3A%3AEOL) by Florian Ragwitz <rafl@debian.org>, Caleb Cushing
<xenoterracide@gmail.com> and Karen Etheridge <ether@cpan.org>.

# CONTRIBUTOR

Graham Knop <haarg@haarg.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

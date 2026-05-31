# NAME

Dist::Zilla::Plugin::AutomationPolicy - add an automation policy to a distribution

# SYNOPSIS

In the `dist.ini`:

```
[AutomationPolicy]
-version    = v0.2.2
description = The automation policy for Foo-Bar-Baz
template    = human_supervised
models      = claude-opus-4-7
models      = claude-opus-4-8
```

# DESCRIPTION

This plugin will create a machine-readable `CPAN-META/automation-policy.json` file in your distribution, using
[Dist::AutomationPolicy](https://metacpan.org/pod/Dist%3A%3AAutomationPolicy).

It allows authors to specify the use of automation in generating their modules, and what automated contributions they
will accept.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Dist::AutomationPolicy](https://metacpan.org/pod/Dist%3A%3AAutomationPolicy)
- [Dist::Zilla::File::InMemory](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3AFile%3A%3AInMemory)
- [Dist::Zilla::Pragmas](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APragmas)
- [Dist::Zilla::Role::FileGatherer](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFileGatherer)
- [Dist::Zilla::Role::FilePruner](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFilePruner)
- [Dist::Zilla::Role::PrereqSource](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3APrereqSource)
- [Moose](https://metacpan.org/pod/Moose)
- [MooseX::Types::Moose](https://metacpan.org/pod/MooseX%3A%3ATypes%3A%3AMoose)
- [MooseX::Types::Perl](https://metacpan.org/pod/MooseX%3A%3ATypes%3A%3APerl)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.24.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Dist::Zilla::Plugin::AutomationPolicy
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

This module requires Perl v5.24 or later, based on the minimum Perl supported by [Dist::Zilla](https://metacpan.org/pod/Dist%3A%3AZilla).

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Dist-Zilla-Plugin-AutomationPolicy/issues](https://github.com/robrwo/perl-Dist-Zilla-Plugin-AutomationPolicy/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Dist-Zilla-Plugin-AutomationPolicy](https://github.com/robrwo/perl-Dist-Zilla-Plugin-AutomationPolicy)
and may be cloned from [https://github.com/robrwo/perl-Dist-Zilla-Plugin-AutomationPolicy.git](https://github.com/robrwo/perl-Dist-Zilla-Plugin-AutomationPolicy.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

# CONTRIBUTOR

Leon Timmermans <fawaka@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

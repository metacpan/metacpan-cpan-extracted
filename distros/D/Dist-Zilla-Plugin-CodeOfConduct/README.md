# NAME

Dist::Zilla::Plugin::CodeOfConduct - add a Code of Conduct to a distribution

# VERSION

version v0.1.0

# SYNOPSIS

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

# CONFIGURATION OPTIONS

Any options that do not start with a hyphen (like "-version") will be passed to [Software::Policy::CodeOfConduct](https://metacpan.org/pod/Software%3A%3APolicy%3A%3ACodeOfConduct).

## name

This is the name of the project.

If you omit it, the distribution name will be used.

## contact

This is a code of conduct contact. It can be a URL or e-mail address.

If you omit it, the e-mail address of the first author will be used.

## policy

This is the policy template that you want to use.

If you omit it, the ["policy" in Software::Policy::CodeOfConduct](https://metacpan.org/pod/Software%3A%3APolicy%3A%3ACodeOfConduct#policy) default will be used.

## -version

You can specify a minimum version of [Software::Policy::CodeOfConduct](https://metacpan.org/pod/Software%3A%3APolicy%3A%3ACodeOfConduct), in case you require a later version than the
default (v0.4.0).

## filename

This is the filename that the policy will be saved as.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.20 or later.  Future releases may only support Perl versions released in the last ten
years.

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
and may be cloned from [git://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct.git](git://github.com/robrwo/perl-Dist-Zilla-Plugin-CodeOfConduct.git)

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# NAME

Dist::Zilla::Plugin::Test::MixedScripts - author tests to ensure there is no mixed Unicode

# VERSION

version v0.1.4

# DESCRIPTION

This generates an author [Test::MixedScripts](https://metacpan.org/pod/Test%3A%3AMixedScripts).

This is an extension of [Dist::Zilla::Plugin::InlineFiles](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AInlineFiles), providing the file `xt/author/mixed-unicode-scripts.t` for
testing against mixed Unicode scripts that are potentially confusing or malicious.

For example, the text for the domain names `оnе.example.com` and `one.example.com` look indistinguishable in many fonts,
but the first one has Cyrillic letters.  If your software interacted with a service on the second domain, then someone
can operate a service on the first domain and attempt to fool developers into using their domain instead.

This might be through a malicious patch submission, or even text from an email or web page that they have convinced a
developer to copy and paste into their code.

# CONFIGURATION OPTIONS

## filename

This is the filename of the test to add. Defaults to `xt/author/mixed-unicode-scripts.t`.

## finder

This is the name of a `FileFinder` for finding files to check. The default value is `:InstallModules`, `:ExecFiles` (see also
[Dist::Zilla::Plugin::ExecDir](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AExecDir)) and `:TestFiles`.

This option can be used more than once.

Other predefined finders are listed in "default\_finders" in [Dist::Zilla::Role::FileFinderUser](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3ARole%3A%3AFileFinderUser).
You can define your own with the [FileFinder::ByName plugin](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3AFileFinder%3A%3AByName).

## file

This is a filename to also test, in addition to any files found earlier.

This option can be repeated to specify multiple additional files.

## exclude

This is a regular expression of filenames to exclude.

This option can be repeated to specify multiple patterns.

## script

This specifies the scripts to test for.  If none are specified, it defaults to the defaults for [Test::MixedScripts](https://metacpan.org/pod/Test%3A%3AMixedScripts).

# KNOWN ISSUES

The default ["finder"](#finder) does not include XS-related files. You will have to add them manually using the ["file"](#file) option,
for example, in the `dist.ini`:

```
[Test::MixedScripts]
file = XS.xs
file = XS.c
```

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

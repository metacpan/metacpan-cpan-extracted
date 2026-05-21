# NAME

Dist::AutomationPolicy - generate and parse distribution automation policies

# SYNOPSIS

To create an automation policy file:

```perl
use Dist::AutomationPolicy;
use Path::Tiny qw( path ) 0.130;

my $pol = Dist::AutomationPolicy->new(
    distribution            => "Dist-AutomationPolicy-v0.1.0",
    code_generation         => "toolchain",
    automated_contributions => "issue",
    automated_actions       => "code_request",
    models                  => [ "claude-sonnet-4.6" ],
);

if ( $pol->validate ) {
    my $path = path( ".", $pol->filename ); # "CPAN-META/automation-policy.json"
    $path->parent->mkdir;
    $path->spew_raw( $pol->to_json );
}
```

To read an automation policy file:

```perl
my $path = path( "CPAN-META/automation-policy.json" );

my $pol  = Dist::AutomationPolicy->from_json( json => $path->slurp_raw );
```

# DESCRIPTION

This module allows package maintainers to specify machine-readable metadata about their policies regarding automation:
how code is generated,
whether automated contributions are allowed,
and whether there are automated actions run by the maintainers.

This is separate but complimentary to including an `AI_POLICY.md` or `CONTRIBUTING.md` file in the distribution.

# RECENT CHANGES

Changes for version v0.2.2 (2026-05-21)

- Bug Fixes
    - Fix bug when JSON::XS is used as the backend.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir)
- [JSON](https://metacpan.org/pod/JSON)
- [JSON::Schema::Validate](https://metacpan.org/pod/JSON%3A%3ASchema%3A%3AValidate) version v0.7.0 or later
- [Moo](https://metacpan.org/pod/Moo)
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) version 0.130 or later
- [PerlX::Maybe](https://metacpan.org/pod/PerlX%3A%3AMaybe)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean)
- [perl](https://metacpan.org/pod/perl) version v5.24.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Dist::AutomationPolicy
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

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Dist-AutomationPolicy/issues](https://github.com/robrwo/perl-Dist-AutomationPolicy/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Dist-AutomationPolicy](https://github.com/robrwo/perl-Dist-AutomationPolicy)
and may be cloned from [https://github.com/robrwo/perl-Dist-AutomationPolicy.git](https://github.com/robrwo/perl-Dist-AutomationPolicy.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The ideas for this policy emerged from discussions at the 2026 Perl Toolchain Summit.

Thanks to
Leon Timmermans,
Nicolas Rochelemagne,
Salve J. Nilsen,
Thibault Duponchelle,
Timothy Legge
Todd Rinaldo,
and others for suggestions and feedback.

# CONTRIBUTOR

Leon Timmermans <fawaka@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

# SEE ALSO

[https://github.com/CPAN-Security/cpan-metadata-v3/blob/main/automation-policy.md](https://github.com/CPAN-Security/cpan-metadata-v3/blob/main/automation-policy.md)

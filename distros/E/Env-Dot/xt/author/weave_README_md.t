#!perl

use strict;
use warnings;

use Test2::V1 qw( -utf8 -x );
use Test2::Plugin::BailOnFail;
use English qw( -no_match_vars );
use Path::Tiny qw( path );

T2->ok(path('README.md')->is_file(), 'File README.md exists');

my $got = path('README.md')->slurp_utf8 =~ s/[[:space:]]+$//rmsx;

my (@got_lines, @expected_lines);
foreach (split qr{\R}msx, $got) { push @got_lines, $_; }
do {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $expected = <DATA>;
    $expected =~ s/[[:space:]]+$//msx;
    foreach (split qr{\R}msx, $expected) { push @expected_lines, $_; }
};
T2->is(\@got_lines, \@expected_lines, 'File README.md matches expected content');

T2->done_testing;

__DATA__
[![License: Artistic-2.0][perlLicenseBadge]](https://opensource.org/licenses/Artistic-2.0)
[![CPAN Version](https://img.shields.io/cpan/v/Env-Dot)](https://metacpan.org/dist/Env-Dot)
[![GitHub release (latest by date)][latestReleaseBadge]](https://github.com/mikkoi/env-dot/releases/latest)
[![GitHub Release Date][releaseDateBadge]](https://github.com/mikkoi/env-dot/releases)

[![kwalitee][kwaliteeBadge]](https://cpants.cpanauthors.org/dist/Env-Dot)
[![codecov][codecovBadge]](https://codecov.io/gh/mikkoi/env-dot)
[![Coverage Status][coverallsBadge]](https://coveralls.io/github/mikkoi/env-dot?branch=main)
[![DeepWiki][deepWikiBadge]](https://deepwiki.com/mikkoi/env-dot)

[![GH Actions: Linux Build][ciLinux]](https://github.com/mikkoi/env-dot/actions/workflows/linux.yml)
[![GH Actions: Windows Build][ciWindows]](https://github.com/mikkoi/env-dot/actions/workflows/windows.yml)
[![GitHub repo size][repoSizeBadge]](https://github.com/mikkoi/env-dot/archive/refs/heads/main.zip)
[![GitHub pull requests][githubPullRequestsBadge]](https://github.com/mikkoi/env-dot/pulls)

# Env-Dot

Read .env file and turn its content into environment variables for different shells. Module and executable.


# VERSION

0.023


# SYNOPSIS

    # If your dotenv file is `.env`:
    use Env::Dot;
    # or
    use Env::Dot 'read';

    print $ENV{'VAR_DEFINED_IN_DOTENV_FILE'};

    # If you have a dotenv file in a different filepath:
    use Env::Dot read => {
        dotenv_file => '/other/path/my_environment.env',
    };

    # When you absolutely require `.env` file:
    use Env::Dot read => {
        required => 1,
    };


# DESCRIPTION

**envdot** reads your `.env` file and converts it
into environment variable commands suitable for
different shells (shell families): **sh**, **csh** and **fish**.

`.env` files can be written in different flavors.
**envdot** supports the often used **sh** compatible flavor and
the **docker** flavor which are not compatible with each other.

If you have several `.env` files, you can read them in at one go
with the help of the environment variable **ENVDOT\_FILEPATHS**.
Separate the full paths with '**:**' character.

Env::Dot will load the files in the **reverse order**,
starting from the last. This is the same ordering as used in **PATH** variable:
the first overrules the following ones, that is, when reading from the last path
to the first path, if same variable is present in more than one file, the later
one replaces the one already read.

If you have set the variable ENVDOT\_FILEPATHS, then **envdot** will use that.
Otherwise, it uses the command line parameter.
If no parameter, then default value is used. Default is the file
`.env` in the current directory.


## INSTALLATION

### Packaging

[![Packaging status](https://repology.org/badge/vertical-allrepos/env-dot.svg)](https://repology.org/project/env-dot/versions)

### CLI interface without dependencies

The **envdot** command is also available
as self contained executable.
You can download it and run it as it is without
additional installation of CPAN packages.
Of course, you still need Perl, but Perl comes with any
normal Linux installation.

This can be convenient if you want to, for instance,
include **envdot** in a docker container build.

    curl -LSs -o envdot https://raw.githubusercontent.com/mikkoi/env-dot/main/envdot.self-contained
    chmod +x ./envdot


## 💻 Contributors

[![GitHub Contributors Image][githubContributorsBadge]](https://github.com/mikkoi/env-dot/graphs/contributors)


# LICENSE

This software is copyright (c) 2026 by Mikko Koivunalho <mikkoi@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself:

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

The complete licenses are in the files LICENSE-Artistic-2.0 and LICENSE-GPL-3
within this repository. If these files are missing, they can be downloaded
from the following urls:

    * https://www.gnu.org/licenses/
    * https://www.perlfoundation.org/artistic-license-20.html


[perlLicenseBadge]: https://img.shields.io/badge/License-Perl-0298c3.svg
[kwaliteeBadge]: https://cpants.cpanauthors.org/dist/Env-Dot.svg
[codecovBadge]: https://codecov.io/gh/mikkoi/env-dot/graph/badge.svg?token=KH15ROS3GZ
[coverallsBadge]: https://coveralls.io/repos/github/mikkoi/env-dot/badge.svg?branch=main
[githubContributorsBadge]: https://contrib.rocks/image?repo=mikkoi/env-dot&max=36&columns=12&anon=1
[ciBadge]: https://github.com/mikkoi/env-dot/actions/workflows/ci.yml/badge.svg
[ciLink]: https://github.com/mikkoi/env-dot/actions/workflows/ci.yml
[ciLinux]: https://github.com/mikkoi/env-dot/actions/workflows/linux.yml/badge.svg?event=push&branch=main
[ciWindows]: https://github.com/mikkoi/env-dot/actions/workflows/windows.yml/badge.svg?event=push&branch=main
[latestReleaseBadge]: https://img.shields.io/github/v/release/mikkoi/env-dot
[releaseDateBadge]: https://img.shields.io/github/release-date/mikkoi/env-dot
[repoSizeBadge]: https://img.shields.io/github/repo-size/mikkoi/env-dot
[totalDownloadsBadge]: https://img.shields.io/github/downloads/mikkoi/env-dot/total
[githubLicenseBadge]: https://img.shields.io/github/license/mikkoi/env-dot
[githubIssuesBadge]: https://img.shields.io/github/issues/mikkoi/env-dot
[githubPullRequestsBadge]: https://img.shields.io/github/issues-pr/mikkoi/env-dot
[deepWikiBadge]: https://img.shields.io/badge/DeepWiki-mikkoi%2Fenv--dot-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==

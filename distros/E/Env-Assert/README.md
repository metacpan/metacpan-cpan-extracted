[![License: Artistic-2.0][perlLicenseBadge]](https://opensource.org/licenses/Artistic-2.0)
[![CPAN Version](https://img.shields.io/cpan/v/Env-Assert)](https://metacpan.org/dist/Env-Assert)
[![GitHub release (latest by date)][latestReleaseBadge]](https://github.com/mikkoi/env-assert/releases/latest)
[![GitHub Release Date][releaseDateBadge]](https://github.com/mikkoi/env-assert/releases)

[![kwalitee][kwaliteeBadge]](https://cpants.cpanauthors.org/dist/Env-Assert)
[![codecov][codecovBadge]](https://codecov.io/gh/mikkoi/env-assert)
[![Coverage Status][coverallsBadge]](https://coveralls.io/github/mikkoi/env-assert?branch=main)
[![DeepWiki][deepWikiBadge]](https://deepwiki.com/mikkoi/env-assert)

[![GH Actions: Linux Build][ciLinux]](https://github.com/mikkoi/env-assert/actions/workflows/linux.yml)
[![GH Actions: Windows Build][ciWindows]](https://github.com/mikkoi/env-assert/actions/workflows/windows.yml)
[![GitHub repo size][repoSizeBadge]](https://github.com/mikkoi/env-assert/archive/refs/heads/main.zip)
[![GitHub pull requests][githubPullRequestsBadge]](https://github.com/mikkoi/env-assert/pulls)

# Env-Assert

Ensure that the environment variables match what is requested, or abort. Module and executable.


0.018


# SYNOPSIS

    use Env::Assert 'assert';
    # or:
    use Env::Assert assert => {
        envdesc_file => 'another-envdesc',
        break_at_first_error => 1,
    };

    # .envdesc file:
    # MY_VAR=.+

    # use any verified environment variable
    say $ENV{MY_VAR};

    # You can inline the envdesc file:
    use Env::Assert assert => {
        exact => 1,
        envdesc => <<'EOF'
    NUMERIC_VAR=^[[:digit:]]+$
    TIME_VAR=^\d{2}:\d{2}:\d{2}$
    EOF
    };


# DESCRIPTION

**envassert** checks that your runtime environment, as defined
with environment variables, matches with what you want.

You can define your required environment in a file.
Default file is `.envassert` but you can use any file.

It is advantageous to use **envassert** for example when running
a container. If you check your environment for missing or
wrongly defined environment variables at the beginning of
the container run, your container will fail sooner instead
of in a later point in execution when the variables are needed.

## Errors

There are three kinds of errors:

- ENV\_ASSERT\_MISSING\_FROM\_ENVIRONMENT

    "Variable &lt;var\_name> is missing from environment"

- ENV\_ASSERT\_INVALID\_CONTENT\_IN\_VARIABLE

    "Variable &lt;var\_name> has invalid content"

- ENV\_ASSERT\_MISSING\_FROM\_DEFINITION

    "Variable &lt;var\_name> is missing from description"

    This error will only be reported if you have set
    the special option **env:exact**. See below.

## Environment Description Language

Environment is described in file `.envdesc`.
Environment description file is a Unix shell compatible file,
similar to a `.env` file.

### `.envdesc` Format

In `.envdesc` file there is only environment variables, comments
meta commands or empty rows.
Example:

    # Required env
    ## envassert (opts: env:exact)
    FILENAME=^[[:word:]]{1,}$

Env var name is followed by a regular expression. The regexp is
an extended Perl regular expression without quotation marks.
One env var and its descriptive regexp use one row.

A comment begins at the beginning of the row and uses the whole row.
It start with '#' character.

Two comment characters and the word **envassert** at the beginning of the row
mean this is an **envassert** meta command.
You can specify different environment related options with these commands.

Supported options:

- env:exact, default: 0

    The option _env:exact_ means that all allowed env variables
    are described in this file. Any unknown env var causes an error
    when verifying.

    By default, this option if off (false).

- var:required, default: 1

    The option _var:required_ means that the next environment
    variable defined is required. This is the default assumption.
    If you set this to "0", the next var definition will became optional.
    If the variable is present in the current environment,
    its content will be checked. If it is not present, it will not be checked.

    This is also applies to situation when **env:exact** is true.
    If the variable is missing, it is will not cause an error.

    By default, this option if on (true).

## CLI interface without dependencies

The `envassert` command is also available
as self contained executable.
You can download it and run it as it is without
additional installation of CPAN packages.
Of course, you still need Perl, but Perl comes with any
normal Linux installation.

This can be convenient if you want to, for instance,
include `envassert` in a docker container build.

    curl -LSs -o envassert https://raw.githubusercontent.com/mikkoi/env-assert/main/envassert.self-contained
    chmod +x ./envassert


## INSTALLATION

### Packaging

[![Packaging status](https://repology.org/badge/vertical-allrepos/env-assert.svg)](https://repology.org/project/env-assert/versions)

### CLI interface without dependencies

The **envassert** command is also available
as self contained executable.
You can download it and run it as it is without
additional installation of CPAN packages.
Of course, you still need Perl, but Perl comes with any
normal Linux installation.

This can be convenient if you want to, for instance,
include **envassert** in a docker container build.

    curl -LSs -o envassert https://raw.githubusercontent.com/mikkoi/env-assert/main/envassert.self-contained
    chmod +x ./envassert


## 💻 Contributors

[![GitHub Contributors Image][githubContributorsBadge]](https://github.com/mikkoi/env-assert/graphs/contributors)


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
[kwaliteeBadge]: https://cpants.cpanauthors.org/dist/Env-Assert.svg
[codecovBadge]: https://codecov.io/gh/mikkoi/env-assert/graph/badge.svg?token=WSOLKXXEVK
[coverallsBadge]: https://coveralls.io/repos/github/mikkoi/env-assert/badge.svg?branch=main
[githubContributorsBadge]: https://contrib.rocks/image?repo=mikkoi/env-assert&max=36&columns=12&anon=1
[ciBadge]: https://github.com/mikkoi/env-assert/actions/workflows/ci.yml/badge.svg
[ciLink]: https://github.com/mikkoi/env-assert/actions/workflows/ci.yml
[ciLinux]: https://github.com/mikkoi/env-assert/actions/workflows/linux.yml/badge.svg?event=push&branch=main
[ciWindows]: https://github.com/mikkoi/env-assert/actions/workflows/windows.yml/badge.svg?event=push&branch=main
[latestReleaseBadge]: https://img.shields.io/github/v/release/mikkoi/env-assert
[releaseDateBadge]: https://img.shields.io/github/release-date/mikkoi/env-assert
[repoSizeBadge]: https://img.shields.io/github/repo-size/mikkoi/env-assert
[totalDownloadsBadge]: https://img.shields.io/github/downloads/mikkoi/env-assert/total
[githubLicenseBadge]: https://img.shields.io/github/license/mikkoi/env-assert
[githubIssuesBadge]: https://img.shields.io/github/issues/mikkoi/env-assert
[githubPullRequestsBadge]: https://img.shields.io/github/issues-pr/mikkoi/env-assert
[deepWikiBadge]: https://img.shields.io/badge/DeepWiki-mikkoi%2Fenv--assert-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==

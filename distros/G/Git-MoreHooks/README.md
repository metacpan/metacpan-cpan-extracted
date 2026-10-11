[![License: Artistic-2.0][perlLicenseBadge]](https://opensource.org/licenses/Artistic-2.0)
[![CPAN Version](https://img.shields.io/cpan/v/Git-MoreHooks)](https://metacpan.org/dist/Git-MoreHooks)
[![GitHub release (latest by date)][latestReleaseBadge]](https://github.com/mikkoi/git-morehooks/releases/latest)
[![GitHub Release Date][releaseDateBadge]](https://github.com/mikkoi/git-morehooks/releases)

[![kwalitee][kwaliteeBadge]](https://cpants.cpanauthors.org/dist/Git-MoreHooks)
[![codecov][codecovBadge]](https://codecov.io/gh/mikkoi/git-morehooks)
[![Coverage Status][coverallsBadge]](https://coveralls.io/github/mikkoi/git-morehooks?branch=main)
[![DeepWiki][deepWikiBadge]](https://deepwiki.com/mikkoi/git-morehooks)

[![GH Actions: Linux Build][ciLinux]](https://github.com/mikkoi/git-morehooks/actions/workflows/linux.yml)
[![GH Actions: Windows Build][ciWindows]](https://github.com/mikkoi/git-morehooks/actions/workflows/windows.yml)
[![GitHub repo size][repoSizeBadge]](https://github.com/mikkoi/git-morehooks/archive/refs/heads/main.zip)
[![GitHub pull requests][githubPullRequestsBadge]](https://github.com/mikkoi/git-morehooks/pulls)

# Git-MoreHooks

More plugins (Git hooks) for package Git::Hooks.


0.020


# SYNOPSIS

Use package via [Git::Hooks](https://metacpan.org/pod/Git%3A%3AHooks) interface (git config file).





## 💻 Contributors

[![GitHub Contributors Image][githubContributorsBadge]](https://github.com/mikkoi/git-morehooks/graphs/contributors)


# LICENSE

This software is copyright (c) 2026 by 'Mikko Koivunalho <mikkoi@cpan.org>'.

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
[kwaliteeBadge]: https://cpants.cpanauthors.org/dist/Git-MoreHooks.svg
[codecovBadge]: https://codecov.io/gh/mikkoi/git-morehooks/graph/badge.svg?token=9ztN77F2bZ
[coverallsBadge]: https://coveralls.io/repos/github/mikkoi/git-morehooks/badge.svg?branch=main
[githubContributorsBadge]: https://contrib.rocks/image?repo=mikkoi/git-morehooks&max=36&columns=12&anon=1
[ciBadge]: https://github.com/mikkoi/git-morehooks/actions/workflows/ci.yml/badge.svg
[ciLink]: https://github.com/mikkoi/git-morehooks/actions/workflows/ci.yml
[ciLinux]: https://github.com/mikkoi/git-morehooks/actions/workflows/linux.yml/badge.svg?event=push&branch=main
[ciWindows]: https://github.com/mikkoi/git-morehooks/actions/workflows/windows.yml/badge.svg?event=push&branch=main
[latestReleaseBadge]: https://img.shields.io/github/v/release/mikkoi/git-morehooks
[releaseDateBadge]: https://img.shields.io/github/release-date/mikkoi/git-morehooks
[repoSizeBadge]: https://img.shields.io/github/repo-size/mikkoi/git-morehooks
[totalDownloadsBadge]: https://img.shields.io/github/downloads/mikkoi/git-morehooks/total
[githubLicenseBadge]: https://img.shields.io/github/license/mikkoi/git-morehooks
[githubIssuesBadge]: https://img.shields.io/github/issues/mikkoi/git-morehooks
[githubPullRequestsBadge]: https://img.shields.io/github/issues-pr/mikkoi/git-morehooks
[deepWikiBadge]: https://img.shields.io/badge/DeepWiki-mikkoi%2Fgit--morehooks-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==

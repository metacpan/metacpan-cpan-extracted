[![License: Artistic-2.0](https://img.shields.io/badge/License-Perl-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)
[![CPAN Version](https://img.shields.io/cpan/v/Log-Any-Adapter-JSONLines)](https://metacpan.org/dist/Log-Any-Adapter-JSONLines)
[![kwalitee](https://cpants.cpanauthors.org/dist/Log-Any-Adapter-JSONLines.svg)](https://cpants.cpanauthors.org/dist/Log-Any-Adapter-JSONLines)
[![codecov](https://codecov.io/gh/mikkoi/log-any-adapter-jsonlines/graph/badge.svg?token=WSOLKXXEVK)](https://codecov.io/gh/mikkoi/log-any-adapter-jsonlines)
[![Coverage Status](https://coveralls.io/repos/github/mikkoi/log-any-adapter-jsonlines/badge.svg?branch=add-codecov-report)](https://coveralls.io/github/mikkoi/log-any-adapter-jsonlines?branch=add-codecov-report)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/mikkoi/log-any-adapter-jsonlines)
[![GH Actions: Linux Build](https://github.com/mikkoi/log-any-adapter-jsonlines/actions/workflows/linux.yml/badge.svg?event=push&branch=main)](https://github.com/mikkoi/log-any-adapter-jsonlines/actions/workflows/linux.yml)
[![GH Actions: Windows Build](https://github.com/mikkoi/log-any-adapter-jsonlines/actions/workflows/windows.yml/badge.svg?event=push&branch=main)](https://github.com/mikkoi/log-any-adapter-jsonlines/actions/workflows/windows.yml)

# Log-Any-Adapter-JSONLines

One-line JSON logging of arbitrary structured data in JSON Lines format.





# SYNOPSIS

    # Print to STDOUT:
    use Log::Any::Adapter( 'JSONLines' );

    # Print to a filehandle:
    use Log::Any::Adapter( 'JSONLines', file => \*STDERR, );

    # Print to a file, define logging level and JSON encoding, and
    # sort JSON properties alphabetically:
    use Log::Any::Adapter( 'JSONLines',
        file => 'out.json',
        log_level => 'fatal',
        encoding => 'UTF-8',
        canonical => 1,
    );

    # JSONLines uses hooks:
    use Log::Any::Adapter ('JSONLines', hooks => {
      before => [ \&add_pid, ],
    });
    sub add_pid {
      my ($level, $category, $data) = @_;
      $data->{pid} = $$;
      return;
    }


## INSTALLATION

### Packaging

[![Packaging status](https://repology.org/badge/vertical-allrepos/log-any-adapter-jsonlines.svg)](https://repology.org/project/log-any-adapter-jsonlines/versions)


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

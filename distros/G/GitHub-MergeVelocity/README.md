# NAME

GitHub::MergeVelocity - Determine how quickly your pull request might get merged

# VERSION

version 0.000009

# SYNOPSIS

    use strict;
    use warnings;

    use GitHub::MergeVelocity;

    my $velocity = GitHub::MergeVelocity->new(
        url => [
            'https://github.com/neilbowers/PAUSE-Permissions',
            'https://github.com/oalders/html-restrict',
        ]
    );

    my $report = $velocity->report;

    $velocity->print_report; # prints a tabular report

# CAVEATS

This module cannot (yet) distinguish between pull requests which were closed
because they were rejected and pull requests which were closed because the
patches were applied outside of GitHub's merge mechanism.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

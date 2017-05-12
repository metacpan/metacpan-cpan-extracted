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

package Devel::Cover::Report::Codecov::Service::Snap;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{SNAP_CI};
}

sub configuration {
    my $commit = defined $ENV{SNAP_COMMIT} ? $ENV{SNAP_COMMIT} : $ENV{SNAP_UPSTREAM_COMMIT};
    my $branch = defined $ENV{SNAP_BRANCH} ? $ENV{SNAP_BRANCH} : $ENV{SNAP_UPSTREAM_BRANCH};

    return {
        service      => 'snap',
        build        => $ENV{SNAP_PIPELINE_COUNTER},
        commit       => $commit,
        branch       => $branch,
        pull_request => $ENV{SNAP_PULL_REQUEST_NUMBER},
    };
}

1;
__END__

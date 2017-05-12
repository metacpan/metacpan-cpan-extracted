use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Snap;

sub snap { 'Devel::Cover::Report::Codecov::Service::Snap' }

subtest basic => sub {
    local %ENV = (
        SNAP_PIPELINE_COUNTER    => 'pipeline_counter',
        SNAP_COMMIT              => 'commit',
        SNAP_UPSTREAM_COMMIT     => 'upstream_commit',
        SNAP_BRANCH              => 'branch',
        SNAP_UPSTREAM_BRANCH     => 'upstream_branch',
        SNAP_PULL_REQUEST_NUMBER => 'pull_request',
    );

    cmp_deeply
        snap->configuration,
        {
            service      => 'snap',
            build        => 'pipeline_counter',
            commit       => 'commit',
            branch       => 'branch',
            pull_request => 'pull_request',
        };
};

subtest upstream => sub {
    local %ENV = (
        SNAP_PIPELINE_COUNTER    => 'pipeline_counter',
        SNAP_UPSTREAM_COMMIT     => 'upstream_commit',
        SNAP_UPSTREAM_BRANCH     => 'upstream_branch',
        SNAP_PULL_REQUEST_NUMBER => 'pull_request',
    );

    cmp_deeply
        snap->configuration,
        {
            service      => 'snap',
            build        => 'pipeline_counter',
            commit       => 'upstream_commit',
            branch       => 'upstream_branch',
            pull_request => 'pull_request',
        };
};

done_testing;

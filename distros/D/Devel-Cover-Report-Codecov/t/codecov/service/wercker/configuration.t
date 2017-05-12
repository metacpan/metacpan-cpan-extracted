use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Wercker;

sub wercker { 'Devel::Cover::Report::Codecov::Service::Wercker' }

subtest basic => sub {
    local $ENV{WERCKER_MAIN_PIPELINE_STARTED} = 'build';
    local $ENV{WERCKER_GIT_COMMIT}            = 'commit';
    local $ENV{WERCKER_BUILD_URL}             = 'build_url';
    local $ENV{WERCKER_GIT_BRANCH}            = 'branch';
    local $ENV{WERCKER_GIT_OWNER}             = 'owner';
    local $ENV{WERCKER_GIT_REPOSITORY}        = 'repo';

    cmp_deeply
        wercker->configuration,
        {
            service   => 'wercker',
            build     => 'build',
            commit    => 'commit',
            build_url => 'build_url',
            branch    => 'branch',
            owner     => 'owner',
            repo      => 'repo',
        };
};

done_testing;

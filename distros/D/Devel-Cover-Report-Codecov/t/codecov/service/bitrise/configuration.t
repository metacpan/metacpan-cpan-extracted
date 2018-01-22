use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Bitrise;

subtest 'without commit hash' => sub {
    local $ENV{BITRISE_GIT_BRANCH}    = 'branch';
    local $ENV{BITRISE_BUILD_NUMBER}  = 'build';
    local $ENV{BITRISE_BUILD_URL}     = 'build_url';
    local $ENV{BITRISE_PULL_REQUEST}  = 'pr';

    cmp_deeply(
        Devel::Cover::Report::Codecov::Service::Bitrise->configuration,
        {
            service   => 'bitrise',
            branch    => 'branch',
            build     => 'build',
            build_url => 'build_url',
            pr        => 'pr',
        });
};

subtest 'with commit hash' => sub {
    local $ENV{BITRISE_GIT_BRANCH}    = 'branch';
    local $ENV{BITRISE_BUILD_NUMBER}  = 'build';
    local $ENV{BITRISE_BUILD_URL}     = 'build_url';
    local $ENV{BITRISE_PULL_REQUEST}  = 'pr';
    local $ENV{GIT_CLONE_COMMIT_HASH} = 'commit';

    cmp_deeply(
        Devel::Cover::Report::Codecov::Service::Bitrise->configuration,
        {
            service   => 'bitrise',
            branch    => 'branch',
            build     => 'build',
            build_url => 'build_url',
            pr        => 'pr',
            commit    => 'commit',
        });
};

done_testing;

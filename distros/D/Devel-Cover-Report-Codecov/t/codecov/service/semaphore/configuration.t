use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Semaphore;

sub semaphore { 'Devel::Cover::Report::Codecov::Service::Semaphore' }

subtest basic => sub {
    local %ENV = (
        SEMAPHORE_BUILD_NUMBER   => 'build_number',
        SEMAPHORE_CURRENT_THREAD => 'thread',
        REVISION                 => 'revision',
        BRANCH_NAME              => 'branch_name',
        SEMAPHORE_REPO_SLUG      => 'slug',
    );

    cmp_deeply
        semaphore->configuration,
        {
            service => 'semaphore',
            build   => 'build_number.thread',
            commit  => 'revision',
            branch  => 'branch_name',
            slug    => 'slug',
        };
};

done_testing;

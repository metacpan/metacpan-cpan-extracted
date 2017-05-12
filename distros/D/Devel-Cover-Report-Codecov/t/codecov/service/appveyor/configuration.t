use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::AppVeyor;

sub appveyor { 'Devel::Cover::Report::Codecov::Service::AppVeyor' }

subtest basic => sub {
    local $ENV{APPVEYOR_ACCOUNT_NAME}  = 'name';
    local $ENV{APPVEYOR_PROJECT_SLUG}  = 'slug';
    local $ENV{APPVEYOR_REPO_COMMIT}   = 'commit';
    local $ENV{APPVEYOR_REPO_BRANCH}   = 'branch';
    local $ENV{APPVEYOR_BUILD_VERSION} = 'build_version';
    local $ENV{APPVEYOR_JOB_ID}        = 'job_id';
    local $ENV{APPVEYOR_REPO_NAME}     = 'repo_name';

    cmp_deeply
        appveyor->configuration,
        {
            service => 'appveyor',
            commit  => 'commit',
            branch  => 'branch',
            job     => 'name/slug/build_version',
            build   => 'job_id',
            slug    => 'repo_name',
        };
};

done_testing;

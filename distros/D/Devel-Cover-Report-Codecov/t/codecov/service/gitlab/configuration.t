use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::GitLab;

sub gitlab { 'Devel::Cover::Report::Codecov::Service::GitLab' }

subtest basic => sub {
  local $ENV{CI_BUILD_REF}      = 'commit';
  local $ENV{CI_BUILD_ID}       = 'build_id';
  local $ENV{CI_BUILD_REF_NAME} = 'branch';
  local $ENV{CI_BUILD_TAG}      = 'tag';
  local $ENV{CI_PIPELINE_ID}    = 'job_id';
  local $ENV{CI_PROJECT_PATH}   = 'repo_slug';
  local $ENV{CI_PROJECT_URL}    = 'repo_url';

  cmp_deeply
    gitlab->configuration,
    {
        service   => 'gitlab',
        commit    => 'commit',
        build     => 'build_id',
        build_url => 'repo_url/builds/build_id',
        job       => 'job_id',
        branch    => 'branch',
        tag       => 'tag',
        slug      => 'repo_slug',
    };
};

done_testing;

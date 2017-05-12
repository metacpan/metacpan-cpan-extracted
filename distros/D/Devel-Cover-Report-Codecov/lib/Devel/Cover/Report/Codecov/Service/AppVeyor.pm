package Devel::Cover::Report::Codecov::Service::AppVeyor;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{APPVEYOR};
}

sub configuration {
    return {
        service => 'appveyor',
        commit  => $ENV{APPVEYOR_REPO_COMMIT},
        branch  => $ENV{APPVEYOR_REPO_BRANCH},
        job     => $ENV{APPVEYOR_ACCOUNT_NAME} . '/' . $ENV{APPVEYOR_PROJECT_SLUG} . '/' . $ENV{APPVEYOR_BUILD_VERSION},
        build   => $ENV{APPVEYOR_JOB_ID},
        slug    => $ENV{APPVEYOR_REPO_NAME},
    };
}

1;
__END__

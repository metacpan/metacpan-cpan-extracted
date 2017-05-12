package Devel::Cover::Report::Codecov::Service::Wercker;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{WERCKER_MAIN_PIPELINE_STARTED};
}

sub configuration {
    return {
        service   => 'wercker',
        build     => $ENV{WERCKER_MAIN_PIPELINE_STARTED},
        commit    => $ENV{WERCKER_GIT_COMMIT},
        build_url => $ENV{WERCKER_BUILD_URL},
        branch    => $ENV{WERCKER_GIT_BRANCH},
        owner     => $ENV{WERCKER_GIT_OWNER},
        repo      => $ENV{WERCKER_GIT_REPOSITORY},
    };
}

1;
__END__

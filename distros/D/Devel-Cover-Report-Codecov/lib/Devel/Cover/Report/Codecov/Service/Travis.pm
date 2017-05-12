package Devel::Cover::Report::Codecov::Service::Travis;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{TRAVIS};
}

sub configuration {
    return {
        service      => 'travis',
        commit       => $ENV{TRAVIS_COMMIT},
        build        => $ENV{TRAVIS_JOB_NUMBER},
        branch       => $ENV{TRAVIS_BRANCH},
        job          => $ENV{TRAVIS_JOB_ID},
        pull_request => $ENV{TRAVIS_PULL_REQUEST},
        slug         => $ENV{TRAVIS_REPO_SLUG},
    };
}

1;
__END__

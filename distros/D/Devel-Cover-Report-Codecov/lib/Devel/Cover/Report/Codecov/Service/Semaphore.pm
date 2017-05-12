package Devel::Cover::Report::Codecov::Service::Semaphore;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{SEMAPHORE};
}

sub configuration {
    return {
        service => 'semaphore',
        build   => $ENV{SEMAPHORE_BUILD_NUMBER} . '.' . $ENV{SEMAPHORE_CURRENT_THREAD},
        commit  => $ENV{REVISION},
        branch  => $ENV{BRANCH_NAME},
        slug    => $ENV{SEMAPHORE_REPO_SLUG},
    };
}

1;
__END__

package Devel::Cover::Report::Codecov::Service::Drone;
use strict;
use warnings;
use utf8;

sub detect {
    return $ENV{DRONE};
}

sub configuration {
    return {
        service   => 'drone.io',
        build     => $ENV{DRONE_BUILD_NUMBER},
        commit    => $ENV{DRONE_COMMIT},
        build_url => $ENV{DRONE_BUILD_URL},
        branch    => $ENV{DRONE_BRANCH},
    };
}

1;
__END__

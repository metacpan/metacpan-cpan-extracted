use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Drone;

sub drone { 'Devel::Cover::Report::Codecov::Service::Drone' }

subtest basic => sub {
    local %ENV = (
        DRONE_BUILD_NUMBER => 'build_number',
        DRONE_COMMIT       => 'commit',
        DRONE_BUILD_URL    => 'build_url',
        DRONE_BRANCH       => 'branch',
        DRONE_TAG          => 'tag',
    );

    cmp_deeply
        drone->configuration,
        {
            service   => 'drone.io',
            build     => 'build_number',
            commit    => 'commit',
            build_url => 'build_url',
            branch    => 'branch',
            tag       => 'tag',
        };
};

done_testing;

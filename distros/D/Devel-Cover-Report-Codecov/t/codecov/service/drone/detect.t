use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Drone;

sub drone { 'Devel::Cover::Report::Codecov::Service::Drone' }

subtest 'if drone' => sub {
    local $ENV{DRONE} = 'true';
    ok( drone->detect );
};

subtest 'if not drone' => sub {
    local %ENV;
    ok( not drone->detect );
};

done_testing;

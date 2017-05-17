use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;
use Devel::Cover::Report::Codecov::Service::Snap;

sub snap { 'Devel::Cover::Report::Codecov::Service::Snap' }

subtest 'if snap' => sub {
    local $ENV{SNAP_CI} = 1;
    ok( snap->detect );
};

subtest 'if not snap' => sub {
    local %ENV;
    ok( not snap->detect );
};

done_testing;

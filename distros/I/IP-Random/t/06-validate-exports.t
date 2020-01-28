#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2020 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use utf8;

use autodie;

use Test2::V0;

package test_dies {
    use Test2::V0;
    use IP::Random;
    sub t {
        ok( dies( sub { random_ipv4() } ), "Not exported by default" );
    }
}

package test_lives {
    use Test2::V0;
    use IP::Random qw(random_ipv4);
    sub t {
        ok( lives( sub { random_ipv4() } ), "Runs successfully" );
    }
};

test_dies::t();
test_lives::t();

done_testing;


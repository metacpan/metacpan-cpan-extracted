#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use Carp;
use Test2::V0;

# Instantiate the object
use IP::Random;

if ( $ENV{DO_BENCHMARK} ) {

    my $st = time;
    diag( "Start   : " . $st );

    pass("Performing Benchmark routines");
    for (my $i=0; $i<100_000; $i++) {
        IP::Random::random_ipv4();
    }

    my $end = time;
    diag( "End     : " . $end );
    diag( "INTERVAL: " . ( $end - $st ) );

} else {
    pass("Skipping Benchmark routines (Set \$ENV{DO_BENCHMARK}=1)");
}

done_testing;


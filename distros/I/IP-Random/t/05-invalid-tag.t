#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use utf8;

use autodie;

use Test2::V0;

# Instantiate the object
use IP::Random;

ok( dies( sub { IP::Random::random_ipv4( exclude => ['rf6598'] ) } ), 'Dies with invalid exclude' );
ok( dies( sub { IP::Random::random_ipv4( additional_exclude => ['rf6598'] ) } ),
    'Dies with invalid additional_exclude' );
ok( dies( sub { IP::Random::random_ipv4( additional_types_allowed => ['rf6598'] ) } ),
    'Dies with invalid additional_types_allowed' );

done_testing;


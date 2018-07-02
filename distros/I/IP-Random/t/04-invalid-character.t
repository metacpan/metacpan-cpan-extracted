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

# Verifies regex properly dies with incorrect script usage
ok( dies( sub { IP::Random::in_ipv4_subnet( '127.0.0.٠/8', '127.0.0.0' ) } ),
    "127.0.0.٠/8 fails for invalid character" );

done_testing;


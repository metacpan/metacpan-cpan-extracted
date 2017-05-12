#!/usr/local/bin/perl

# program to test IP::World in Mmap mode

use strict;
use warnings;
use lib '.';
use Test::More;
END { done_testing }
use t::lib::tests;

use IP::World qw(IP_WORLD_MMAP);

my $ipw = IP::World->new(IP_WORLD_MMAP);
# get 'Mmap in use' from the object
my $ismmap = unpack 'L', substr($$ipw, -4);

# skip this test if not a Mmap system
SKIP: {
    skip "this system does not support Mmap", 1 if !$ismmap;
    tests($ipw);
}

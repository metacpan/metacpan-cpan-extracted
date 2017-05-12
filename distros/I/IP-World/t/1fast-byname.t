#!/usr/local/bin/perl

# program to test IP::World

use strict;
use warnings;
use lib '.';
use Test::More;
END { done_testing }
use t::lib::tests;

use IP::World qw(IP_WORLD_FAST);

my $ipw = IP::World->new(IP_WORLD_FAST);

tests($ipw);

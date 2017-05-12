#!/usr/local/bin/perl

# program to test IP::World in tiny mode with perl I/O

use strict;
use warnings;
use lib '.';
use Test::More;
END { done_testing }
use t::lib::tests;

use IP::World;

my $ipw = IP::World->new(3);

tests($ipw);

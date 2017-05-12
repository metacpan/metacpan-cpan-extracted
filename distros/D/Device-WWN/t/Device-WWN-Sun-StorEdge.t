#!perl
use strict; use warnings;
use Test::Most tests => 2;
use ok 'Device::WWN::Sun::StorEdge';

ok( my $obj = Device::WWN::Sun::StorEdge->new( {} ), "created object" );

#!perl
use strict; use warnings;
use Test::Most tests => 2;
use ok 'Device::WWN::EMC::Clariion';

ok( my $obj = Device::WWN::EMC::Clariion->new( {
} ), "created object" );

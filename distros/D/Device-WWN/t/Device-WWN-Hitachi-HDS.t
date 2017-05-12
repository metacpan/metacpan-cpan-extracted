#!perl
use strict; use warnings;
use Test::Most tests => 2;
use ok 'Device::WWN::Hitachi::HDS';

ok( my $obj = Device::WWN::Hitachi::HDS->new( {} ), "created object" );

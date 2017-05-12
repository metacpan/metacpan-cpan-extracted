package main;

use strict;
use warnings;

use Test::More 0.40;

require_ok('Geo::Coder::Geocoder::US');

can_ok( 'Geo::Coder::Geocoder::US', qw{ new debug geocode response ua } );

my $ms = Geo::Coder::Geocoder::US->new();

isa_ok($ms, 'Geo::Coder::Geocoder::US');

done_testing;

1;

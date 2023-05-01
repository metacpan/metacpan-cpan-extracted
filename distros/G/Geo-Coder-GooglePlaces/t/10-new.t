#!perl -wT

use strict;

use Test::Most tests => 4;

use_ok('Geo::Coder::GooglePlaces');

isa_ok(Geo::Coder::GooglePlaces->new(), 'Geo::Coder::GooglePlaces::V3', 'Creating Geo::Coder::GooglePlaces object');
isa_ok(Geo::Coder::GooglePlaces::new(), 'Geo::Coder::GooglePlaces::V3');
isa_ok(Geo::Coder::GooglePlaces->new()->new(), 'Geo::Coder::GooglePlaces::V3', 'Cloning Geo::Coder::GooglePlaces object');

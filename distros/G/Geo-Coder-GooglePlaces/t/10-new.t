#!perl -wT

use strict;

use Test::Most tests => 2;

use Geo::Coder::GooglePlaces;

isa_ok(Geo::Coder::GooglePlaces->new(), 'Geo::Coder::GooglePlaces::V3', 'Creating Geo::Coder::GooglePlaces object');
isa_ok(Geo::Coder::GooglePlaces::new(), 'Geo::Coder::GooglePlaces::V3');

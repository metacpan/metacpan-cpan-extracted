#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { plan skip_all => "AUTOMATED_TESTING not set" if not $ENV{AUTOMATED_TESTING}; }

plan tests => 4;

use Test::RequiresInternet ('www.geocode.farm' => 80);

use Geo::Coder::GeocodeFarm;

my $geocode = new_ok 'Geo::Coder::GeocodeFarm';

can_ok $geocode, qw(geocode);

my $result = $geocode->reverse_geocode(lat => 45.2040305, lon => -93.3995728);

isa_ok $result, 'HASH';

is $result->{STATUS}{status}, 'SUCCESS', '$result status';

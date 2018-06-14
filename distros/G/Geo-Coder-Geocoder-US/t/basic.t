package main;

use strict;
use warnings;

use Test::More 0.40;

{
    local $@ = undef;

    eval {
	require Geo::Coder::Geocoder::US;
	1;
    };

    like $@, qr<Geo::Coder::Geocoder::US has been retracted,>,
    'Attempt to load Geo::Coder::Geocoder::US throws correct exception';
}

done_testing;

1;

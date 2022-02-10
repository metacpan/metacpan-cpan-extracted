#!perl -Tw

use strict;
use warnings;
use Test::Number::Delta within => 1e-3;
use Test::Most;

use Geo::Coder::GooglePlaces;

my $coder = Geo::Coder::GooglePlaces->new(key => $ENV{'GMAP_KEY'});
my $location;

if($ENV{TEST_GEOCODER_GOOGLE_LIVE} || $ENV{'GMAP_KEY'}) {
	eval {
		$location = $coder->geocode(location => 'Wisdom Hospice, High Bank, Rochester, Kent, England');
	};
	if($@) {
		plan(skip_all => $@);
	} else {
		plan(tests => 4);
	}
} else {
	plan(skip_all => 'Not running live tests. Set $ENV{TEST_GEOCODER_GOOGLE_LIVE} = 1 to enable');
}

require_ok('Test::NoWarnings');
Test::NoWarnings->import();

delta_ok($location->{geometry}{location}{lat}, 51.372563);
delta_ok($location->{geometry}{location}{lng}, 0.5093407);

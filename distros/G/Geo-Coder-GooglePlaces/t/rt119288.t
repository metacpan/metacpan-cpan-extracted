#!perl -Tw

use strict;
use warnings;
use Test::Number::Delta within => 1e-4;
use Test::Most;

if(!$ENV{TEST_GEOCODER_GOOGLE_LIVE}) {
	plan skip_all => 'Not running live tests. Set $ENV{TEST_GEOCODER_GOOGLE_LIVE} = 1 to enable';
} else {
	plan tests => 4;

	require Test::NoWarnings;
	Test::NoWarnings->import();
	use_ok('Geo::Coder::GooglePlaces');

	my $coder = Geo::Coder::GooglePlaces->new(key => $ENV{'GMAP_KEY'});
	my $location = $coder->geocode(location => 'Wisdom Hospice, High Bank, Rochester, Kent, England');
	delta_ok($location->{geometry}{location}{lat}, 51.372563);
	delta_ok($location->{geometry}{location}{lng}, 0.5093407);
}

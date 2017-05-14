#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 6;
use Geo::Coder::CA;

CA: {
	my $geocoder = new_ok('Geo::Coder::CA');
	my $location = $geocoder->geocode('9235 Main St, Richibucto, New Brunswick, Canada');
	delta_ok($location->{latt}, 46.67);
	delta_ok($location->{longt}, -64.87);

	$location = $geocoder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
	delta_ok($location->{latt}, 46.67);
	delta_ok($location->{longt}, -64.87);

	my $address = $geocoder->reverse_geocode(latlng => '46.67,-64.87');
	is($address->{'city'}, 'Richibucto', 'test reverse');
}

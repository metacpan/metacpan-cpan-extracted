#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 4;

use_ok('Geo::Coder::GeoApify');

if($ENV{'GEOAPIFY_KEY'}) {
	isa_ok(Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'}), 'Geo::Coder::GeoApify', 'Creating Geo::Coder::GeoApify object');
	ok(!defined(Geo::Coder::GeoApify::new()));
	isa_ok(Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'})->new(), 'Geo::Coder::GeoApify', 'Cloning Geo::Coder::GeoApify object');
} else {
	SKIP: {
		skip('GEOAPIFY_KEY not set', 3);
	}
}

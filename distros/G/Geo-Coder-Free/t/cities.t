#!perl -wT

# Check the cities database is sensible

use strict;
use warnings;
use Test::Most tests => 6;
use Test::Number::Delta;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free::DB::MaxMind::cities');
}

CITIES: {
	Geo::Coder::Free::DB::init(directory => 'lib/Geo/Coder/Free/MaxMind/databases');

	my $cities = new_ok('Geo::Coder::Free::DB::MaxMind::cities' => [logger => new_ok('MyLogger')]);

	# diag($cities->population(Country => 'gb', City => 'ramsgate'));
	ok($cities->population(Country => 'gb', City => 'ramsgate') == 38624);

	my $ramsgate = $cities->fetchrow_hashref({ Country => 'gb', City => 'ramsgate' });
	if($ramsgate->{latitude}) {
		delta_within($ramsgate->{latitude}, 51.33, 1e-2);
		delta_within($ramsgate->{longitude}, 1.43, 1e-2);
	} else {
		delta_within($ramsgate->{Latitude}, 51.33, 1e-2);
		delta_within($ramsgate->{Longitude}, 1.43, 1e-2);
	}
}

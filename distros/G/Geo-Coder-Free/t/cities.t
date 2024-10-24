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
	SKIP: {
		if(!$ENV{'NO_NETWORK_TESTING'}) {
			my $cities = new_ok('Geo::Coder::Free::DB::MaxMind::cities' => [{
				directory => 'lib/Geo/Coder/Free/MaxMind/databases',
				logger => new_ok('MyLogger'),
				no_entry => 1
			}]);

			# diag($cities->population(Country => 'gb', City => 'ramsgate'));
			cmp_ok($cities->population(Country => 'gb', City => 'ramsgate'), '==', 38624, 'Reading the population of a town/city');

			my $ramsgate = $cities->fetchrow_hashref({ Country => 'gb', City => 'ramsgate' });
			if($ramsgate->{'latitude'}) {
				delta_within($ramsgate->{latitude}, 51.33, 1e-2);
				delta_within($ramsgate->{longitude}, 1.43, 1e-2);
			} else {
				delta_within($ramsgate->{Latitude}, 51.33, 1e-2);
				delta_within($ramsgate->{Longitude}, 1.43, 1e-2);
			}
		} else {
			diag('Network testing disabled');
			skip('Network testing disabled', 5);
		}
	}
}

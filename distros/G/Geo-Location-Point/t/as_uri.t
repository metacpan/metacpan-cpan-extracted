#!perl -wT

use strict;
use warnings;
use Test::Most tests => 4;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Location::Point');
}

URI: {
	my $loc = new_ok('Geo::Location::Point' => [{
		Region => 'Kent',
		City => 'Minster',
		longitude => 51.34,
		Country => 'gb',
		latitude => 1.32,
		AccentCity => 'Minster'
	}]);

	cmp_ok($loc->as_uri(), 'eq', 'geo:1.32,51.34', 'as_uri method works');
}

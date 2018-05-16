#!perl -w

use warnings;
use strict;
use Test::Most tests => 9;
use Test::Number::Delta;
use Test::Carp;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free');
}

WHOSONFIRST: {
	SKIP: {
		if($ENV{'WHOSONFIRST_HOME'}) {
			diag('This will take some time and memory');

			Geo::Coder::Free::DB::init(logger => new_ok('MyLogger'));

			my $geocoder = new_ok('Geo::Coder::Free' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);
			my $location = $geocoder->geocode(location => 'Margate, Kent, England');
			delta_within($location->{latitude}, 51.39, 1e-2);
			delta_within($location->{longitude}, 1.42, 1e-2);
			$location = $geocoder->geocode(location => 'Summerfield Road, Margate, Kent, England');
			delta_within($location->{latitude}, 51.39, 1e-2);
			delta_within($location->{longitude}, 1.42, 1e-2);
			$location = $geocoder->geocode(location => '7 Summerfield Road, Margate, Kent, England');
			delta_within($location->{latitude}, 51.39, 1e-2);
			delta_within($location->{longitude}, 1.42, 1e-2);
		} else {
			diag('Set WHOSONFIRST_HOME to enable whosonfirst.org testing');
			skip 'WHOSONFIRST_HOME not defined', 8;
		}
	}
}

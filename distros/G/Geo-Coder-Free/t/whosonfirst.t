#!perl -wT

use warnings;
use strict;
use Test::Most tests => 45;
use Test::Number::Delta;
use Test::Carp;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free');
}

WHOSONFIRST: {
	SKIP: {
		if($ENV{'WHOSONFIRST_HOME'} && $ENV{'OPENADDR_HOME'}) {
			if($ENV{AUTHOR_TESTING}) {
				diag('This will take some time and memory');

				my $libpostal_is_installed = 0;
				if(eval { require Geo::libpostal; }) {
					$libpostal_is_installed = 1;
				}

				Geo::Coder::Free::DB::init(logger => new_ok('MyLogger'));

				my $geocoder = new_ok('Geo::Coder::Free');
				my $location = $geocoder->geocode(location => 'Margate, Kent, England');
				delta_within($location->{latitude}, 51.38, 1e-2);
				delta_within($location->{longitude}, 1.39, 1e-2);

				TODO: {
					local $TODO = 'UK only supports towns and venues';

					$location = $geocoder->geocode(location => 'Summerfield Road, Margate, Kent, England');
					ok(ref($location) eq 'HASH');
					# delta_within($location->{latitude}, 51.38, 1e-2);
					# delta_within($location->{longitude}, 1.36, 1e-2);
					$location = $geocoder->geocode(location => '7 Summerfield Road, Margate, Kent, England');
					ok(ref($location) eq 'HASH');
					# delta_within($location->{latitude}, 51.38, 1e-2);
					# delta_within($location->{longitude}, 1.36, 1e-2);
				}

				$location = $geocoder->geocode('Silver Diner, 12276 Rockville Pike, Rockville, MD, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 39.06, 1e-2);
				delta_within($location->{longitude}, -77.12, 1e-2);

				# https://spelunker.whosonfirst.org/id/772834215/
				$location = $geocoder->geocode('Rock Bottom, Norfolk Ave, Bethesda, MD, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 38.99, 1e-2);
				delta_within($location->{longitude}, -77.10, 1e-2);

				$location = $geocoder->geocode('Rock Bottom, Bethesda, MD, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 38.99, 1e-2);
				delta_within($location->{longitude}, -77.10, 1e-2);

				$location = $geocoder->geocode('Rock Bottom Restaurant & Brewery, Norfolk Ave, Bethesda, MD, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 38.99, 1e-2);
				delta_within($location->{longitude}, -77.10, 1e-2);

				$location = $geocoder->geocode('12276 Rockville Pike, Rockville, MD, USA');
				delta_within($location->{latitude}, 39.06, 1e-2);
				delta_within($location->{longitude}, -77.12, 1e-2);

				$location = $geocoder->geocode(location => 'Ramsgate, Kent, England');
				delta_within($location->{latitude}, 51.34, 1e-2);
				delta_within($location->{longitude}, 1.42, 1e-2);

				$location = $geocoder->geocode({ location => 'Silver Diner, Rockville Pike, Rockville, MD, USA' });
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				# FIXME: Stop the different results
				delta_within($location->{latitude}, 39.06, 1e-2);
				if($libpostal_is_installed) {
					delta_within($location->{longitude}, -77.13, 1e-2);
				} else {
					delta_within($location->{longitude}, -77.12, 1e-2);
				}

				$location = $geocoder->geocode({ location => '106 Tothill St, Minster, Thanet, Kent, England' });
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 51.34, 1e-2);
				delta_within($location->{longitude}, 1.32, 1e-2);

				$location = $geocoder->geocode({ location => 'Minster Cemetery, Tothill St, Minster, Thanet, Kent, England' });
				delta_within($location->{latitude}, 51.34, 1e-2);
				delta_within($location->{longitude}, 1.32, 1e-2);

				$location = $geocoder->geocode(location => '13 Ashburnham Road, St Lawrence, Thanet, Kent, England');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 51.34, 1e-2);
				delta_within($location->{longitude}, 1.41, 1e-2);

				$location = $geocoder->geocode('Wickhambreaux, Kent, England');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 51.30, 1e-2);
				delta_within($location->{longitude}, 1.19, 1e-2);
				# diag(Data::Dumper->new([$location])->Dump());
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 44);
			}
		} else {
			diag('Set WHOSONFIRST_HOME and OPENADDR_HOME to enable whosonfirst.org testing');
			skip 'WHOSONFIRST_HOME and/or OPENADDR_HOME not defined', 44;
		}
	}
}

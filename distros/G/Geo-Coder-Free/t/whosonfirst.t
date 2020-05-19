#!perl -wT

# TODO:  Try using Test::Without::Module to try without Geo::libpostal is that
#	is installed

use warnings;
use strict;
use Test::Most tests => 21;
use Test::Number::Delta;
use Test::Carp;
use Test::Deep;
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

				if($ENV{'TEST_VERBOSE'}) {
					Geo::Coder::Free::DB::init(logger => new_ok('MyLogger'));
				}

				my $geo_coder = new_ok('Geo::Coder::Free');
				my $location = $geo_coder->geocode(location => 'Margate, Kent, England');
				ok(defined($location));
				cmp_deeply($location,
					methods('lat' => num(51.38, 1e-2), 'long' => num(1.38, 1e-2)));

				TODO: {
					local $TODO = 'UK only supports towns and venues';

					$location = $geo_coder->geocode(location => 'Summerfield Road, Margate, Kent, England');
					is(ref($location), 'HASH');
					# delta_within($location->{latitude}, 51.38, 1e-2);
					# delta_within($location->{longitude}, 1.36, 1e-2);
					$location = $geo_coder->geocode(location => '7 Summerfield Road, Margate, Kent, England');
					is(ref($location), 'HASH');
					# delta_within($location->{latitude}, 51.38, 1e-2);
					# delta_within($location->{longitude}, 1.36, 1e-2);
				}

				$location = $geo_coder->geocode('Silver Diner, 12276 Rockville Pike, Rockville, MD, USA');
				ok(defined($location));
				cmp_deeply($location,
					methods('lat' => num(39.06, 1e-2), 'long' => num(-77.12, 1e-2)));

				# https://spelunker.whosonfirst.org/id/772834215/
				$location = $geo_coder->geocode('Rock Bottom, Norfolk Ave, Bethesda, MD, USA');
				ok(defined($location));
				cmp_deeply($location,
					methods('lat' => num(38.99, 1e-2), 'long' => num(-77.10, 1e-2)));

				$location = $geo_coder->geocode('Rock Bottom, Bethesda, MD, USA');
				cmp_deeply($location,
					methods('lat' => num(38.99, 1e-2), 'long' => num(-77.10, 1e-2)));

				$location = $geo_coder->geocode('Rock Bottom Restaurant & Brewery, Norfolk Ave, Bethesda, MD, USA');
				ok(defined($location));
				cmp_deeply($location,
					methods('lat' => num(38.99, 1e-2), 'long' => num(-77.10, 1e-2)));

				$location = $geo_coder->geocode('12276 Rockville Pike, Rockville, MD, USA');
				cmp_deeply($location,
					methods('lat' => num(39.06, 1e-2), 'long' => num(-77.12, 1e-2)));

				$location = $geo_coder->geocode(location => 'Ramsgate, Kent, England');
				cmp_deeply($location,
					methods('lat' => num(51.34, 1e-2), 'long' => num(1.41, 1e-2)));

				$location = $geo_coder->geocode({ location => 'Silver Diner, Rockville Pike, Rockville, MD, USA' });
				if($libpostal_is_installed) {
					cmp_deeply($location,
						methods('lat' => num(39.06, 1e-2), 'long' => num(-77.13, 1e-2)));
				} else {
					cmp_deeply($location,
						methods('lat' => num(39.06, 1e-2), 'long' => num(-77.12, 1e-2)));
				}

				$location = $geo_coder->geocode({ location => '106 Tothill St, Minster, Thanet, Kent, England' });
				cmp_deeply($location,
					methods('lat' => num(51.34, 1e-2), 'long' => num(1.32, 1e-2)));

				$location = $geo_coder->geocode({ location => 'Minster Cemetery, Tothill St, Minster, Thanet, Kent, England' });
				cmp_deeply($location,
					methods('lat' => num(51.34, 1e-2), 'long' => num(1.32, 1e-2)));

				$location = $geo_coder->geocode('Wickhambreaux, Kent, England');
				ok(defined($location));
				cmp_deeply($location,
					methods('lat' => num(51.30, 1e-2), 'long' => num(1.19, 1e-2)));

				# diag(Data::Dumper->new([$location])->Dump());

				eval 'use Test::Memory::Cycle';
				if($@) {
					skip('Test::Memory::Cycle required to check for cicular memory references', 1);
				} else {
					memory_cycle_ok($geo_coder);
				}
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 20);
			}
		} else {
			diag('Set WHOSONFIRST_HOME and OPENADDR_HOME to enable whosonfirst.org testing');
			skip('WHOSONFIRST_HOME and/or OPENADDR_HOME not defined', 20);
		}
	}
}

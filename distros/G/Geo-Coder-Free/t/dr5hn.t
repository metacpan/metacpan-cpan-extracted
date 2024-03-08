#!perl -w

# TODO:  Try using Test::Without::Module to try without Geo::libpostal is that
#	is installed

use warnings;
use strict;
use Data::Dumper;
use Test::Most tests => 5;
use Test::Number::Delta;
use Test::Carp;
use Test::Deep;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free');
}

DR5HN: {
	SKIP: {
		if($ENV{'DR5HN_HOME'} && $ENV{'OPENADDR_HOME'}) {
			if($ENV{AUTHOR_TESTING}) {
				diag('This will take some time and memory');

				my $libpostal_is_installed = 0;
				if(eval { require Geo::libpostal; }) {
					$libpostal_is_installed = 1;
				}

				if($ENV{'TEST_VERBOSE'}) {
					Database::Abstraction::init(logger => MyLogger->new());
				}

				my $geo_coder = new_ok('Geo::Coder::Free');
				my $location = $geo_coder->geocode(location => 'Silver Spring, MD, USA');
				ok(defined($location));
				cmp_deeply($location,
					methods('lat' => num(38.99, 1e-2), 'long' => num(-77.02, 1e-1)));

				diag(Data::Dumper->new([$location])->Dump()) if($ENV{'TEST_VERBOSE'});

				eval 'use Test::Memory::Cycle';
				if($@) {
					skip('Test::Memory::Cycle required to check for cicular memory references', 1);
				} else {
					memory_cycle_ok($geo_coder);
				}
			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 4);
			}
		} else {
			diag('Set DR5HN_HOME and OPENADDR_HOME to enable dr5hn testing');
			skip('DR5HN_HOME and/or OPENADDR_HOME not defined', 4);
		}
	}
}

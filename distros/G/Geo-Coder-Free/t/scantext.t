#!perl -w

use warnings;
use strict;
use Data::Dumper;
use Test::Most tests => 24;
use Test::Number::Delta;
use Test::Carp;
use Test::Deep;

use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free');
}

SCANTEXT: {
	SKIP: {
		if($ENV{'OPENADDR_HOME'} && $ENV{AUTHOR_TESTING}) {
			diag('This will take some time and memory');

			if($ENV{'TEST_VERBOSE'}) {
				Database::Abstraction::init(logger => MyLogger->new());
			}

			my $geo_coder = new_ok('Geo::Coder::Free' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);
			my @locations = $geo_coder->geocode(scantext => 'I was born in Ramsgate, Kent, England');
			diag(Data::Dumper->new([\@locations])->Dump()) if($ENV{'TEST_VERBOSE'});
			cmp_ok(scalar(@locations), '==', 1, 'Finds one match');
			my $location = $locations[0];
			ok(defined($location));
			if($ENV{'WHOSONFIRST_HOME'}) {
				cmp_deeply($location,
					methods('lat' => num(51.34, 1e-2), 'long' => num(1.41, 1e-2)));
			} else {
				cmp_deeply($location,
					methods('lat' => num(51.34, 1e-2), 'long' => num(1.31, 1e-2)));
			}

			ok(defined($location->{'confidence'}));
			cmp_ok($location->{'location'}, 'eq', 'Ramsgate, Kent, England', 'Location is found in text');

			@locations = $geo_coder->geocode(scantext => 'Hello World', region => 'GB');
			ok(ref($locations[0]) eq '');

			@locations = $geo_coder->geocode(scantext => 'Hello World');
			ok(ref($locations[0]) eq '');

			@locations = $geo_coder->geocode({ scantext => "I was born at St Mary's Hospital in Newark, DE in 1987", region => 'US' });
			my $found = 0;
			foreach $location(@locations) {
				# if($location->{'city'} ne 'NEWARK') {
					# next;
				# }
				# if($location->{'state'} ne 'DE') {
					# next;
				# }
				# if($location->{'country'} ne 'US') {
					# next;
				# }

				diag(Data::Dumper->new([$location])->Dump()) if($ENV{'TEST_VERBOSE'});
				next unless($location->{'location'} eq 'NEWARK, DE, USA');
				$found++;
				cmp_deeply($location,
					methods('lat' => num(39.68, 1e-2), 'long' => num(-75.75, 1e-2)));
				ok(defined($location->{'confidence'}));
			}
			ok($found == 1);

			my $s = 'From the Indianapolis Star, 25/4/2013:  "75, Indianapolis, died Apr. 21, 2013. Services: 1 p.m. Apr. 26 in Forest Lawn Funeral Home, Greenwood, with visitation from 11 a.m.".  Obituary from Forest Lawn Funeral Home:  "Sharlene C. Cloud, 75, of Indianapolis, passed away April 21, 2013. She was born May 21, 1937 in Noblesville, IN to Virgil and Josephine (Beaver) Day. She is survived by her mother; two sons, Christopher and Thomas Cloud; daughter, Marsha Cloud; three sisters, Mary Kirby, Sharon Lowery, and Doris Lyng; two grandchildren, Allison and Jamie Cloud. Funeral Services will be Friday at 1:00 pm at Forest Lawn Funeral Home, Greenwood, IN, with visitation from 11:00am till time of service Friday at the funeral home."';
			@locations = $geo_coder->geocode({ scantext => $s, region => 'US' });
			my %found;
			# diag(Data::Dumper->new([\@locations])->Dump());
			foreach $location(@locations) {
				my $city;
				# diag(__LINE__, $location->{'location'});
				next if(!defined($city = $location->{'city'}));
				# diag(__LINE__, ": $city: ", $location->{'confidence'});
				if(defined($location->{'state'}) && ($location->{'state'} ne 'IN')) {
					next;
				}
				next if($location->{'country'} ne 'US');
				next if($found{$city});

				if($city eq 'GREENWOOD') {
				# if($location->{'location'} =~ /^Greenwood, IN/i) {
					$found{'GREENWOOD'}++;
					ok(defined($location->{'confidence'}));
					ok($location->{'state'} eq 'IN');
					cmp_deeply($location,
						methods('lat' => num(39, 1), 'long' => num(-86, 1)));
				} elsif($city eq 'INDIANAPOLIS') {
				# } elsif($location->{'location'} =~ /^Indianapolis,/i) {
					$found{'INDIANAPOLIS'}++;
					ok(defined($location->{'confidence'}));
					ok($location->{'state'} eq 'IN');
					cmp_deeply($location,
						methods('lat' => num(39.8, 1e-2), 'long' => num(-86.2, 1e-2)));
				} elsif($city eq 'NOBLESVILLE') {
				# } elsif($location->{'location'} =~ /^Noblesville,/i) {
					$found{'NOBLESVILLE'}++;
					ok(defined($location->{'confidence'}));
					ok($location->{'state'} eq 'IN');
					cmp_deeply($location,
						methods('lat' => num(40.04, 1e-2), 'long' => num(-86.01, 1e-2)));
				}
			}
			ok($found{'GREENWOOD'});
			ok($found{'NOBLESVILLE'});
			# ok($found{'INDIANAPOLIS'});

			@locations = $geo_coder->geocode(scantext => 'Nigel Horne was here', region => 'gb');
			cmp_ok(scalar(@locations), '==', 1, 'Found one match for Horne in GB');
			diag(Data::Dumper->new([\@locations])->Dump()) if($ENV{'TEST_VERBOSE'});
			cmp_ok(lc($locations[0]->{'city'}), 'eq', 'horne', 'There is a place near Gatwick called Horne');

			@locations = $geo_coder->geocode(scantext => 'Nigel Horne was here', region => 'gb', ignore_words => [ 'horne' ]);
			# cmp_ok(scalar(@locations), '==', 0, 'ignore_words are ignored');
			cmp_ok($locations[0], 'eq', '', 'Empty string');	# FIXME: should be undef
			diag(__LINE__, ': ', Data::Dumper->new([\@locations])->Dump()) if($ENV{'TEST_VERBOSE'});

			@locations = $geo_coder->geocode({
				scantext => 'Send it to 123 Main Street, Springfield, IL 62704 or to 456 Elm St., Denver, CO. Other options: 789 Pine Blvd, Austin, TX.',
				region => 'us'
			});
			diag(Data::Dumper->new([\@locations])->Dump()) if($ENV{'TEST_VERBOSE'});

			eval 'use Test::Memory::Cycle';
			if($@) {
				skip('Test::Memory::Cycle required to check for cicular memory references', 1);
			} else {
				memory_cycle_ok($geo_coder);
			}
		} elsif(!defined($ENV{'AUTHOR_TESTING'})) {
			diag('Author tests not required for installation');
			skip('Author tests not required for installation', 23);
		} else {
			diag('Set OPENADDR_HOME to enable openaddresses.io testing');
			skip('Set OPENADDR_HOME to enable openaddresses.io testing', 23);
		}
	}
}

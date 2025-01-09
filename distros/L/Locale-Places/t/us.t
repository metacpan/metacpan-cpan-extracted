#!perl -wT

# Check the US database is sensible

use strict;
use warnings;

# use autodie qw(:all);
use Test::Most tests => 6;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Locale::Places::US');
}

US: {
	SKIP: {
		if((!defined($ENV{'AUTOMATED_TESTING'}) && (!defined($ENV{'NO_NETWORK_TESTING'})) && (-d 'lib/Locale/Places/data'))) {
			Database::Abstraction::init(directory => 'lib/Locale/Places/data');
			my $places = new_ok('Locale::Places::US' => [{logger => new_ok('MyLogger'), no_entry => 1}]);

			eval { require 'autodie' };

			my $dc = $places->fetchrow_hashref({ data => 'Washington DC', type => 'en' });
			if($ENV{'TEST_VERBOSE'}) {
				require Data::Dumper;
				Data::Dumper->import();
				diag(Data::Dumper->new([$dc])->Dump());
			}

			$dc = $places->selectall_hashref({ code2 => $dc->{'code2'} });

			my $found;

			foreach my $entry(@{$dc}) {
				next if(!defined($entry->{'type'}));
				if($ENV{'TEST_VERBOSE'}) {
					diag(Data::Dumper->new([\$entry])->Dump());
				}

				if($entry->{'type'} eq 'la') {
					is($entry->{'data'}, 'Vasingtonia', 'Latvian');
					$found++;
				} elsif($entry->{'type'} eq 'fr') {
					is($entry->{'data'}, 'Washington', 'French');
					$found++;
				}
			}

			cmp_ok($found, '==', 2, 'Should have been 2 matches');
		} else {
			diag('AUTOMATED_TESTING: Not testing live data');
			skip('AUTOMATED_TESTING: Not testing live data', 5);
		}
	}
}

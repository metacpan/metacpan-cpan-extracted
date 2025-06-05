#!perl -wT

# Check the US database is sensible

use strict;
use warnings;

# use autodie qw(:all);
use Test::DescribeMe qw(extended);	# This can use a lot of resources
use Test::Most tests => 6;

use lib 't/lib';
use MyLogger;

BEGIN { use_ok('Locale::Places::US') }

US: {
	SKIP: {
		if(-d 'lib/Locale/Places/data') {
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
			diag('No data');
			skip('No data', 5);
		}
	}
}

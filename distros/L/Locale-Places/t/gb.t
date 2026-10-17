#!perl -wT

# Check the GB database is sensible

use strict;
use warnings;

# use autodie qw(:all);
use Test::DescribeMe qw(extended);	# This can use a lot of resources
use Test::Most tests => 6;
use Test::Log::Abstraction;

BEGIN {
	use_ok('Locale::Places::GB');
}

GB: {
	SKIP: {
		if((!defined($ENV{'AUTOMATED_TESTING'}) && (!defined($ENV{'NO_NETWORK_TESTING'})) && (-d 'lib/Locale/Places/data'))) {
			Database::Abstraction::init(directory => 'lib/Locale/Places/data');
			my $places = new_ok('Locale::Places::GB' => [logger => new_ok('Test::Log::Abstraction'), no_entry => 1]);

			eval { require 'autodie' };

			my $dover = $places->fetchrow_hashref({ data => 'Dover', type => 'en' });
			if($ENV{'TEST_VERBOSE'}) {
				require Data::Dumper;
				Data::Dumper->import();
				diag(Data::Dumper->new([$dover])->Dump());
			}

			$dover = $places->selectall_hashref({ code2 => $dover->{'code2'} });

			my $found;

			foreach my $entry(@{$dover}) {
				next if(!defined($entry->{'type'}));
				if($ENV{'TEST_VERBOSE'}) {
					diag(Data::Dumper->new([\$entry])->Dump());
				}

				if($entry->{'type'} eq 'en') {
					is($entry->{'data'}, 'Dover', 'English');
					$found++;
				} elsif($entry->{'type'} eq 'fr') {
					is($entry->{'data'}, 'Douvres', 'French');
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

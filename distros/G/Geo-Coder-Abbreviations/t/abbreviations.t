#!perl -w

use strict;
use warnings;
use Test::Most tests => 22;
use Test::NoWarnings;

BEGIN {
	use_ok('Geo::Coder::Abbreviations');
}

ABBREVIATIONS: {
	SKIP: {
		skip('Online tests disabled', 20) unless(-e 't/online.enabled');
		if(my $abbr = new_ok('Geo::Coder::Abbreviations')) {
			cmp_ok($abbr->abbreviate('Road'), 'eq', 'RD', 'Road => RD');
			# I think it should abbreviate to AVE
			cmp_ok($abbr->abbreviate('Avenue'), 'eq', 'AV', 'Avenue => AV');

			my %streets = (
				'SW MACVICAR AVENUE' => 'SW MACVICAR AV',
				'NORFOLK AVENUE' => 'NORFOLK AV',
				'CONNECTICUT AVENUE' => 'CONNECTICUT AV',
				'HOWARD AVENUE' => 'HOWARD AV',
				'MAPLE AVENUE W' => 'MAPLE AV W',
				'SW MACVICAR AVE' => 'SW MACVICAR AV',
				'NORFOLK AVE' => 'NORFOLK AV',
				'CONNECTICUT AVE' => 'CONNECTICUT AV',
				'HOWARD AVE' => 'HOWARD AV',
				'MAPLE AVE W' => 'MAPLE AV W',
				'HIGH STREET' => 'HIGH ST',
				'HIGH ST' => 'HIGH ST',
				'8600 ROCKVILLE PIKE' => '8600 ROCKVILLE PK',
				'39 CROSS STREET' => '39 CROSS ST',	# Not 39 X ST
			);

			while ((my ($k, $v)) = each(%streets)) {
				my $street = uc($k);
				if($street =~ /(.+)\s+(.+)\s+(.+)/) {
					my $a;
					if((lc($2) ne 'cross') && ($a = $abbr->abbreviate($2))) {
						$street = "$1 $a $3";
					} elsif($a = $abbr->abbreviate($3)) {
						$street = "$1 $2 $a";
					}
				} elsif($street =~ /(.+)\s(.+)$/) {
					if(my $a = $abbr->abbreviate($2)) {
						$street = "$1 $a";
					}
				}
				# $street =~ s/^0+//;	# Turn 04th St into 4th St
				cmp_ok($street, 'eq', $v, "$k => $v (got $street)");
			}

			# Second and subsequent should not need to download the database
			#	Verify that by checking in coverage tools
			$abbr = new_ok('Geo::Coder::Abbreviations');
			cmp_ok($abbr->abbreviate('Road'), 'eq', 'RD', 'Road => RD');
			cmp_ok($abbr->abbreviate('Avenue'), 'eq', 'AV', 'Avenue => AV');
		} elsif(defined($ENV{'AUTHOR_TESTING'})) {
			fail('Test failed');
			skip('Test failed', 20);
		} else {
			skip("Couldn't instantiate class", 20);
		}
	}
}

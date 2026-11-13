#!perl -T

use strict;
use warnings;

use LWP::UserAgent;
use Test::Most;
use Test::RequiresInternet ('www.loc.gov' => 'https');
use Test::URI;

# tile.loc.gov may refuse automated clients (403) or be unavailable (5xx),
# in which case the link can't be verified, but that's not a failure of this module
sub link_ok {
	my $link = shift;

	my $resp = LWP::UserAgent->new(agent => 'Genealogy-ChroniclingAmerica-test')->head($link);
	if($resp->is_success()) {
		pass("$link is reachable");
	} elsif($resp->code() == 403 || $resp->code() >= 500) {
		diag($link, ': ', $resp->status_line());
		SKIP: { skip('Cannot verify link, server refused or unavailable', 1) }
	} else {
		fail("$link: " . $resp->status_line());
	}
}

BEGIN {
	use_ok('Genealogy::ChroniclingAmerica');
}

CHRONICLING: {
	if(-e 't/online.enabled') {
		my $ca = Genealogy::ChroniclingAmerica->new({
			'firstname' => 'ralph',
			'lastname' => 'bixler',
			'date_of_birth' => 1919,
			'state' => 'Indiana',
		});
		ok(defined($ca));
		ok($ca->isa('Genealogy::ChroniclingAmerica'));

		my $count = 0;
		sleep(1);
		while(my $link = $ca->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'tile.loc.gov');
			link_ok($link);
			ok($link =~ /\.pdf$/);
			$count++;
		}
		ok(!defined($ca->get_next_entry()));
		SKIP: {
			# loc.gov sometimes answers this search with no results, even after a retry
			skip('loc.gov returned no results for ralph bixler', 1) if(($count == 0) && ($ca->{'matches'} == 0));
			cmp_ok($count, '>', 0, 'At least one match found');
		}

		$ca = Genealogy::ChroniclingAmerica->new(
			'firstname' => 'mahalan',
			'lastname' => 'sargent',
			# 'date_of_birth' => 1895,
			'date_of_death' => 1895,
			'state' => 'Indiana',
		);
		ok(defined($ca));
		ok($ca->isa('Genealogy::ChroniclingAmerica'));

		ok(!defined($ca->get_next_entry()));

		$ca = Genealogy::ChroniclingAmerica->new({
			'firstname' => 'katherine',
			'lastname' => 'bixler',
			'date_of_birth' => 1789,
			'date_of_death' => 1789,
			'state' => 'Indiana',
		});
		ok(defined($ca));
		ok($ca->isa('Genealogy::ChroniclingAmerica'));

		ok(!defined($ca->get_next_entry()));

		$ca = Genealogy::ChroniclingAmerica->new({
			'firstname' => 'harry',
			'middlename' => 'james',
			'lastname' => 'maxted',
			'date_of_birth' => 1943,
			'date_of_death' => 1943,
			'state' => 'District of Columbia',
		});
		ok(defined($ca));
		ok($ca->isa('Genealogy::ChroniclingAmerica'));

		$count = 0;
		sleep(1);
		while(my $link = $ca->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'tile.loc.gov');
			link_ok($link);
			ok($link =~ /\.pdf$/);
			$count++;
		}
		ok(!defined($ca->get_next_entry()));
		SKIP: {
			# loc.gov is sometimes unavailable (503) or answers with no results, even after a retry
			skip('loc.gov returned no results for harry maxted', 1) if(($count == 0) && ($ca->{'matches'} == 0));
			ok($count > 0, 'At least one match found');
		}
	}
}

done_testing();

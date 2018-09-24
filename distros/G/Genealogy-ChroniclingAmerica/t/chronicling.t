#!perl -T

use strict;
use warnings;
use Test::Most;
use Test::URI;

CHRONICLING: {
	unless(-e 't/online.enabled') {
		plan skip_all => 'On-line tests disabled';
	} else {
		plan tests => 9;

		use_ok('Genealogy::ChroniclingAmerica');

		my $ca = Genealogy::ChroniclingAmerica->new({
			'firstname' => 'ralph',
			'lastname' => 'bixler',
			'date_of_birth' => 1912,
			'state' => 'Indiana',
		});
		ok(defined($ca));
		ok($ca->isa('Genealogy::ChroniclingAmerica'));

		my $count = 0;
		while(my $link = $ca->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'chroniclingamerica.loc.gov');
			$count++;
		}
		ok(!defined($ca->get_next_entry()));
		ok($count > 0);

		my $ca = Genealogy::ChroniclingAmerica->new({
			'firstname' => 'mahalan',
			'lastname' => 'sargent',
			'date_of_birth' => 1895,
			'date_of_death' => 1895,
			'state' => 'Indiana',
		});
		ok(defined($ca));
		ok($ca->isa('Genealogy::ChroniclingAmerica'));

		ok(!defined($ca->get_next_entry()));
	}
}

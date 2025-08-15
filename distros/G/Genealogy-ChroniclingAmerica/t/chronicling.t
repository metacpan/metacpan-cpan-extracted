#!perl -T

use strict;
use warnings;

use Test::HTTPStatus;
use Test::Most;
use Test::RequiresInternet ('www.loc.gov' => 'https');
use Test::URI;

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
		while(my $link = $ca->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'tile.loc.gov');
			http_ok($link, HTTP_OK);
			ok($link =~ /\.pdf$/);
			$count++;
		}
		ok(!defined($ca->get_next_entry()));
		cmp_ok($count, '>', 0, 'At least one match found');

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
		while(my $link = $ca->get_next_entry()) {
			diag($link);
			uri_host_ok($link, 'tile.loc.gov');
			http_ok($link, HTTP_OK);
			ok($link =~ /\.pdf$/);
			$count++;
		}
		ok(!defined($ca->get_next_entry()));
		ok($count > 0);
	}
}

done_testing();

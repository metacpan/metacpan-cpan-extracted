#!perl -w

use strict;

use lib 'lib';
use Test::Most;
use Genealogy::ChroniclingAmerica;

NEW: {
	if(-e 't/online.enabled') {
		plan tests => 2;

		my $args = {
			'firstname' => 'ralph',
			'lastname' => 'bixler',
			'date_of_birth' => 1912,
			'state' => 'Indiana',
		};

		isa_ok(Genealogy::ChroniclingAmerica->new($args), 'Genealogy::ChroniclingAmerica', 'Creating Genealogy::ChroniclingAmerica object');
		ok(!defined(Genealogy::ChroniclingAmerica::new()));
	} else {
		plan(skip_all => 'On-line tests disabled');
	}
}

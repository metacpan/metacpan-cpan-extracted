#!perl -wT

use strict;
use warnings;
use Test::Most;
use Test::Needs 'Test::Carp';
use Genealogy::ChroniclingAmerica;

CARP: {
	Test::Carp->import();

	does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new() }, qr/Firstname is not optional/);
	does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new({ firstname => 'Nigel '}) }, qr/^Lastname is not optional/);
	does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new( lastname => ' Horne') }, qr/^Firstname is not optional/);
	does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new({ firstname => '12345', lastname => 'Horne'}) }, qr/invalid input/);
	does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new({ firstname => 'Nigel', lastname => 'Horne'}) }, qr/^State is not optional/);
	does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new({
		'firstname' => 'ralph',
		'lastname' => 'bixler',
		'date_of_birth' => 1912,
		'state' => 'IN',
	}) }, qr/State needs to be the full name/);

	done_testing();
}

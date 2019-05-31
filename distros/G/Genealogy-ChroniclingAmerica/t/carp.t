#!perl -wT

use strict;
use warnings;
use Test::Most;
use Genealogy::ChroniclingAmerica;

eval 'use Test::Carp';

CARP: {
	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new() }, qr/^Usage: /);
		does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new({ firstname => 'Nigel '}) }, qr/^Last name is not optional/);
		does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new( lastname => ' Horne') }, qr/^First name is not optional/);
		does_croak_that_matches(sub { Genealogy::ChroniclingAmerica->new({ firstname => 'Nigel', lastname => 'Horne'}) }, qr/^State is not optional/);
		done_testing();
	}
}

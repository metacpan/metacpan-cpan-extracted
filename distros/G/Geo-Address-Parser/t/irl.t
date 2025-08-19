#!perl -wT

use strict;
use warnings;
use Test::Most;
use utf8;

use_ok('Geo::Address::Parser::Rules::IRL');

my @tests = (
	{
		input => '123 Main Street, Dublin 2, D02 Y006, Ireland',
		expect => {
			name => undef,
			road => '123 Main Street',
			city => 'Dublin 2',
			region => undef,
			postal_code => 'D02 Y006',
			country => 'Ireland',
		},
	}, {
		input => 'The Mill House, Ballynahinch, Co. Galway',
		expect => {
			name => 'The Mill House',
			city => 'Ballynahinch',
			road => undef,
			region => 'Galway',
			postal_code => undef,
			country => 'Ireland',
		},
	}, {
		input => "45 O'Connell Road, Limerick, Co. Limerick",
		expect => {
			name => undef,
			road => "45 O'Connell Road",
			city => 'Limerick',
			region => 'Limerick',
			postal_code => undef,
			country => 'Ireland',
		},
	}, {
		input => '12 High Street, Dublin 8, Ireland',
		expect => {
			name => undef,
			road => '12 High Street',
			city => 'Dublin 8',
			region => undef,
			postal_code => undef,
			country => 'Ireland',
		},
	},
);

foreach my $t (@tests) {
	my $parsed = Geo::Address::Parser::Rules::IRL->parse_address($t->{input});

	cmp_deeply($parsed, $t->{expect}, "$t->{input} parsed correctly");

	foreach my $field (qw(name road city region postal_code country)) {
		is(
			(defined $parsed->{$field} ? $parsed->{$field} : undef),
			(defined $t->{expect}{$field} ? $t->{expect}{$field} : undef),
			"$t->{input} => $field"
		);
	}
}

done_testing();

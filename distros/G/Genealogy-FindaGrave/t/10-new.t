#!perl -w

use strict;
use warnings;

use Test::Most tests => 6;

BEGIN { use_ok('Genealogy::FindaGrave') }

NEW: {
	if(-e 't/online.enabled') {
		my %args = (
			'firstname' => 'john',
			'lastname' => 'smith',
			'date_of_birth' => 1912
		);

		isa_ok(Genealogy::FindaGrave->new(%args), 'Genealogy::FindaGrave', 'Creating Genealogy::FindaGrave object');

		# Create a new object with direct key-value pairs
		my $obj = Genealogy::FindaGrave->new(%args);
		cmp_ok($obj->{firstname}, 'eq', 'john', 'direct key-value pairs');

		# Create a new object with hash ref
		$obj = Genealogy::FindaGrave->new(\%args);
		cmp_ok($obj->{firstname}, 'eq', 'john', 'hash ref');

		# Test cloning behavior by calling new() on an existing object
		my $obj2 = $obj->new({ firstname => 'nigel' });
		cmp_ok($obj2->{lastname}, 'eq', 'smith', 'clone keeps old args');
		cmp_ok($obj2->{firstname}, 'eq', 'nigel', 'clone adds new args');
	} else {
		SKIP: {
			skip('On-line tests disabled', 5);
		}
	}
}

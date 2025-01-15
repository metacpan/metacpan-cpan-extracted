#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

if(-e 't/online.enabled') {
	plan tests => 4;

	use_ok('Genealogy::FindaGrave');

	# Test instantiation of the module
	subtest 'Constructor tests' => sub {
		my $obj = Genealogy::FindaGrave->new({
			firstname => 'Edmund',
			lastname => 'Horne',
			date_of_death => 1945,
		});

		ok($obj, 'Object created successfully');
		isa_ok($obj, 'Genealogy::FindaGrave', 'Object is of correct class');

		dies_ok { Genealogy::FindaGrave->new(lastname => 'Horne') }
			'Dies if firstname is missing';

		dies_ok { Genealogy::FindaGrave->new({ firstname => 'Edmund' }) }
			'Dies if lastname is missing';

		dies_ok { Genealogy::FindaGrave->new({ firstname => 'Edmund', lastname => 'Horne' }) }
			'Dies if both date_of_birth and date_of_death are missing';

		dies_ok {
			my $obj = Genealogy::FindaGrave->new({
				firstname => 'InvalidName',
				lastname => 'InvalidLastName',
				date_of_death => 9999
			})
		} 'Dies if year in the future';
	};

	# Test fetching entries
	subtest 'Fetch entries' => sub {
		my $obj = Genealogy::FindaGrave->new({
			firstname => 'Edmund',
			lastname => 'Horne',
			date_of_death => 1945,
		});

		if(my $entry = $obj->get_next_entry()) {
			like($entry, qr{/memorial/\d+/}, 'URL format is correct');
		} else {
			pass('No entries found, but method did not fail');
		}
	};

	# Test handling of invalid requests
	subtest 'Invalid requests' => sub {
		my $obj = Genealogy::FindaGrave->new({
			firstname => 'InvalidName',
			lastname => 'InvalidLastName',
			date_of_death => 2000
		});

		my $entry = $obj->get_next_entry();
		ok(!defined($entry), 'No entries returned for invalid data');
	};
} else {
	plan skip_all => 'On-line tests disabled';
}

done_testing();

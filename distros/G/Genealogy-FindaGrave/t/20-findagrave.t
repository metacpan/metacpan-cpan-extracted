#!perl -T

use strict;
use warnings;
use Test::Most;
use Test::URI;

FINDAGRAVE: {
	unless(-e 't/online.enabled') {
		plan skip_all => 'On-line tests disabled';
	} else {
		plan tests => 15;

		use_ok('Genealogy::FindaGrave');
		my $f = Genealogy::FindaGrave->new({
			firstname => 'Daniel',
			lastname => 'Culmer',
			country => 'England',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('Genealogy::FindaGrave'));

		my $count = 0;
		while(my $link = $f->get_next_entry()) {
			diag($link) if($ENV{'TEST_VERBOSE'});
			uri_host_ok($link, 'www.findagrave.com');
			$count++;
		}
		ok(!defined($f->get_next_entry()));
		cmp_ok($count, '>', 0, 'Found at least one entry');

		$f = Genealogy::FindaGrave->new({
			firstname => 'xyzzy',
			lastname => 'plugh',
			country => 'Canada',
			date_of_birth => 1862
		});

		ok(defined $f);
		ok($f->isa('Genealogy::FindaGrave'));
		ok(!defined($f->get_next_entry()));

		$f = Genealogy::FindaGrave->new({
			firstname => 'Daniel',
			middlename => 'John',
			lastname => 'Culmer',
			country => 'England',
			date_of_death => 1862
		});
		ok(defined $f);
		ok($f->isa('Genealogy::FindaGrave'));
		ok(!defined($f->get_next_entry()));

		$f = Genealogy::FindaGrave->new(
			firstname => 'Daniel',
			lastname => 'Culmer',
			country => 'United States',
			date_of_death => 1862
		);
		ok(defined $f);
		ok($f->isa('Genealogy::FindaGrave'));
		ok(!defined($f->get_next_entry()));
	}
}

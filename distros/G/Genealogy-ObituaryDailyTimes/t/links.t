#!perl -w

use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Pod::LinkCheck';
	if($@) {
		plan(skip_all => 'Test::Pod::LinkCheck required for testing POD');
	} else {
		Test::Pod::LinkCheck->new->all_pod_ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}

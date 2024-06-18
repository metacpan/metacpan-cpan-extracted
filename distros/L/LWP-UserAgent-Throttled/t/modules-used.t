#!perl -w

use warnings;
use strict;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Module::Used';
	if($@) {
		plan(skip_all => 'Test::Module::Used required for testing all modules needed');
	} else {
		my $used = Test::Module::Used->new(meta_file => 'MYMETA.yml');
		$used->ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}

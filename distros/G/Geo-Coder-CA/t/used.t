#!perl -w

use strict;
use Test::Most;

unless($ENV{RELEASE_TESTING}) {
	plan(skip_all => "Author tests not required for installation");
}

eval 'use Test::Module::Used';
if($@) {
	plan(skip_all => 'Test::Module::Used required for testing all modules needed');
} else {
	my $used = Test::Module::Used->new(meta_file => 'MYMETA.yml');
	# Geo::Coder::Free::Validate is optional: geocode() asks it when it is
	# installed and refuses a reference when it is not, and t/reference.t skips
	# the checks that compare against it when it is missing.  It cannot be a
	# prerequisite, so neither check may expect one.
	$used->push_exclude_in_libdir('Geo::Coder::Free::Validate');
	$used->push_exclude_in_testdir('Geo::Coder::Free::Validate');
	$used->ok();
}

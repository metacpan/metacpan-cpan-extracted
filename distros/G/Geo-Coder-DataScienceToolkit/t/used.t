#!perl -w

use strict;
use Test::Most;

unless($ENV{AUTHOR_TESTING}) {
	plan(skip_all => "Author tests not required for installation");
}

eval 'use Test::Module::Used';
if($@) {
	plan(skip_all => 'Test::Module::Used required for testing all modules needed');
} else {
	my $used = Test::Module::Used->new(meta_file => 'MYMETA.yml');
	# Geo::Location::Predicate is a recommendation at runtime, not a
	# prerequisite: geocode() asks it when it is installed and refuses a
	# reference when it is not.  It is in TEST_REQUIRES because the tests are
	# graded against it, so the library's use of it is excluded here and nothing
	# expects one of the runtime prereqs.
	$used->push_exclude_in_libdir('Geo::Location::Predicate');
	$used->ok();
}

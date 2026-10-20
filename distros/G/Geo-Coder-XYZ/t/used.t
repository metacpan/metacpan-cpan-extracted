#!perl -w

use strict;
use warnings;
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
	# reference when it is not, and t/reference.t skips the comparisons it
	# cannot make.  The tests are graded against it, so it is in TEST_REQUIRES,
	# but a check of the runtime prereqs must not expect one.
	$used->push_exclude_in_libdir('Geo::Location::Predicate');
	$used->ok();
}

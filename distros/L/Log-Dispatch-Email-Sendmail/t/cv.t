#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::ConsistentVersion";

plan skip_all => "Test::ConsistentVersion required for checking versions" if $@;

Test::ConsistentVersion::check_consistent_versions();

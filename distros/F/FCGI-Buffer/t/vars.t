#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Vars';

	plan(skip_all => 'Test::Vars required for detecting unused variables') if $@;

	all_vars_ok();
} else {
	plan(skip_all => 'Author tests not required for installation');
}

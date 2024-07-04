#!/usr/bin/env perl

use strict;
use warnings;
use Test::Needs 'Test::Version';
use Test::Most;

BEGIN {
	if($ENV{'AUTHOR_TESTING'}) {
		Test::Version->import();
		version_all_ok();
		done_testing();
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}

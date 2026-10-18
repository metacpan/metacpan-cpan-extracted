#!/usr/bin/env perl

use strict;
use warnings;
use Test::Needs 'Test::EOF';
use Test::Most;

BEGIN {
	if($ENV{'AUTHOR_TESTING'}) {
		Test::EOF->import();
		all_perl_files_ok({ minimum_newlines => 1, maximum_newlines => 4 });
		done_testing();
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}

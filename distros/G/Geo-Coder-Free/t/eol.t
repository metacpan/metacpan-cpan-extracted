#!/usr/bin/env perl

use strict;
use warnings;
use Test::Needs 'Test::EOL';
use Test::Most;

BEGIN {
	if($ENV{'AUTHOR_TESTING'}) {
		Test::EOL->import();
		all_perl_files_ok({ trailing_whitespace => 1 });
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}

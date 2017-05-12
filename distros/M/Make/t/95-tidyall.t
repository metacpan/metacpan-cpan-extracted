use strict;
use warnings;

use Test::More;

unless ( $ENV{AUTHOR_TESTING} ) {
	plan skip_all => 'Author test, set $ENV{AUTHOR_TESTING} to run';
}

## no critic
eval 'use Test::Code::TidyAll 0.41';
plan skip_all => 'Test::Code::TidyAll 0.41 required to check if the code is clean.'
	if $@;
tidyall_ok();

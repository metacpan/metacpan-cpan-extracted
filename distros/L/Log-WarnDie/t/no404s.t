#!perl -wT

use strict;
use warnings;
use Test::Most;

if(not $ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::Pod::No404s";
if($@) {
	plan skip_all => 'Test::Pod::No404s required for testing POD';
} else {
	all_pod_files_ok();
}

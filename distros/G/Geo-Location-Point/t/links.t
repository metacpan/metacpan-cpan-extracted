#!perl -w

use strict;
use warnings;
use Test::Most;

if(not $ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::Pod::LinkCheck";
if($@) {
	plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
} else {
	Test::Pod::LinkCheck->new->all_pod_ok();
}

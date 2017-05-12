#!perl -wT

use strict;
use warnings;
use Test::Most;

my $can_test = 1;

if($ENV{RELEASE_TESTING}) {
	eval {
		use Test::Requires {
			'warnings::unused' => 0.04
		};
	};
	if($@) {
		plan(skip_all => 'Test::Requires needed for installation');
		$can_test = 0;
	}
}

if($can_test) {
	BEGIN {
		if($ENV{RELEASE_TESTING}) {
			use_ok('CGI::Info');
			use warnings::unused -global;
		}
	}

	if(not $ENV{RELEASE_TESTING}) {
		plan(skip_all => 'Author tests not required for installation');
	} else {
		new_ok('CGI::Info');
		plan tests => 1;
	}
}

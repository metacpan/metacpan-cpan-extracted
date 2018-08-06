#!perl -wT

use strict;
use warnings;
use Test::Most;

my $can_test = 1;

if($ENV{AUTHOR_TESTING}) {
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
		if($ENV{AUTHOR_TESTING}) {
			use_ok('File::Print::Many');
			use warnings::unused;
		}
	}

	if(not $ENV{AUTHOR_TESTING}) {
		plan(skip_all => 'Author tests not required for installation');
	} else {
		new_ok('File::Print::Many' => [ fds => [ *STDERR ] ]);
		plan tests => 2;
	}
}

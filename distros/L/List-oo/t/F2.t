use Test::More qw(
	no_plan
	);

use warnings;
use strict;

BEGIN {
	use_ok('List::oo', qw());
}

eval('_{7+4}');
ok(($@ || '') =~ m/^Can't call/);


use warnings;
use strict;

use Test::More tests => 1;

BEGIN {
	require XSLoader;
	my $orig_load = \&XSLoader::load;
	no warnings "redefine";
	*XSLoader::load = sub {
		die "XS loading disabled for Devel::GoFaster"
			if ($_[0] || "") eq "Devel::GoFaster";
		goto &$orig_load;
	};
}

use Devel::GoFaster;

ok 1;

1;

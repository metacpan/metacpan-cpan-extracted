use warnings;
use strict;

use Test::More tests => 2;

our $native_package;

BEGIN {
	our $package;
	{
		package Foo;
		require t::package_0;
	}
	$native_package = $package;
	$package = undef;
	delete $INC{"t/package_0.pm"};
}

BEGIN { use_ok "Lexical::SealRequireHints"; }

our $package;
{
	package Foo;
	require t::package_0;
}
is $package, $native_package;

1;

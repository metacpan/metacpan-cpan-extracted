use warnings;
use strict;

use Test::More tests => 3;

BEGIN { unshift @INC, "./t/lib"; }

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
$package = undef;
delete $INC{"t/package_0.pm"};

{
	package Foo;
	do "t/package_0.pm" or die $@ || $!;
}
is $package, $native_package;
$package = undef;
delete $INC{"t/package_0.pm"};

1;

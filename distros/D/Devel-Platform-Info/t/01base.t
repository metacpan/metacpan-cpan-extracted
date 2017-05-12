#!/usr/bin/perl -w
use strict;

use Test::More tests => 9;

BEGIN {
	use_ok( 'Devel::Platform::Info' );
	use_ok( 'Devel::Platform::Info::BSD' );
	use_ok( 'Devel::Platform::Info::BeOS' );
	use_ok( 'Devel::Platform::Info::Irix' );
	use_ok( 'Devel::Platform::Info::Linux' );
	use_ok( 'Devel::Platform::Info::Mac' );
	use_ok( 'Devel::Platform::Info::SCO' );
	use_ok( 'Devel::Platform::Info::Solaris' );
	use_ok( 'Devel::Platform::Info::Win32' );
}

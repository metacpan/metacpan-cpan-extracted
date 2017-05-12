#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Debian::ModuleList' );
}

diag( "Testing Debian::ModuleList $Debian::ModuleList::VERSION, Perl $], $^X" );

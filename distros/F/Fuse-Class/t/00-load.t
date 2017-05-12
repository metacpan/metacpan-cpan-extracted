#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fuse::Class' );
}

diag( "Testing Fuse::Class $Fuse::Class::VERSION, Perl $], $^X" );

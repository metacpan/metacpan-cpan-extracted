#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fuse::Simple' );
}

diag( "\nTesting Fuse::Simple $Fuse::Simple::VERSION, Perl $], $^X" );

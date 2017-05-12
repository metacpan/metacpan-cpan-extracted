#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Fuse::Filesys::Virtual' );
}

diag( "Testing Fuse::Filesys::Virtual $Fuse::Filesys::Virtual::VERSION, Perl $], $^X" );

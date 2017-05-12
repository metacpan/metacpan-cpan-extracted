#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IO::All::SFTP' );
}

diag( "Testing IO::All::SFTP $IO::All::SFTP::VERSION, Perl $], $^X" );

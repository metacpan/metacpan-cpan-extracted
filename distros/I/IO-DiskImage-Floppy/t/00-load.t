#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'IO::DiskImage::Floppy' );
}

diag( "Testing IO::DiskImage::Floppy $IO::DiskImage::Floppy::VERSION, Perl $], $^X" );

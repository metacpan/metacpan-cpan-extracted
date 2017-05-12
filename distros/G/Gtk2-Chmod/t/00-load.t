#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Chmod' );
}

diag( "Testing Gtk2::Chmod $Gtk2::Chmod::VERSION, Perl $], $^X" );

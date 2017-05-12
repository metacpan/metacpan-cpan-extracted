#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Notify' );
}

diag( "Testing Gtk2::Notify $Gtk2::Notify::VERSION, Perl $], $^X" );

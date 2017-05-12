#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::PathButtonBar' );
}

diag( "Testing Gtk2::PathButtonBar $Gtk2::PathButtonBar::VERSION, Perl $], $^X" );

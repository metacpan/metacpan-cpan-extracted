#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Ex::CalendarButton' );
}

diag( "Testing Gtk2::Ex::CalendarButton $Gtk2::Ex::CalendarButton::VERSION, Perl $], $^X" );

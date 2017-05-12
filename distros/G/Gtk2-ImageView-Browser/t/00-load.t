#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::ImageView::Browser' );
}

diag( "Testing Gtk2::ImageView::Browser $Gtk2::ImageView::Browser::VERSION, Perl $], $^X" );

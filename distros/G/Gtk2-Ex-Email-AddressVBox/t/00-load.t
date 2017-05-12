#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Ex::Email::AddressVBox' );
}

diag( "Testing Gtk2::Ex::Email::AddressVBox $Gtk2::Ex::Email::AddressVBox::VERSION, Perl $], $^X" );

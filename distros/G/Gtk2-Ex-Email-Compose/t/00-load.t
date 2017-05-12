#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Ex::Email::Compose' );
}

diag( "Testing Gtk2::Ex::Email::Compose $Gtk2::Ex::Email::Compose::VERSION, Perl $], $^X" );

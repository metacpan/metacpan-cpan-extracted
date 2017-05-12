#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Ex::Email::AAnotebook' );
}

diag( "Testing Gtk2::Ex::Email::AAnotebook $Gtk2::Ex::Email::AAnotebook::VERSION, Perl $], $^X" );

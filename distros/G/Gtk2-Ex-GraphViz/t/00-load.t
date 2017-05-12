#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Gtk2::Ex::GraphViz' );
}

diag( "Testing Gtk2::Ex::GraphViz $Gtk2::Ex::GraphViz::VERSION, Perl $], $^X" );

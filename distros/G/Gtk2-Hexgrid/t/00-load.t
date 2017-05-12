#!perl -T

#use Test::More tests => 1;
#use lib "./lib/";
use Gtk2::TestHelper tests => 1;

BEGIN {
    use_ok( 'Gtk2::Hexgrid' );
}

diag( "Testing Gtk2::Hexgrid $Gtk2::Hexgrid::VERSION, Perl $], $^X" );

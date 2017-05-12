#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Games::EternalLands::Binary::Unitvec16' ) || print "Bail out!\n";
}

diag( "Testing Games::EternalLands::Binary::Unitvec16 $Games::EternalLands::Binary::Unitvec16::VERSION, Perl $], $^X" );

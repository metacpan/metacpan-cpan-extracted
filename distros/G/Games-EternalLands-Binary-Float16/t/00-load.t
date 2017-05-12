#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Games::EternalLands::Binary::Float16' ) || print "Bail out!\n";
}

diag( "Testing Games::EternalLands::Binary::Float16 $Games::EternalLands::Binary::Float16::VERSION, Perl $], $^X" );

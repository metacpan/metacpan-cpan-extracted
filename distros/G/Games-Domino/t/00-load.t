#!perl

use 5.006;
use strict; use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok( 'Games::Domino' )         || print "Bail out!\n";
    use_ok( 'Games::Domino::Player' ) || print "Bail out!\n";
    use_ok( 'Games::Domino::Tile' )   || print "Bail out!\n";
    use_ok( 'Games::Domino::Params' ) || print "Bail out!\n";
}

diag( "Testing Games::Domino $Games::Domino::VERSION, Perl $], $^X" );

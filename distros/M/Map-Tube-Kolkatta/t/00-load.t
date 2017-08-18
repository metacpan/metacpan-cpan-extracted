#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

BEGIN {
    use_ok( 'Map::Tube::Kolkatta')            || print "Bail out!\n";
    use_ok( 'Map::Tube::Kolkatta::Line::L1')  || print "Bail out!\n";
    use_ok( 'Map::Tube::Kolkatta::Line::L2')  || print "Bail out!\n";
    use_ok( 'Map::Tube::Kolkatta::Line::L3')  || print "Bail out!\n";
    use_ok( 'Map::Tube::Kolkatta::Line::L4')  || print "Bail out!\n";
    use_ok( 'Map::Tube::Kolkatta::Line::L5')  || print "Bail out!\n";
    use_ok( 'Map::Tube::Kolkatta::Line::L6')  || print "Bail out!\n";
}

diag( "Testing Map::Tube::Kolkatta $Map::Tube::Kolkatta::VERSION, Perl $], $^X" );

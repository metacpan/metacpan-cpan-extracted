#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

BEGIN {
    use_ok( 'Map::Tube::Delhi'               ) || print "Bail out!\n";
    use_ok( 'Map::Tube::Delhi::Line::Blue'   ) || print "Bail out!\n";
    use_ok( 'Map::Tube::Delhi::Line::Red'    ) || print "Bail out!\n";
    use_ok( 'Map::Tube::Delhi::Line::Green'  ) || print "Bail out!\n";
    use_ok( 'Map::Tube::Delhi::Line::Orange' ) || print "Bail out!\n";
    use_ok( 'Map::Tube::Delhi::Line::Violet' ) || print "Bail out!\n";
    use_ok( 'Map::Tube::Delhi::Line::Yellow' ) || print "Bail out!\n";
}

diag( "Testing Map::Tube::Delhi $Map::Tube::Delhi::VERSION, Perl $], $^X" );

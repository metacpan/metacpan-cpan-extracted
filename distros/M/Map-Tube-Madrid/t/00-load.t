#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

BEGIN {
    use_ok('Map::Tube::Madrid')            || print "Bail out!\n";
    use_ok('Map::Tube::Madrid::Line::L1')  || print "Bail out!\n";
    use_ok('Map::Tube::Madrid::Line::L2')  || print "Bail out!\n";
    use_ok('Map::Tube::Madrid::Line::L3')  || print "Bail out!\n";
    use_ok('Map::Tube::Madrid::Line::L5')  || print "Bail out!\n";
    use_ok('Map::Tube::Madrid::Line::L11') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Madrid $Map::Tube::Madrid::VERSION, Perl $], $^X" );

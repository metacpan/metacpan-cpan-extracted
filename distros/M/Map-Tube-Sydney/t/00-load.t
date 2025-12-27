#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 15;

BEGIN {
    use_ok('Map::Tube::Sydney')           || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T1') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T2') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T3') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T4') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T5') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T6') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T7') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T8') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::T9') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::M1') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::L1') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::L2') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::L3') || print "Bail out!\n";
    use_ok('Map::Tube::Sydney::Line::L4') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Sydney $Map::Tube::Sydney::VERSION, Perl $], $^X" );

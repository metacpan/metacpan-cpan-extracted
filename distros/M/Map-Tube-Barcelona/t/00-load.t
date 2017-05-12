#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;

BEGIN {
    use_ok('Map::Tube::Barcelona')            || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L1')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L2')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L3')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L4')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L5')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L6')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L7')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L8')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L9')  || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L10') || print "Bail out!\n";
    use_ok('Map::Tube::Barcelona::Line::L11') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Barcelona $Map::Tube::Barcelona::VERSION, Perl $], $^X" );

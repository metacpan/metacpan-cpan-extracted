#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;

BEGIN {
    use_ok('Map::Tube::London')                        || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Bakerloo')        || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Central')         || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Circle')          || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::District')        || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::DLR')             || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::HammersmithCity') || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Jubilee')         || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Metropolitan')    || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Overground')      || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Piccadilly')      || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Northern')        || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::Victoria')        || print "Bail out!\n";
    use_ok('Map::Tube::London::Line::WaterlooCity')    || print "Bail out!\n";
}

diag( "Testing Map::Tube::London $Map::Tube::London::VERSION, Perl $], $^X" );

#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 8;

BEGIN {
    use_ok('Map::Tube')            || print "Bail out!\n";
    use_ok('Map::Tube::Node')      || print "Bail out!\n";
    use_ok('Map::Tube::Line')      || print "Bail out!\n";
    use_ok('Map::Tube::Table')     || print "Bail out!\n";
    use_ok('Map::Tube::Route')     || print "Bail out!\n";
    use_ok('Map::Tube::Utils')     || print "Bail out!\n";
    use_ok('Map::Tube::Types')     || print "Bail out!\n";
    use_ok('Map::Tube::Pluggable') || print "Bail out!\n";
}

diag( "Testing Map::Tube $Map::Tube::VERSION, Perl $], $^X" );

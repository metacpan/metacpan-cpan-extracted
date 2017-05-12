#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('Map::Tube::Tokyo')                || print "Bail out!\n";
    use_ok('Map::Tube::Tokyo::Line::Asakusa') || print "Bail out!\n";
    use_ok('Map::Tube::Tokyo::Line::Chiyoda') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Tokyo $Map::Tube::Tokyo::VERSION, Perl $], $^X" );

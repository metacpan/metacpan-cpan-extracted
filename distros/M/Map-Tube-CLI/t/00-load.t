#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Map::Tube::CLI')         || print "Bail out!\n";
    use_ok('Map::Tube::CLI::Option') || print "Bail out!\n";
}

diag( "Testing Map::Tube::CLI $Map::Tube::CLI::VERSION, Perl $], $^X" );

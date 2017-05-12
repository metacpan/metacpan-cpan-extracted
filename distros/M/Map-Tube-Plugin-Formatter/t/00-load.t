#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

BEGIN {
    use_ok('Map::Tube::Plugin::Formatter')        || print "Bail out!\n";
    use_ok('Map::Tube::Plugin::Formatter::Utils') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Plugin::Formatter $Map::Tube::Plugin::Formatter::VERSION, Perl $], $^X" );

#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok('Map::Tube::API')            || print "Bail out!\n";
    use_ok('Map::Tube::API::UserAgent') || print "Bail out!\n";
    use_ok('Map::Tube::API::Exception') || print "Bail out!\n";
}

diag( "Testing Map::Tube::API $Map::Tube::API::VERSION, Perl $], $^X" );

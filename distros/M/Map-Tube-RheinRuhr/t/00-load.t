#!perl -T
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::RheinRuhr') || print "Bail out!\n"; }

diag( "Testing Map::Tube::RheinRuhr $Map::Tube::RheinRuhr::VERSION, Perl $], $^X" );

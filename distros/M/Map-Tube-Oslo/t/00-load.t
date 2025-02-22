#!perl -T
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Oslo') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Oslo $Map::Tube::Oslo::VERSION, Perl $], $^X" );

#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Paris') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Paris $Map::Tube::Paris::VERSION, Perl $], $^X" );

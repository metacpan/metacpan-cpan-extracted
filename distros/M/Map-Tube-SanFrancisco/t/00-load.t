#!perl -T
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::SanFrancisco') || print "Bail out!\n"; }

diag( "Testing Map::Tube::SanFrancisco $Map::Tube::SanFrancisco::VERSION, Perl $], $^X" );

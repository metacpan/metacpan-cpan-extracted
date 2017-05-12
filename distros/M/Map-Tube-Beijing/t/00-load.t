#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Beijing') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Beijing $Map::Tube::Beijing::VERSION, Perl $], $^X" );

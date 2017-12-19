#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Copenhagen') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Copenhagen $Map::Tube::Copenhagen::VERSION, Perl $], $^X" );

#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Madrid') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Madrid $Map::Tube::Madrid::VERSION, Perl $], $^X" );

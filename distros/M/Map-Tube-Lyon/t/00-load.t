#!perl -T

use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Lyon') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Lyon $Map::Tube::Lyon::VERSION, Perl $], $^X" );

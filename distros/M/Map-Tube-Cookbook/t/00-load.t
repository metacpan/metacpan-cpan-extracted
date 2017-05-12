#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Cookbook') || print "Bail out!\n"; }
diag( "Testing Map::Tube::Cookbook $Map::Tube::Cookbook::VERSION, Perl $], $^X" );

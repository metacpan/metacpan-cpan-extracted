#!perl -T
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Hamburg') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Hamburg $Map::Tube::Hamburg::VERSION, Perl $], $^X" );

#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Napoli') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Napoli $Map::Tube::Napoli::VERSION, Perl $], $^X" );

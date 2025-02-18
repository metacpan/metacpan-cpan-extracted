#!perl -T
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Glasgow') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Glasgow $Map::Tube::Glasgow::VERSION, Perl $], $^X" );

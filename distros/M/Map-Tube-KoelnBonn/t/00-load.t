#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::KoelnBonn') || print "Bail out!\n"; }

diag( "Testing Map::Tube::KoelnBonn $Map::Tube::KoelnBonn::VERSION, Perl $], $^X" );

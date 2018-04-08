#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Map::Tube::Server') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Server $Map::Tube::Server::VERSION, Perl $], $^X" );

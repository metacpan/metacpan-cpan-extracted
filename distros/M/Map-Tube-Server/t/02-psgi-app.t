#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN { use_ok('Map::Tube::Server') || print "Bail out!\n"; }

can_ok( 'Map::Tube::Server', 'to_app' );

my $app = Map::Tube::Server->to_app;
isa_ok( $app, 'CODE', 'to_app returns a code reference' );

done_testing;

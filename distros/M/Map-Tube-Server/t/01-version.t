#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN { use_ok('Map::Tube::Server') || print "Bail out!\n"; }

ok( defined $Map::Tube::Server::VERSION,
    'VERSION constant is defined' );

like( $Map::Tube::Server::VERSION,
    qr/^v?\d+\.\d+\.\d+(?:\.\d+)?(_\d+)?$/,
    'VERSION constant looks like a release version' );

is( $Map::Tube::Server::AUTHORITY, 'cpan:MANWAR',
    'AUTHORITY constant is set to cpan:MANWAR' );

done_testing;

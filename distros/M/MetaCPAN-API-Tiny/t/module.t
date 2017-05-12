#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;
use t::lib::Functions;

my $mcpan = mcpan();

isa_ok( $mcpan, 'MetaCPAN::API::Tiny' );
can_ok( $mcpan, 'module'        );

# missing input
like(
    exception { $mcpan->module },
    qr/^Please provide a module name/,
    'Missing any information',
);

my $result = $mcpan->module('Moose');
ok( $result, 'Got result' );


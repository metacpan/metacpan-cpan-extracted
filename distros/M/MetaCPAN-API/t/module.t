use strict;
use warnings;

use lib 't/lib';
use Test::RequiresInternet 'fastapi.metacpan.org' => 443;
use Test::More tests => 4;
use Test::Fatal;
use TestFunctions;

my $mcpan = mcpan();

isa_ok( $mcpan, 'MetaCPAN::API' );
can_ok( $mcpan, 'module'        );

# missing input
like(
    exception { $mcpan->module },
    qr/^Please provide a module name/,
    'Missing any information',
);

my $result = $mcpan->module('Moose');
ok( $result, 'Got result' );


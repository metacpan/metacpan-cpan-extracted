use strict;
use warnings;

use lib 't/lib';
use Test::RequiresInternet 'fastapi.metacpan.org' => 443;
use Test::More tests => 4;
use Test::Fatal;
use TestFunctions;

my $mcpan = mcpan();

isa_ok( $mcpan, 'MetaCPAN::API' );
can_ok( $mcpan, 'author'        );

# missing input
like(
    exception { $mcpan->author },
    qr/^Please provide an author PAUSEID/,
    'Missing any information',
);

my $result = $mcpan->author('DOY');
ok( $result, 'Got result' );


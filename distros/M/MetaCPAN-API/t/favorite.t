use strict;
use warnings;

use lib 't/lib';
use Test::RequiresInternet 'fastapi.metacpan.org' => 443;
use Test::More tests => 5;
use Test::Fatal;
use TestFunctions;

my $mcpan = mcpan();

isa_ok( $mcpan, 'MetaCPAN::API' );
can_ok( $mcpan, 'favorite'      );
my $errmsg = qr/^Only 'search' can be used here/;

# missing input
like(
    exception { $mcpan->favorite },
    $errmsg,
    'Missing any information',
);

# incorrect input
like(
    exception { $mcpan->favorite( ding => 'dong' ) },
    $errmsg,
    'Incorrect input',
);

my $result = $mcpan->favorite(
    search => {
        q => 'distribution:Moose',
        fields => "distribution",
        size   => 100,
    },
);
ok( $result, 'Got result' );

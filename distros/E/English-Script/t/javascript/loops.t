use Test2::V0;
use English::Script;

my $es;
ok( lives { $es = English::Script->new }, 'new' ) or note $@;

is(
    $es->parse(
        ( ref $_->[1] ) ? join( "\n", @{ $_->[1] } ) : $_->[1]
    )->render,
    ( ( ref $_->[2] ) ? join( "\n", @{ $_->[2] } ) : $_->[2] ) . "\n",
    $_->[0],
) for (
    [
        'for each item in items block',
        'For each prime in primes, apply the following block. Add prime to sum. This ends the block.',
        [
            'if ( typeof( prime ) == "undefined" ) var prime = "";',
            'if ( typeof( primes ) == "undefined" ) var primes = "";',
            'if ( typeof( sum ) == "undefined" ) var sum = "";',
            'for ( prime of primes ) {',
            'sum += prime;',
            '}',
        ],
    ],
);

done_testing;

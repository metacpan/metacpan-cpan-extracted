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
        'append "+" to a variable',
        'Append "+" to the answer text.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = "";',
            'answer += "+";',
        ],
    ],
    [
        'append an integer to a list',
        [
            'Set the primes list to 3, 5, and 7.',
            'Append 9 to the primes list.',
        ],
        [
            'if ( typeof( primes ) == "undefined" ) var primes = [];',
            'primes = [ 3, 5, 7 ];',
            'primes.push( 9 );',
        ],
    ],
);

done_testing;

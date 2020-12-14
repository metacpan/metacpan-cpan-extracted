use strict;
use warnings;
use Test::Most;

use_ok('English::Script');

my $es;
lives_ok( sub { $es = English::Script->new }, 'new' );

is(
    $es->parse(
        ( ref $_->[1] ) ? join( "\n", @{ $_->[1] } ) : $_->[1]
    )->render,
    ( ( ref $_->[2] ) ? join( "\n", @{ $_->[2] } ) : $_->[2] ) . "\n",
    $_->[0],
) for (
    [
        'if boolean then say string',
        'If something is true, then say "It\'s true!".',
        [
            'if ( typeof( something ) == "undefined" ) var something = "";',
            'if ( something == true ) {',
            'console.log( "It\'s true!" );',
            '}',
        ],
    ],
    [
        'complex conditional with contains',
        [
            'Set prime to 3.',
            'Set primes to 3, 5, and 7.',
            'If prime is 3 and 7 is in primes and something is true, then set answer to 42.',
        ],
        [
            'if ( typeof( answer ) == "undefined" ) var answer = "";',
            'if ( typeof( prime ) == "undefined" ) var prime = "";',
            'if ( typeof( primes ) == "undefined" ) var primes = [];',
            'if ( typeof( something ) == "undefined" ) var something = "";',
            'prime = 3;',
            'primes = [ 3, 5, 7 ];',
            'if ( prime == 3 && primes.indexOf( 7 ) > -1 && something == true ) {',
            'answer = 42;',
            '}',
        ],
    ],
    [
        'if conditional statement otherwise statement',
        'If prime is 3, then set result to true. Otherwise, set result to false.',
        [
            'if ( typeof( prime ) == "undefined" ) var prime = "";',
            'if ( typeof( result ) == "undefined" ) var result = "";',
            'if ( prime == 3 ) {',
            'result = true;',
            '}',
            'else {',
            'result = false;',
            '}',
        ],
    ],
    [
        'if conditional then statement otherwise if conditional then statement',
        'If prime is 3, then set result to true. Otherwise, if prime is not 42, then set result to false.',
        [
            'if ( typeof( prime ) == "undefined" ) var prime = "";',
            'if ( typeof( result ) == "undefined" ) var result = "";',
            'if ( prime == 3 ) {',
            'result = true;',
            '}',
            'else if ( prime != 42 ) {',
            'result = false;',
            '}',
        ],
    ],
);

done_testing;

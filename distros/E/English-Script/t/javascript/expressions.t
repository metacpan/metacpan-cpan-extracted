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
        'say a number',
        'Say 42.',
        'console.log( 42 );',
    ],
    [
        'say a number',
        'Say -42.',
        'console.log( -42 );',
    ],
    [
        'say a string',
        'Say "Hello World".',
        'console.log( "Hello World" );',
    ],
    [
        'say an expression',
        'Say 42 plus 1138 times 13 divided by 12.',
        'console.log( 42 + 1138 * 13 / 12 );',
    ],
    [
        'set simple object',
        'Set prime to 3.',
        [
            'if ( typeof( prime ) == "undefined" ) var prime = "";',
            'prime = 3;'
        ],
    ],
    [
        'set complex object',
        'Set special prime to 3.',
        [
            'if ( typeof( special ) == "undefined" ) var special = {};',
            'if ( typeof( special.prime ) == "undefined" ) special.prime = "";',
            'special.prime = 3;'
        ],
    ],
    [
        'set complex object that starts with number',
        'Set 42 special prime to 3.',
        [
            'if ( typeof( _42 ) == "undefined" ) var _42 = {};',
            'if ( typeof( _42.special ) == "undefined" ) _42.special = {};',
            'if ( typeof( _42.special.prime ) == "undefined" ) _42.special.prime = "";',
            '_42.special.prime = 3;'
        ],
    ],
    [
        'ignore superfluous words',
        'Set the special prime list value string text number list array to 3.',
        [
            'if ( typeof( special ) == "undefined" ) var special = {};',
            'if ( typeof( special.prime ) == "undefined" ) special.prime = "";',
            'special.prime = 3;'
        ],
    ],
    [
        'complex object and complex expression',
        'Set the sum of 27 to the value of 3 plus 5 times 10 divided by 2 minus 1.',
        [
            'if ( typeof( sum ) == "undefined" ) var sum = {};',
            'if ( typeof( sum.of ) == "undefined" ) sum.of = {};',
            'if ( typeof( sum.of.27 ) == "undefined" ) sum.of.27 = "";',
            'sum.of.27 = 3 + 5 * 10 / 2 - 1;'
        ],
    ],
    [
        'set a floating point number with commas',
        'Set the answer to 123,456.78.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = "";',
            'answer = 123456.78;'
        ],
    ],
);

done_testing;

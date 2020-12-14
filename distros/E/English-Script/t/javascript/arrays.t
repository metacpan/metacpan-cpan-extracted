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
        'shift',
        'Set number to a removed item from favorite numbers.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = {};',
            'if ( typeof( favorite.numbers ) == "undefined" ) favorite.numbers = [];',
            'if ( typeof( number ) == "undefined" ) var number = "";',
            'number = favorite.numbers.shift;',
        ],
    ],
    [
        'length',
        'Set string size to the length of strings example.',
        [
            'if ( typeof( string ) == "undefined" ) var string = {};',
            'if ( typeof( string.size ) == "undefined" ) string.size = "";',
            'if ( typeof( strings ) == "undefined" ) var strings = {};',
            'if ( typeof( strings.example ) == "undefined" ) strings.example = "";',
            'string.size = strings.example.length;',
        ],
    ],
    [
        'set a list',
        'Set the answer to 5, 6, 7.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = [];',
            'answer = [ 5, 6, 7 ];',
        ],
    ],
    [
        'set a list (wrongly) without spaces',
        'Set the answer to 5,6,7.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = "";',
            'answer = 567;',
        ],
    ],
    [
        'set a list with an and',
        'Set the answer to 5, 6, and 7.',
        [
            'if ( typeof( answer ) == "undefined" ) var answer = [];',
            'answer = [ 5, 6, 7 ];',
        ],
    ],
    [
        'set variable to item in array',
        'Set number to item 1 of favorite numbers.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = {};',
            'if ( typeof( favorite.numbers ) == "undefined" ) favorite.numbers = "";',
            'if ( typeof( number ) == "undefined" ) var number = "";',
            'number = favorite.numbers[0];',
        ],
    ],
    [
        'set variable to function of item in array',
        'Set number to the length of item 1 of favorite numbers.',
        [
            'if ( typeof( favorite ) == "undefined" ) var favorite = {};',
            'if ( typeof( favorite.numbers ) == "undefined" ) favorite.numbers = "";',
            'if ( typeof( number ) == "undefined" ) var number = "";',
            'number = favorite.numbers[0].length;',
        ],
    ],
);

done_testing;

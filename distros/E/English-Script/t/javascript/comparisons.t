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
        'greather than and length of',
        'If the object is greater than the length of the other object, then say 42.',
        [
            'if ( typeof( object ) == "undefined" ) var object;',
            'if ( typeof( other ) == "undefined" ) var other = {};',
            'if ( typeof( other.object ) == "undefined" ) var other.object;',
            'if ( object > other.object.length ) {',
            'console.log( 42 );',
            '}',
        ],
    ],
    [
        'greater than or equal to',
        'If the thing value is greater than or equal to the stuff value plus 17, then say 43.',
        [
            'if ( typeof( stuff ) == "undefined" ) var stuff;',
            'if ( typeof( thing ) == "undefined" ) var thing;',
            'if ( thing >= stuff + 17 ) {',
            'console.log( 43 );',
            '}',
        ],
    ],
    [
        'greater than',
        'If the thing value is greater than the stuff value, then say 43.',
        [
            'if ( typeof( stuff ) == "undefined" ) var stuff;',
            'if ( typeof( thing ) == "undefined" ) var thing;',
            'if ( thing > stuff ) {',
            'console.log( 43 );',
            '}',
        ],
    ],
    [
        'less than or equal to',
        'If the thing value is less than or equal to 42, then say 42.',
        [
            'if ( typeof( thing ) == "undefined" ) var thing;',
            'if ( thing <= 42 ) {',
            'console.log( 42 );',
            '}',
        ],
    ],
    [
        'less than',
        'If the thing value is less than 42, then say 42.',
        [
            'if ( typeof( thing ) == "undefined" ) var thing;',
            'if ( thing < 42 ) {',
            'console.log( 42 );',
            '}',
        ],
    ],
    [
        'is not in',
        [
            'Set primes to 3, 5, and 7.',
            'If 42 is not in primes, then say 42.',
        ],
        [
            'if ( typeof( primes ) == "undefined" ) var primes = [];',
            'primes = [ 3, 5, 7 ];',
            'if ( primes.indexOf( 42 ) == -1 ) {',
            'console.log( 42 );',
            '}',
        ],
    ],
    [
        'begins with',
        'If phrase begins with "start", then say 42.',
        [
            'if ( typeof( phrase ) == "undefined" ) var phrase;',
            'if ( phrase.indexOf( "start" ) == 0 ) {',
            'console.log( 42 );',
            '}',
        ],
    ],
    [
        'does not begin with',
        'If phrase does not begin with "start", then say 42.',
        [
            'if ( typeof( phrase ) == "undefined" ) var phrase;',
            'if ( phrase.indexOf( "start" ) != 0 ) {',
            'console.log( 42 );',
            '}',
        ],
    ],
);

done_testing;

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
        'single-line comment',
        '(This is a single-line comment.)',
        "// This is a single-line comment.",
    ],
    [
        'multi-line comment',
        [
            '(This is a',
            'multi-line comment.)',
        ],
        [
            '// This is a',
            '// multi-line comment.',
        ],
    ],
    [
        'conditional with block containing a comment',
        [
            'If prime is 3, then apply the following block.',
            'Set answer to 42.',
            '(This is a comment.)',
            'This ends the block.',
        ],
        [
            'if ( typeof( answer ) == "undefined" ) var answer = "";',
            'if ( typeof( prime ) == "undefined" ) var prime = "";',
            'if ( prime == 3 ) {',
            'answer = 42;',
            '// This is a comment.',
            '}',
        ],
    ],
);

done_testing;

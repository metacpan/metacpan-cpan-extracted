use strict;
use warnings;
use Test::Most;

use_ok('English::Script');

my $es;
lives_ok( sub { $es = English::Script->new }, 'new' );
lives_ok( sub { $es->parse('Set answer to 42.') }, 'set object to value' );

is_deeply(
    $es->data,
    {
        content => [ {
            sentence => {
                command => {
                    set => [
                        { object => { components => [ { word => 'answer' } ] } },
                        { expression => [ { object => { components => [ { number => 42 } ] } } ] },
                    ],
                },
            },
        } ],
    },
    'data',
);

is(
    $es->yaml,
    join( "\n",
        '---',
        'content:',
        '- sentence:',
        '    command:',
        '      set:',
        '      - object:',
        '          components:',
        '          - word: answer',
        '      - expression:',
        '        - object:',
        '            components:',
        '            - number: \'42\'',
    ) . "\n",
    'yaml',
);

my @grammar = (
    join( "\n",
        'content :',
        '    ( comment | sentence )(s) /^\Z/',
        '    { +{ $item[0] => $item[1] } }',
        '    | <error>',
    ),
    join( "\n",
        'comment :',
        '    /\([^\(\)]*\)/',
        '    {',
        '        $item[1] =~ /\(([^\)]+)\)/;',
        '        +{ $item[0] => ( $1 || \'\' ) };',
        '    }',
        '    | <error>',
    ),
);

is( $es->grammar( $grammar[0] ), $grammar[0], 'set and retrieve grammar' );
is( $es->append_grammar( $grammar[1] )->grammar, join( "\n", @grammar ), 'append to and retrieve grammar' );

done_testing;

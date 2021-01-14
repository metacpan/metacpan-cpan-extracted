use Test2::V0;
use English::Script;

my $es;
ok( lives { $es = English::Script->new }, 'new' ) or note $@;
ok( lives { $es->parse('Set answer to 42.') }, 'set object to value' ) or note $@;

is(
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

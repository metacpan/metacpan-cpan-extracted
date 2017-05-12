use strict;
use warnings;
use Test::More tests => 5 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('a && b', [
    'op',
    '&&',
    [
        'variable',
        'a'
    ],
    [
        'variable',
        'b'
    ]
]);
expr_eq('a || b', [
    'op',
    '||',
    [
        'variable',
        'a'
    ],
    [
        'variable',
        'b'
    ]
]);
expr_eq('a and b', [
    'op',
    'and',
    [
        'variable',
        'a'
    ],
    [
        'variable',
        'b'
    ]
]);
expr_eq('a or b', [
    'op',
    'or',
    [
        'variable',
        'a'
    ],
    [
        'variable',
        'b'
    ]
]);
expr_eq('a && b || c and d or e', [
    'op',
    'or',
    [
        'op',
        'and',
        [
            'op',
            '||',
            [
                'op',
                '&&',
                [
                    'variable',
                    'a'
                ],
                [
                    'variable',
                    'b'
                ]
            ],
            [
                'variable',
                'c'
            ]
        ],
        [
            'variable',
            'd'
        ]
    ],
    [
        'variable',
        'e'
    ]
]);

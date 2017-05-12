use strict;
use warnings;
use Test::More tests => 4 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('a =~ /b/', [
    'op',
    '=~',
    [
        'variable',
        'a'
    ],
    [
        'regexp',
        '/b/'
    ]
]);

expr_eq('not a =~ /b/', [
    'op',
    'not',
    [
        'op',
        '=~',
        [
            'variable',
            'a'
        ],
        [
            'regexp',
            '/b/'
        ]
    ]
]);

expr_eq('foo() =~ /b/', [
    'op',
    '=~',
    [
        'function',
        [
            'name',
            'foo'
        ]
    ],
    [
        'regexp',
        '/b/'
    ]
]);

expr_eq('foo(a =~ /b/)', [
    'function',
    [
        'name',
        'foo'
    ],
    [
        'op',
        '=~',
        [
            'variable',
            'a'
        ],
        [
            'regexp',
            '/b/'
        ]
    ]
]);

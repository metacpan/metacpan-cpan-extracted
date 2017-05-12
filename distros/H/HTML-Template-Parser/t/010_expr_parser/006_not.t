use strict;
use warnings;
use Test::More tests => 5 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('not 0', [ 'op', 'not', [ 'number', '0', ]]);
expr_eq('not a', [ 'op', 'not', [ 'variable', 'a', ]]);
expr_eq('not 1+2', [ 'op', 'not', [ 'op', '+', [ 'number', '1', ], [ 'number', '2', ], ]]);
expr_eq('not foo()', [
    'op',
    'not',
    [
        'function',
        [
            'name',
            'foo'
        ]
    ]
]);
expr_eq('foo(not 1)', [
    'function',
    [
        'name',
        'foo'
    ],
    [
        'op',
        'not',
        [
            'number',
            1
        ]
    ]
]);

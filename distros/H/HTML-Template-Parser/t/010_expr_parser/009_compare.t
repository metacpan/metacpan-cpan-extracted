use strict;
use warnings;
use Test::More tests => 12 * 2;

use HTML::Template::Parser::ExprParser;

use t::lib::Util;

expr_eq('1>2', [
    'op',
    '>',
    [
        'number',
        1
    ],
    [
        'number',
        2
    ]
]);
expr_eq('2 >=3', [
    'op',
    '>=',
    [
        'number',
        2
    ],
    [
        'number',
        3
    ]
]);
expr_eq('3< 4', [
    'op',
    '<',
    [
        'number',
        3
    ],
    [
        'number',
        4
    ]
]);
expr_eq('4 <=5', [
    'op',
    '<=',
    [
        'number',
        4
    ],
    [
        'number',
        5
    ]
]);
expr_eq('5 != 6', [
    'op',
    '!=',
    [
        'number',
        5
    ],
    [
        'number',
        6
    ]
]);
expr_eq('7 == 8',[
    'op',
    '==',
    [
        'number',
        7
    ],
    [
        'number',
        8
    ]
]);
expr_eq('9 le 10', [
    'op',
    'le',
    [
        'number',
        9
    ],
    [
        'number',
        10
    ]
]);
expr_eq('10 ge 11', [
    'op',
    'ge',
    [
        'number',
        10
    ],
    [
        'number',
        11
    ]
]);
expr_eq('11 eq 12', [
    'op',
    'eq',
    [
        'number',
        11
    ],
    [
        'number',
        12
    ]
]);
expr_eq('12 ne 13', [
    'op',
    'ne',
    [
        'number',
        12
    ],
    [
        'number',
        13
    ]
]);
expr_eq('13 lt 14', [
    'op',
    'lt',
    [
        'number',
        13
    ],
    [
        'number',
        14
    ]
]);
expr_eq('15 gt 16', [
    'op',
    'gt',
    [
        'number',
        15
    ],
    [
        'number',
        16
    ]
]);

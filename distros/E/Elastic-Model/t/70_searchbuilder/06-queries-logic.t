#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_details deep_diag bag);
use Data::Dump qw(pp);
use Test::Exception;
use Elastic::Model::SearchBuilder;

my $a = Elastic::Model::SearchBuilder->new;

test_queries(
    'EMPTY AND|OR|NOT',

    '-and',
    { k => 1, -and => [] },
    { match => { k => 1 } },

    '-or',
    { k => 1, -or => [] },
    { match => { k => 1 } },

    '-not',
    { k => 1, -not => [] },
    { match => { k => 1 } },
);

test_queries(
    'SCALAR',
    '-and scalar',
    { -and => 1 },
    qr/little sense/,

    '-or scalar',
    { -or => 1 },
    qr/little sense/,

    '-not scalar',
    { -not => 1 },
    qr/little sense/
);

test_queries(
    'UNDEF',
    '-and undef',
    { -and => undef },
    qr/undef not supported/,

    '-or undef',
    { -or => undef },
    qr/undef not supported/,

    '-not undef',
    { -not => undef },
    qr/undef not supported/,
);

test_queries(
    'SINGLE AND|OR|NOT',

    '-and1',
    { -and  => [ k => 1 ] },
    { match => { k => 1 } },

    '-or1',
    { -or   => [ k => 1 ] },
    { match => { k => 1 } },

    '-not',
    { -not => [ k => 1 ] },
    { bool => { must_not => [ { match => { k => 1 } } ] } },
);

my %and_or = (
    and => {
        bool => {
            must => bag( { match => { a => 1 } }, { match => { b => 2 } } )
        }
    },
    or => {
        bool => {
            should => [ { match => { a => 1 } }, { match => { b => 2 } } ]
        }
    },
    or_and => {
        bool => {
            must => bag(
                { match => { c => 3 } },
                {   bool => {
                        should => [
                            { match => { a => 1 } },
                            { match => { b => 2 } }
                        ]
                    }
                }
            ),
        }
    },
    and_or => {
        bool => {
            should => [ {
                    bool => {
                        must => bag(
                            { match => { a => 1 } },
                            { match => { b => 2 } }
                        )
                    }
                },
                { match => { c => 3 } }
            ]
        }
    },
    or_or => {
        bool => {
            should => [
                { match => { a => 1 } }, { match => { b => 2 } },
                { match => { c => 3 } }

            ]
        }
    },
);

test_queries(
    'BASIC AND|OR',

    '{and[]}',
    { -and => [ a => 1, b => 2 ] },
    $and_or{and},

    '[and[]]',
    [ -and => [ a => 1, b => 2 ] ],
    $and_or{and},

    '{or[]}',
    { -or => [ a => 1, b => 2 ] },
    $and_or{or},

    '[or[]]',
    [ -or => [ a => 1, b => 2 ] ],
    $and_or{or},

    '{and{}}',
    { -and => { a => 1, b => 2 } },
    $and_or{and},

    '[and{}]',
    [ -and => { a => 1, b => 2 } ],
    $and_or{and},

    '{or{}}',
    { -or => { a => 1, b => 2 } },
    $and_or{or},

    '[or{}]',
    [ -or => { a => 1, b => 2 } ],
    $and_or{or},
);

test_queries(
    'NESTED []{}',

    '{-or[[],kv]}',
    { -or => [ [ a => 1, b => 2 ], c => 3 ] },
    $and_or{or_or},

    '{-and[[],kv]}',
    { -and => [ [ a => 1, b => 2 ], c => 3 ] },
    $and_or{or_and},

    '[-or[[],kv]]',
    [ -or => [ [ a => 1, b => 2 ], c => 3 ] ],
    $and_or{or_or},

    '[-and[[],kv]]',
    [ -and => [ [ a => 1, b => 2 ], c => 3 ] ],
    $and_or{or_and},

    '{-and[-or[],kv]}',
    { -and => [ -or => [ a => 1, b => 2 ], c => 3 ] },
    $and_or{or_and},

    '{-or[-and[],kv]}',
    { -or => [ -and => [ a => 1, b => 2 ], c => 3 ] },
    $and_or{and_or},

    '[-and[-or[],kv]]',
    [ -and => [ -or => [ a => 1, b => 2 ], c => 3 ] ],
    $and_or{or_and},

    '[-or[-and[],kv]]',
    [ -or => [ -and => [ a => 1, b => 2 ], c => 3 ] ],
    $and_or{and_or},
);

test_queries(
    'MULTI OPS',

    'K[-and @V]',
    { k => [ -and => 1, 2, 3 ] },
    {   bool => {
            must => [
                { match => { k => 1 } },
                { match => { k => 2 } },
                { match => { k => 3 } }
            ]
        }
    },

    'K[-and @{kv}]',
    { k => [ -and => { '^' => 1 }, { '^' => 2 }, { '^' => 3 } ] },
    {   bool => {
            must => [
                { match_phrase_prefix => { k => 1 } },
                { match_phrase_prefix => { k => 2 } },
                { match_phrase_prefix => { k => 3 } }
            ]
        }
    },

    'K{=[-and,@v]}',
    { k => { '=' => [ '-and', 1, 2 ] } },
    {   bool => {
            should => [
                { match => { k => '-and' } },
                { match => { k => 1 } },
                { match => { k => 2 } }
            ]
        }
    },

    'K{-or{}}',
    { k => { -or => { '!=' => 1, '=' => 2 } } },
    qr/Unknown query operator/,

    'K=>[-and[],{}]',
    { k => [ -and => [ 1, 2 ], { '^' => 3 } ] },
    {   bool => {
            must => bag(
                { match_phrase_prefix => { k => 3 } },
                {   bool => {
                        should => [
                            { match => { k => 1 } },
                            { match => { k => 2 } }
                        ]
                    }
                }
            )
        }
    },

    '-and[],kv,-or{}',
    { -and => [ a => 1, b => 2 ], x => 9, -or => { c => 3, d => 4 } },
    {   bool => {
            must => bag(
                { match => { a => 1 } },
                { match => { b => 2 } },
                { match => { x => 9 } },
                {   bool => {
                        should => [
                            { match => { c => 3 } },
                            { match => { d => 4 } }
                        ]
                    }
                }
            ),
        }
    },

    '{-and[@kv,k[]],kv,-or{@kv,k[]}}',
    {   -and => [ a => 1, b => 2, k => [ 11, 12 ] ],
        x    => 9,
        -or => { c => 3, d => 4, l => { '=' => [ 21, 22 ] } }
    },
    {   bool => {
            must => bag(
                { match => { a => 1 } },
                { match => { b => 2 } },
                {   bool => {
                        should => [
                            { match => { k => 11 } },
                            { match => { k => 12 } }
                        ]
                    }
                },
                { match => { x => 9 } },
                {   bool => {
                        should => [
                            { match => { c => 3 } },
                            { match => { d => 4 } },
                            { match => { l => 21 } },
                            { match => { l => 22 } },
                        ]
                    }
                },
            ),
        }
    },

    '{-or[@kv,k[]],kv,-and{@kv,k[]}}',
    {   -or => [ a => 1, b => 2, k => [ 11, 12 ] ],
        x   => 9,
        -and => { c => 3, d => 4, l => { '=' => [ 21, 22 ] } }
    },
    {   bool => {
            must => bag(
                { match => { c => 3 } },
                { match => { d => 4 } },
                {   bool => {
                        should => [
                            { match => { l => 21 } },
                            { match => { l => 22 } }
                        ]
                    },
                },
                {   bool => {
                        should => [
                            { match => { a => 1 } },
                            { match => { b => 2 } },
                            { match => { k => 11 } },
                            { match => { k => 12 } },
                        ],
                    },
                },
                { match => { x => 9 } },
            ),
        },
    },

    '[-or[],-or[],kv,-and[],[@kv,-and[],{}',
    [   -or  => [ a => 1, b => 2 ],
        -or  => { c => 3, d => 4 },
        e    => 5,
        -and => [ f => 6, g => 7 ],
        [ h => 8,  i => 9, -and => [ k => 10, l => 11 ] ],
        { m => 12, n => 13 }
    ],
    {   bool => {
            should => [
                { match => { a => 1 } },
                { match => { b => 2 } },
                { match => { c => 3 } },
                { match => { d => 4 } },
                { match => { e => 5 } },
                {   bool => {
                        must => [
                            { match => { f => 6 } },
                            { match => { g => 7 } }
                        ]
                    }
                },
                { match => { h => 8 } },
                { match => { i => 9 } },
                {   bool => {
                        must => [
                            { match => { k => 10 } },
                            { match => { l => 11 } }
                        ]
                    }
                },
                {   bool => {
                        must => [
                            { match => { m => 12 } },
                            { match => { n => 13 } }
                        ]
                    }
                },

            ]
        }
    },

    'K[-and mixed []{} ]',
    {   foo => [
            '-and',
            [ { '^' => 'foo' }, { 'gt' => 'moo' } ],
            { '^' => 'bar', 'lt' => 'baz' },
            [ { '^' => 'alpha' }, { '^' => 'beta' } ],
            [ { '!=' => 'toto', '=' => 'koko' } ],
        ]
    },
    {   bool => {
            must => bag( {
                    bool => {
                        should => [
                            { match_phrase_prefix => { foo => "foo" } },
                            { range => { foo => { gt => "moo" } } },
                        ],
                    },
                },
                { match_phrase_prefix => { foo => "bar" } },
                { range               => { foo => { lt => "baz" } } },
                {   bool => {
                        should => [
                            { match_phrase_prefix => { foo => "alpha" } },
                            { match_phrase_prefix => { foo => "beta" } },
                        ],
                    },
                },
                { match => { foo => "koko" } },
            ),
            must_not => [ { match => { foo => "toto" } } ],
        },
    },

    '[-and[],-or[],k[-and{}{}]',
    [   -and => [ a => 1, b => 2 ],
        -or  => [ c => 3, d => 4 ],
        e => [ -and => { '^' => 'foo' }, { '^' => 'bar' } ],
    ],
    {   bool => {
            should => [ {
                    bool => {
                        must => [
                            { match => { a => 1 } },
                            { match => { b => 2 } }
                        ]
                    }
                },
                { match => { c => 3 } },
                { match => { d => 4 } },
                {   bool => {
                        must => [
                            { match_phrase_prefix => { e => 'foo' } },
                            { match_phrase_prefix => { e => 'bar' } }
                        ]
                    }
                }
            ]
        }
    },

    '[-and[{},{}],-or{}]',
    [ -and => [ { foo => 1 }, { bar => 2 } ], -or => { baz => 3 } ],
    {   bool => {
            should => [ {
                    bool => {
                        must => [
                            { match => { foo => 1 } },
                            { match => { bar => 2 } }
                        ]
                    }
                },
                { match => { baz => 3 } }
            ]
        }
    },

    # -and has only 1 following element, thus all still ORed
    'k[-and[]]',
    { k => [ -and => [ { '=' => 1 }, { '=' => 2 }, { '=' => 3 } ] ] },
    {   bool => {
            should => [
                { match => { k => 1 } },
                { match => { k => 2 } },
                { match => { k => 3 } }
            ]
        }
    }
);

test_queries(
    'NOT',

    'not [k]',
    { -not => ['k'] },
    qr/UNDEF not a supported/,

    'not{k=>v}',
    { -not => { k => 'v' } },
    { bool => { must_not => [ { match => { k => 'v' } } ] } },

    'not{k{=v}}',
    { -not => { k => { '=' => 'v' } } },
    { bool => { must_not => [ { match => { k => 'v' } } ] } },

    'not[k=>v]',
    { -not => [ k => 'v' ] },
    { bool => { must_not => [ { match => { k => 'v' } } ] } },

    'not[k{=v}]',
    { -not => [ k => { '=' => 'v' } ] },
    { bool => { must_not => [ { match => { k => 'v' } } ] } },

    'not{k1=>v,k2=>v}',
    { -not => { k1 => 'v', k2 => 'v' } },
    {   bool => {
            must_not => [ {
                    bool => {
                        must => bag(
                            { match => { k1 => 'v' } },
                            { match => { k2 => 'v' } }
                        )
                    }
                }
            ]
        }
    },

    'not{k{=v,^v}}',
    { -not => { k => { '=' => 'v', '^' => 'v' } } },
    {   bool => {
            must_not => [ {
                    bool => {
                        must => bag(
                            { match               => { k => 'v' } },
                            { match_phrase_prefix => { k => 'v' } }
                        )
                    }
                }
            ]
        }
    },

    'not[k1=>v,k2=>v]',
    { -not => [ k1 => 'v', k2 => 'v' ] },
    {   bool => {
            must_not =>
                [ { match => { k1 => 'v' } }, { match => { k2 => 'v' } } ]
        }
    },

    'not[k{=v,^v}]',
    { -not => [ k => { '=' => 'v', '^' => 'v' } ] },
    {   bool => {
            must_not => [ {
                    bool => {
                        must => bag(
                            { match               => { k => 'v' } },
                            { match_phrase_prefix => { k => 'v' } }
                        )
                    }
                }
            ]
        }
    },

    'not not',
    { -not  => { -not => { k => 'v' } } },
    { match => { k    => 'v' } },

    'not !=',
    { -not  => { k => { '!=' => 'v' } } },
    { match => { k => 'v' } },

    'not [{}{}]',
    { -not => { foo => [ 1, 2 ], bar => [ 1, 2 ], baz => { '!=' => 3 } } },
    {   bool => {
            must_not => [ {
                    bool => {
                        must => bag( {
                                bool => {
                                    should => [
                                        { match => { foo => 1 } },
                                        { match => { foo => 2 } }
                                    ]
                                }
                            },
                            {   bool => {
                                    should => [
                                        { match => { bar => 1 } },
                                        { match => { bar => 2 } }
                                    ]
                                }
                            }
                        ),
                        must_not => [ { match => { baz => 3 } } ],
                    }
                }
            ]
        }
    }
);

done_testing;

#===================================
sub test_queries {
#===================================
    note "\n" . shift();
    while (@_) {
        my $name = shift;
        my $in   = shift;
        my $out  = shift;
        if ( ref $out eq 'Regexp' ) {
            throws_ok { $a->query($in) } $out, $name;
            next;
        }

        my $got = $a->query($in);
        my $expect = { query => $out };
        my ( $ok, $stack ) = cmp_details( $got, $expect );

        if ($ok) {
            pass $name;
            next;
        }

        fail($name);

        note("Got:");
        note( pp($got) );
        note("Expected:");
        note( pp($expect) );

        diag( deep_diag($stack) );

    }
}

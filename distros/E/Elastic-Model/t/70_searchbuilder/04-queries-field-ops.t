#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_details deep_diag bag);
use Data::Dump qw(pp);
use Test::Exception;
use Elastic::Model::SearchBuilder;

my $a = Elastic::Model::SearchBuilder->new;

is( scalar $a->query(),      undef, 'Empty ()' );
is( scalar $a->query(undef), undef, '(undef)' );
is( scalar $a->query( [] ), undef, 'Empty []' );
is( scalar $a->query( {} ), undef, 'Empty {}' );
is( scalar $a->query( [ [], {} ] ), undef, 'Empty [[]{}]' );
is( scalar $a->query( { [], {} } ), undef, 'Empty {[]{}}' );
is( scalar $a->query( { -ids => [] } ), undef, 'IDS=>[]' );

throws_ok { $a->query( 1, 2 ) } qr/Too many params/, '1,2';
throws_ok { $a->query( [undef] ) } qr/UNDEF in arrayref/, '[undef]';

test_queries(
    'SCALAR',

    'V',
    'v',
    { match => { _all => 'v' } },

    '\\V',
    \'v',
    'v',

);

test_queries(
    'KEY-VALUE PAIRS',

    'K: V',
    { k     => 'v' },
    { match => { k => 'v' } },

    'K: UNDEF',
    { k => undef },
    qr/UNDEF not a supported query/,

    'K: \\V',
    { k => \'v' },
    { k => 'v' },

    'K: []',
    { k => [] },
    qr/UNDEF not a supported query/,

    'K: [V]',
    { k     => ['v'] },
    { match => { k => 'v' } },

    'K: [V,V]',
    { k => [ 'v', 'v' ] },
    {   bool => {
            should => [ { match => { k => 'v' } }, { match => { k => 'v' } } ]
        }
    },

    'K: [UNDEF]',
    { k => [undef] },
    qr/UNDEF not a supported query/,

    'K: [V,UNDEF]',
    { k => [ 'v', undef ] },
    qr/UNDEF not a supported query/,

    'K: [-and,V,UNDEF]',
    { k => [ '-and', 'v', undef ] },
    qr/UNDEF not a supported query/,

);

for my $op (qw(= match)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k     => { $op => 'v' } },
        { match => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k     => { $op => ['v'] } },
        { match => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should =>
                    [ { match => { k => 'v' } }, { match => { k => 'v' } } ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query                => 'v',
                    boost                => 1,
                    operator             => 'AND',
                    analyzer             => 'default',
                    fuzzy_rewrite        => 'constant_score_default',
                    fuzziness            => 0.5,
                    lenient              => 1,
                    max_expansions       => 10,
                    minimum_should_match => 2,
                    prefix_length        => 2,
                    rewrite              => 'constant_score_default',
                }
            }
        },
        {   match => {
                k => {
                    analyzer             => 'default',
                    boost                => 1,
                    fuzziness            => '0.5',
                    fuzzy_rewrite        => 'constant_score_default',
                    lenient              => 1,
                    max_expansions       => 10,
                    minimum_should_match => 2,
                    operator             => 'AND',
                    prefix_length        => 2,
                    query                => 'v',
                    rewrite              => 'constant_score_default',
                }
            }
        },
    );
}

for my $op (qw(!= <> not_match)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { bool => { must_not => [ { match => { k => 'v' } } ] } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { bool => { must_not => [ { match => { k => 'v' } } ] } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not =>
                    [ { match => { k => 'v' } }, { match => { k => 'v' } } ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query                => 'v',
                    boost                => 1,
                    operator             => 'AND',
                    analyzer             => 'default',
                    fuzziness            => 0.5,
                    fuzzy_rewrite        => 'constant_score_default',
                    lenient              => 1,
                    max_expansions       => 10,
                    minimum_should_match => 2,
                    prefix_length        => 2,
                    rewrite              => 'constant_score_default',
                }
            }
        },
        {   bool => {
                must_not => [ {
                        match => {
                            k => {
                                analyzer       => 'default',
                                boost          => 1,
                                fuzziness      => '0.5',
                                fuzzy_rewrite  => 'constant_score_default',
                                lenient        => 1,
                                max_expansions => 10,
                                minimum_should_match => 2,
                                operator             => 'AND',
                                prefix_length        => 2,
                                query                => 'v',
                                rewrite => 'constant_score_default',
                            }
                        }
                    }
                ]
            }
        }
    );
}

for my $op (qw(== phrase match_phrase)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k            => { $op => 'v' } },
        { match_phrase => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k            => { $op => ['v'] } },
        { match_phrase => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should => [
                    { match_phrase => { k => 'v' } },
                    { match_phrase => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query    => 'v',
                    boost    => 1,
                    analyzer => 'default',
                    lenient  => 1,
                    slop     => 3,
                }
            }
        },
        {   match_phrase => {
                k => {
                    analyzer => 'default',
                    boost    => 1,
                    query    => 'v',
                    lenient  => 1,
                    slop     => 3,
                }
            }
        },
    );
}

for my $op (qw(not_phrase not_match_phrase)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { bool => { must_not => [ { match_phrase => { k => 'v' } } ] } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { bool => { must_not => [ { match_phrase => { k => 'v' } } ] } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not => [
                    { match_phrase => { k => 'v' } },
                    { match_phrase => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query    => 'v',
                    boost    => 1,
                    analyzer => 'default',
                    lenient  => 1,
                    slop     => 3,
                }
            }
        },
        {   bool => {
                must_not => [ {
                        match_phrase => {
                            k => {
                                analyzer => 'default',
                                boost    => 1,
                                query    => 'v',
                                lenient  => 1,
                                slop     => 3,
                            }
                        }
                    }
                ]
            }
        },
    );
}

for my $op (qw(term terms)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k    => { $op => 'v' } },
        { term => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k    => { $op => ['v'] } },
        { term => { k   => 'v' } },

        "K: $op [V,V]",
        { k     => { $op => [ 'v', 'v' ] } },
        { terms => { k   => [ 'v', 'v' ] } },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        { k => { $op => { value => 1, boost => 1, minimum_match => 1 } } },
        { term => { k => { boost => 1, value => 1 } } },

        'K: $op {[]}',
        {   k => {
                $op => { value => [ 1, 2 ], boost => 1, minimum_match => 1 }
            }
        },
        { terms => { boost => 1, k => [ 1, 2 ], minimum_match => 1 } },

    );
}

for my $op (qw(not_term not_terms)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { bool => { must_not => [ { term => { k => 'v' } } ] } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { bool => { must_not => [ { term => { k => 'v' } } ] } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        { bool => { must_not => [ { terms => { k => [ 'v', 'v' ] } } ] } },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        { k => { $op => { value => 1, boost => 1, minimum_match => 1 } } },
        {   bool => {
                must_not =>
                    [ { term => { k => { boost => 1, value => 1 } } } ]
            }
        },

        'K: $op {[]}',
        {   k => {
                $op => { value => [ 1, 2 ], boost => 1, minimum_match => 1 }
            }
        },
        {   bool => {
                must_not => [ {
                        terms =>
                            { boost => 1, k => [ 1, 2 ], minimum_match => 1 }
                    }
                ]
            }
        },

    );
}

for my $op (qw(^ phrase_prefix match_phrase_prefix)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k                   => { $op => 'v' } },
        { match_phrase_prefix => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k                   => { $op => ['v'] } },
        { match_phrase_prefix => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should => [
                    { match_phrase_prefix => { k => 'v' } },
                    { match_phrase_prefix => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query          => 'v',
                    boost          => 1,
                    analyzer       => 'default',
                    lenient        => 1,
                    slop           => 10,
                    max_expansions => 10
                }
            }
        },
        {   match_phrase_prefix => {
                k => {
                    query          => 'v',
                    boost          => 1,
                    analyzer       => 'default',
                    lenient        => 1,
                    slop           => 10,
                    max_expansions => 10

                }
            }
        }
    );
}

for my $op (qw(not_phrase_prefix not_match_phrase_prefix)) {

    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        {   bool =>
                { must_not => [ { match_phrase_prefix => { k => 'v' } } ] }
        },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        {   bool =>
                { must_not => [ { match_phrase_prefix => { k => 'v' } } ] }
        },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not => [
                    { match_phrase_prefix => { k => 'v' } },
                    { match_phrase_prefix => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query          => 'v',
                    boost          => 1,
                    analyzer       => 'default',
                    lenient        => 1,
                    slop           => 10,
                    max_expansions => 10
                }
            }
        },
        {   bool => {
                must_not => [ {
                        match_phrase_prefix => {
                            k => {
                                query          => 'v',
                                boost          => 1,
                                analyzer       => 'default',
                                lenient        => 1,
                                slop           => 10,
                                max_expansions => 10

                            }
                        }
                    }
                ]
            }
        }

    );
}

for my $op (qw(prefix)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k      => { $op => 'v' } },
        { prefix => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k      => { $op => ['v'] } },
        { prefix => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should => [
                    { prefix => { k => 'v' } }, { prefix => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    value   => 'v',
                    boost   => 1,
                    rewrite => 'constant_score_default',
                }
            }
        },
        {   prefix => {
                k => {
                    value   => 'v',
                    boost   => 1,
                    rewrite => 'constant_score_default',

                }
            }
        },
    );
}

for my $op (qw(not_prefix)) {

    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { bool => { must_not => [ { prefix => { k => 'v' } } ] } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { bool => { must_not => [ { prefix => { k => 'v' } } ] } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not => [
                    { prefix => { k => 'v' } }, { prefix => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    value   => 'v',
                    boost   => 1,
                    rewrite => 'constant_score_default',
                }
            }
        },
        {   bool => {
                must_not => [ {
                        prefix => {
                            k => {
                                value   => 'v',
                                boost   => 1,
                                rewrite => 'constant_score_default',
                            }
                        }
                    }
                ]
            }
        },
    );
}

for my $op (qw(* wildcard)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k        => { $op => 'v' } },
        { wildcard => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k        => { $op => ['v'] } },
        { wildcard => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should => [
                    { wildcard => { k => 'v' } },
                    { wildcard => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    value   => 'v',
                    boost   => 1,
                    rewrite => 'constant_score_default',
                }
            }
        },
        {   wildcard => {
                k => {
                    value   => 'v',
                    boost   => 1,
                    rewrite => 'constant_score_default',
                }
            }
        },
    );
}

for my $op (qw(not_wildcard)) {

    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { bool => { must_not => [ { wildcard => { k => 'v' } } ] } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { bool => { must_not => [ { wildcard => { k => 'v' } } ] } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not => [
                    { wildcard => { k => 'v' } },
                    { wildcard => { k => 'v' } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    value   => 'v',
                    boost   => 1,
                    rewrite => 'constant_score_default',
                }
            }
        },
        {   bool => {
                must_not => [ {
                        wildcard => {
                            k => {
                                value   => 'v',
                                boost   => 1,
                                rewrite => 'constant_score_default',
                            }
                        }
                    }
                ]
            }
        },
    );
}

for my $op (qw(fuzzy)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k     => { $op => 'v' } },
        { fuzzy => { k   => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k     => { $op => ['v'] } },
        { fuzzy => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should =>
                    [ { fuzzy => { k => 'v' } }, { fuzzy => { k => 'v' } } ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    value          => 'v',
                    boost          => 1,
                    min_similarity => 0.5,
                    max_expansions => 10,
                    prefix_length  => 2,
                    rewrite        => 'constant_score_default',
                }
            }
        },
        {   fuzzy => {
                k => {
                    value          => 'v',
                    boost          => 1,
                    min_similarity => 0.5,
                    max_expansions => 10,
                    prefix_length  => 2,
                    rewrite        => 'constant_score_default',
                }
            }
        },
    );
}

for my $op (qw(not_fuzzy)) {

    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { bool => { must_not => [ { fuzzy => { k => 'v' } } ] } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { bool => { must_not => [ { fuzzy => { k => 'v' } } ] } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not =>
                    [ { fuzzy => { k => 'v' } }, { fuzzy => { k => 'v' } } ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    value          => 'v',
                    boost          => 1,
                    min_similarity => 0.5,
                    max_expansions => 10,
                    prefix_length  => 2,
                    rewrite        => 'constant_score_default',
                }
            }
        },
        {   bool => {
                must_not => [ {
                        fuzzy => {
                            k => {
                                value          => 'v',
                                boost          => 1,
                                min_similarity => 0.5,
                                max_expansions => 10,
                                prefix_length  => 2,
                                rewrite        => 'constant_score_default',
                            }
                        }
                    }
                ]
            }
        },
    );
}

my %range_map = (
    '<'  => 'lt',
    '<=' => 'lte',
    '>'  => 'gt',
    '>=' => 'gte'
);

for my $op (qw(< <= >= > gt gte lt lte)) {
    my $type = 'range';
    my $es_op = $range_map{$op} || $op;

    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { $type => { k => { $es_op => 'v' } } },

        "K: $op UNDEF",
        { $type => { $op => undef } },
        qr/SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        qr/SCALAR/,

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        qr/SCALAR/,

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/SCALAR/,

        'K[$op 5],K[$op 10]',
        { k => [ -and => { '>' => 5 }, { '>' => 10 } ] },
        qr/Duplicate/,
    );
}

test_queries(
    "COMBINED RANGE OPERATORS",

    "K: gt gte lt lte V",
    {   k => {
            gt  => 'v',
            gte => 'v',
            lt  => 'v',
            lte => 'v',
        }
    },
    { range => { k => { gt => 'v', gte => 'v', lt => 'v', lte => 'v' } } },

    "K: < <= > >= V",
    {   k => {
            '>'  => 'v',
            '>=' => 'v',
            '<'  => 'v',
            '<=' => 'v'
        }
    },
    { range => { k => { gt => 'v', gte => 'v', lt => 'v', lte => 'v' } } },

    "K: [gt gte lt lte < <= > >=] V",
    {   k => [
            { gt   => 'v' },
            { gte  => 'v' },
            { lt   => 'v' },
            { lte  => 'v' },
            { '>'  => 'V' },
            { '>=' => 'V' },
            { '<'  => 'V' },
            { '<=' => 'V' }
        ]
    },
    {   bool => {
            should => [
                { range => { k => { gt  => "v" } } },
                { range => { k => { gte => "v" } } },
                { range => { k => { lt  => "v" } } },
                { range => { k => { lte => "v" } } },
                { range => { k => { gt  => "V" } } },
                { range => { k => { gte => "V" } } },
                { range => { k => { lt  => "V" } } },
                { range => { k => { lte => "V" } } },
            ],
        }
    },

    "K: range {}",
    {   k => {
            range => {
                from          => 1,
                to            => 2,
                include_lower => 1,
                include_upper => 1,
                gt            => 1,
                gte           => 1,
                lt            => 2,
                lte           => 2,
                boost         => 1
            }
        }
    },
    {   range => {
            k => {
                from          => 1,
                to            => 2,
                include_lower => 1,
                include_upper => 1,
                gt            => 1,
                gte           => 1,
                lt            => 2,
                lte           => 2,
                boost         => 1
            }
        }
    }
);

for my $op (qw(flt)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { flt_field => { k => { like_text => 'v' } } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { flt_field => { k => { like_text => 'v' } } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should => [
                    { flt_field => { k => { like_text => 'v' } } },
                    { flt_field => { k => { like_text => 'v' } } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    like_text      => 'v',
                    boost          => 1,
                    min_similarity => 0.5,
                    ignore_tf      => 1,
                    prefix_length  => 2,
                    analyzer       => 'default',
                }
            }
        },
        {   flt_field => {
                k => {
                    like_text      => 'v',
                    boost          => 1,
                    min_similarity => 0.5,
                    ignore_tf      => 1,
                    prefix_length  => 2,
                    analyzer       => 'default',
                }
            }
        },
    );
}

for my $op (qw(not_flt)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        {   bool => {
                must_not => [ { flt_field => { k => { like_text => 'v' } } } ]
            }
        },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        {   bool => {
                must_not => [ { flt_field => { k => { like_text => 'v' } } } ]
            }
        },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not => [
                    { flt_field => { k => { like_text => 'v' } } },
                    { flt_field => { k => { like_text => 'v' } } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    like_text      => 'v',
                    boost          => 1,
                    min_similarity => 0.5,
                    ignore_tf      => 1,
                    prefix_length  => 2,
                    analyzer       => 'default',
                }
            }
        },
        {   bool => {
                must_not => [ {
                        flt_field => {
                            k => {
                                like_text      => 'v',
                                boost          => 1,
                                min_similarity => 0.5,
                                ignore_tf      => 1,
                                prefix_length  => 2,
                                analyzer       => 'default',
                            }
                        }
                    }
                ]
            }
        },
    );
}

for my $op (qw(mlt)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        { mlt_field => { k => { like_text => 'v' } } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        { mlt_field => { k => { like_text => 'v' } } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should => [
                    { mlt_field => { k => { like_text => 'v' } } },
                    { mlt_field => { k => { like_text => 'v' } } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    like_text              => 'v',
                    boost                  => 1,
                    boost_terms            => 1,
                    max_doc_freq           => 100,
                    max_query_terms        => 100,
                    max_word_len           => 20,
                    min_doc_freq           => 1,
                    min_term_freq          => 1,
                    min_word_len           => 1,
                    percent_terms_to_match => 0.3,
                    stop_words             => [ 'foo', 'bar' ],
                    analyzer               => 'default',
                }
            }
        },
        {   mlt_field => {
                k => {

                    like_text              => 'v',
                    boost                  => 1,
                    boost_terms            => 1,
                    max_doc_freq           => 100,
                    max_query_terms        => 100,
                    max_word_len           => 20,
                    min_doc_freq           => 1,
                    min_term_freq          => 1,
                    min_word_len           => 1,
                    percent_terms_to_match => 0.3,
                    stop_words             => [ 'foo', 'bar' ],
                    analyzer               => 'default',
                }
            }
        },
    );
}

for my $op (qw(not_mlt)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k => { $op => 'v' } },
        {   bool => {
                must_not => [ { mlt_field => { k => { like_text => 'v' } } } ]
            }
        },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k => { $op => ['v'] } },
        {   bool => {
                must_not => [ { mlt_field => { k => { like_text => 'v' } } } ]
            }
        },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not => [
                    { mlt_field => { k => { like_text => 'v' } } },
                    { mlt_field => { k => { like_text => 'v' } } }
                ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    like_text              => 'v',
                    boost                  => 1,
                    boost_terms            => 1,
                    max_doc_freq           => 100,
                    max_query_terms        => 100,
                    max_word_len           => 20,
                    min_doc_freq           => 1,
                    min_term_freq          => 1,
                    min_word_len           => 1,
                    percent_terms_to_match => 0.3,
                    stop_words             => [ 'foo', 'bar' ],
                    analyzer               => 'default',
                }
            }
        },
        {   bool => {
                must_not => [ {
                        mlt_field => {
                            k => {
                                like_text              => 'v',
                                boost                  => 1,
                                boost_terms            => 1,
                                max_doc_freq           => 100,
                                max_query_terms        => 100,
                                max_word_len           => 20,
                                min_doc_freq           => 1,
                                min_term_freq          => 1,
                                min_word_len           => 1,
                                percent_terms_to_match => 0.3,
                                stop_words             => [ 'foo', 'bar' ],
                                analyzer               => 'default',
                            }
                        }
                    }
                ]
            }
        },
    );
}

for my $op (qw(query_string qs)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k     => { $op => 'v' } },
        { field => { k   => => 'v' } },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k     => { $op => ['v'] } },
        { field => { k   => 'v' } },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                should =>
                    [ { field => { k => 'v' } }, { field => { k => 'v' } } ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query                        => 'v',
                    default_operator             => 'AND',
                    analyzer                     => 'default',
                    allow_leading_wildcard       => 0,
                    lowercase_expanded_terms     => 1,
                    enable_position_increments   => 1,
                    fuzzy_prefix_length          => 2,
                    fuzzy_min_sim                => 0.5,
                    fuzzy_rewrite                => 'constant_score_default',
                    fuzzy_max_expansions         => 1024,
                    lenient                      => 1,
                    phrase_slop                  => 10,
                    boost                        => 1,
                    analyze_wildcard             => 1,
                    auto_generate_phrase_queries => 0,
                    rewrite                      => 'constant_score_default',
                    minimum_should_match         => 3,
                    quote_analyzer               => 'standard',
                    quote_field_suffix           => '.unstemmed'

                }
            }
        },
        {   field => {
                k => {
                    query                        => 'v',
                    default_operator             => 'AND',
                    analyzer                     => 'default',
                    allow_leading_wildcard       => 0,
                    lowercase_expanded_terms     => 1,
                    enable_position_increments   => 1,
                    fuzzy_prefix_length          => 2,
                    fuzzy_min_sim                => 0.5,
                    fuzzy_rewrite                => 'constant_score_default',
                    fuzzy_max_expansions         => 1024,
                    lenient                      => 1,
                    phrase_slop                  => 10,
                    boost                        => 1,
                    analyze_wildcard             => 1,
                    auto_generate_phrase_queries => 0,
                    rewrite                      => 'constant_score_default',
                    minimum_should_match         => 3,
                    quote_analyzer               => 'standard',
                    quote_field_suffix           => '.unstemmed'
                }
            }
        },
    );
}

for my $op (qw(not_query_string not_qs)) {
    test_queries(
        "FIELD OPERATOR: $op",

        "K: $op V",
        { k    => { $op => 'v' } },
        { bool => {
                must_not => [ { field => { k => 'v' } } ]
            }
        },

        "K: $op UNDEF",
        { k => { $op => undef } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V]",
        { k    => { $op => ['v'] } },
        { bool => {
                must_not => [ { field => { k => 'v' } } ]
            }
        },

        "K: $op [V,V]",
        { k => { $op => [ 'v', 'v' ] } },
        {   bool => {
                must_not =>
                    [ { field => { k => 'v' } }, { field => { k => 'v' } } ]
            }
        },

        "K: $op [UNDEF]",
        { k => { $op => [undef] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        "K: $op [V,UNDEF]",
        { k => { $op => [ 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op [-and,V,UNDEF]',
        { k => { $op => [ '-and', 'v', undef ] } },
        qr/ARRAYREF, HASHREF, SCALAR/,

        'K: $op {}',
        {   k => {
                $op => {
                    query                        => 'v',
                    default_operator             => 'AND',
                    analyzer                     => 'default',
                    allow_leading_wildcard       => 0,
                    lowercase_expanded_terms     => 1,
                    enable_position_increments   => 1,
                    fuzzy_prefix_length          => 2,
                    fuzzy_min_sim                => 0.5,
                    fuzzy_rewrite                => 'constant_score_default',
                    fuzzy_max_expansions         => 1024,
                    lenient                      => 1,
                    phrase_slop                  => 10,
                    boost                        => 1,
                    analyze_wildcard             => 1,
                    auto_generate_phrase_queries => 0,
                    rewrite                      => 'constant_score_default',
                    quote_analyzer               => 'standard',
                    quote_field_suffix           => '.unstemmed'
                }
            }
        },
        {   bool => {
                must_not => [ {
                        field => {
                            k => {
                                query                      => 'v',
                                default_operator           => 'AND',
                                analyzer                   => 'default',
                                allow_leading_wildcard     => 0,
                                lowercase_expanded_terms   => 1,
                                enable_position_increments => 1,
                                fuzzy_prefix_length        => 2,
                                fuzzy_min_sim              => 0.5,
                                fuzzy_rewrite => 'constant_score_default',
                                fuzzy_max_expansions         => 1024,
                                lenient                      => 1,
                                phrase_slop                  => 10,
                                boost                        => 1,
                                analyze_wildcard             => 1,
                                auto_generate_phrase_queries => 0,
                                rewrite        => 'constant_score_default',
                                quote_analyzer => 'standard',
                                quote_field_suffix => '.unstemmed'
                            }
                        }
                    }
                ]
            }
        },
    );
}

done_testing();

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

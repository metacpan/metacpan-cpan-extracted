#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep qw(cmp_details deep_diag);
use Data::Dump qw(pp);
use Test::Exception;
use Elastic::Model::SearchBuilder;

my $a = Elastic::Model::SearchBuilder->new;

test_queries(
    "UNARY OPERATOR: all",

    "all: 0",
    { -all      => 0 },
    { match_all => {} },

    "all: 1",
    { -all      => 1 },
    { match_all => {} },

    "all: []",
    { -all      => [] },
    { match_all => {} },

    "all: {}",
    { -all      => {} },
    { match_all => {} },

    "all: {kv}",
    { -all      => { boost => 1, norms_field => 'foo' } },
    { match_all => { boost => 1, norms_field => 'foo' } }

);

test_queries(
    'UNARY OPERATOR: ids, not_ids',
    'IDS: 1',
    { -ids => 1 },
    { ids => { values => [1] } },

    'IDS: [1]',
    { -ids => [1] },
    { ids => { values => [1] } },

    'IDS: {V:1,T:foo}',
    { -ids => { values => 1,     type   => 'foo' } },
    { ids  => { type   => 'foo', values => [1] } },

    'IDS: {V:[1],T:[foo]}',
    { -ids => { values => [1],     type   => ['foo'], boost => 2 } },
    { ids  => { type   => ['foo'], values => [1],     boost => 2 } },

    'NOT_IDS: 1',
    { -not_ids => 1 },
    { bool => { must_not => [ { ids => { values => [1] } } ] } },

    'NOT_IDS: [1]',
    { -not_ids => [1] },
    { bool => { must_not => [ { ids => { values => [1] } } ] } },

    'NOT_IDS: {V:1,T:foo}',
    { -not_ids => { values => 1, type => 'foo' } },
    {   bool =>
            { must_not => [ { ids => { type => 'foo', values => [1] } } ] }
    },

    'NOT_IDS: {V:[1],T:[foo]}',
    { -not_ids => { values => [1], type => ['foo'], boost => 2 } },
    {   bool => {
            must_not =>
                [ { ids => { type => ['foo'], values => [1], boost => 2 } } ]
        }
    },

);

test_queries(
    'UNARY OPERATOR: flt, not_flt',
    'FLT: V',
    { -flt => 'v' },
    { flt => { like_text => 'v' } },

    'FLT: UNDEF',
    { -flt => undef },
    qr/HASHREF, SCALAR/,

    'FLT: [V]',
    { -flt => ['v'] },
    qr/HASHREF, SCALAR/,

    'FLT: {}',
    {   -flt => {
            like_text       => 'v',
            boost           => 1,
            fields          => [ 'foo', 'bar' ],
            ignore_tf       => 0,
            max_query_terms => 100,
            min_similarity  => 0.5,
            prefix_length   => 2,
            analyzer        => 'default',
        }
    },
    {   flt => {
            like_text       => 'v',
            boost           => 1,
            fields          => [ 'foo', 'bar' ],
            ignore_tf       => 0,
            max_query_terms => 100,
            min_similarity  => 0.5,
            prefix_length   => 2,
            analyzer        => 'default',
        }
    },

    'NOT_FLT: V',
    { -not_flt => 'v' },
    { bool => { must_not => [ { flt => { like_text => 'v' } } ] } },

    'NOT_FLT: UNDEF',
    { -not_flt => undef },
    qr/HASHREF, SCALAR/,

    'NOT_FLT: [V]',
    { -not_flt => ['v'] },
    qr/HASHREF, SCALAR/,

    'NOT_FLT: {}',
    {   -not_flt => {
            like_text       => 'v',
            boost           => 1,
            fields          => [ 'foo', 'bar' ],
            ignore_tf       => 0,
            max_query_terms => 100,
            min_similarity  => 0.5,
            prefix_length   => 2,
            analyzer        => 'default',
        }
    },
    {   bool => {
            must_not => [ {
                    flt => {
                        like_text       => 'v',
                        boost           => 1,
                        fields          => [ 'foo', 'bar' ],
                        ignore_tf       => 0,
                        max_query_terms => 100,
                        min_similarity  => 0.5,
                        prefix_length   => 2,
                        analyzer        => 'default',
                    }
                }
            ]
        }
    },
);

test_queries(
    'UNARY OPERATOR: mlt, not_mlt',
    'MLT: V',
    { -mlt => 'v' },
    { mlt => { like_text => 'v' } },

    'MLT: UNDEF',
    { -mlt => undef },
    qr/HASHREF, SCALAR/,

    'MLT: [V]',
    { -mlt => ['v'] },
    qr/HASHREF, SCALAR/,

    'MLT: {}',
    {   -mlt => {
            like_text              => 'v',
            boost                  => 1,
            boost_terms            => 1,
            fields                 => [ 'foo', 'bar' ],
            max_doc_freq           => 100,
            max_query_terms        => 20,
            max_word_len           => 10,
            min_doc_freq           => 1,
            min_term_freq          => 1,
            min_word_len           => 1,
            percent_terms_to_match => 0.3,
            stop_words             => [ 'foo', 'bar' ],
            analyzer               => 'default',
        }
    },
    {   mlt => {
            like_text              => 'v',
            boost                  => 1,
            boost_terms            => 1,
            fields                 => [ 'foo', 'bar' ],
            max_doc_freq           => 100,
            max_query_terms        => 20,
            max_word_len           => 10,
            min_doc_freq           => 1,
            min_term_freq          => 1,
            min_word_len           => 1,
            percent_terms_to_match => 0.3,
            stop_words             => [ 'foo', 'bar' ],
            analyzer               => 'default',
        }
    },

    'NOT_MLT: V',
    { -not_mlt => 'v' },
    { bool => { must_not => [ { mlt => { like_text => 'v' } } ] } },

    'NOT_MLT: UNDEF',
    { -not_mlt => undef },
    qr/HASHREF, SCALAR/,

    'NOT_MLT: [V]',
    { -not_mlt => ['v'] },
    qr/HASHREF, SCALAR/,

    'NOT_MLT: {}',
    {   -not_mlt => {
            like_text              => 'v',
            boost                  => 1,
            boost_terms            => 1,
            fields                 => [ 'foo', 'bar' ],
            max_doc_freq           => 100,
            max_query_terms        => 20,
            max_word_len           => 10,
            min_doc_freq           => 1,
            min_term_freq          => 1,
            min_word_len           => 1,
            percent_terms_to_match => 0.3,
            stop_words             => [ 'foo', 'bar' ],
            analyzer               => 'default',
        }
    },
    {   bool => {
            must_not => [ {
                    mlt => {

                        like_text              => 'v',
                        boost                  => 1,
                        boost_terms            => 1,
                        fields                 => [ 'foo', 'bar' ],
                        max_doc_freq           => 100,
                        max_query_terms        => 20,
                        max_word_len           => 10,
                        min_doc_freq           => 1,
                        min_term_freq          => 1,
                        min_word_len           => 1,
                        percent_terms_to_match => 0.3,
                        stop_words             => [ 'foo', 'bar' ],
                        analyzer               => 'default',
                    }
                }
            ]
        }
    },
);

test_queries(
    'UNARY OPERATOR: match, not_match',
    'MATCH: V',
    { -match => 'v' },
    qr/HASHREF/,

    'MATCH: UNDEF',
    { -match => undef },
    qr/HASHREF/,

    'MATCH: [V]',
    { -match => ['v'] },
    qr/HASHREF/,

    'MATCH: {}',
    {   -match => {
            query                => "foo bar",
            fields               => [ 'title', 'content' ],
            use_dis_max          => 1,
            tie_breaker          => 0.7,
            boost                => 2,
            operator             => 'and',
            analyzer             => 'standard',
            fuzziness            => 0.5,
            fuzzy_rewrite        => 'constant_score_default',
            rewrite              => 'constant_score_default',
            max_expansions       => 1024,
            minimum_should_match => 2,
            prefix_length        => 2,
            lenient              => 1,
            slop                 => 10,
            type                 => 'boolean'
        }
    },
    {   multi_match => {
            query                => "foo bar",
            fields               => [ 'title', 'content' ],
            use_dis_max          => 1,
            tie_breaker          => 0.7,
            boost                => 2,
            operator             => 'and',
            analyzer             => 'standard',
            fuzziness            => 0.5,
            fuzzy_rewrite        => 'constant_score_default',
            rewrite              => 'constant_score_default',
            max_expansions       => 1024,
            minimum_should_match => 2,
            prefix_length        => 2,
            lenient              => 1,
            slop                 => 10,
            type                 => 'boolean'
        }
    },

    'NOT_MATCH: V',
    { -not_match => 'v' },
    qr/HASHREF/,

    'NOT_MATCH: UNDEF',
    { -not_match => undef },
    qr/HASHREF/,

    'NOT_MATCH: [V]',
    { -not_match => ['v'] },
    qr/HASHREF/,

    'NOT_MATCH: {}',
    {   -not_match => {
            query                => "foo bar",
            fields               => [ 'title', 'content' ],
            use_dis_max          => 1,
            tie_breaker          => 0.7,
            boost                => 2,
            operator             => 'and',
            analyzer             => 'standard',
            fuzziness            => 0.5,
            fuzzy_rewrite        => 'constant_score_default',
            rewrite              => 'constant_score_default',
            max_expansions       => 1024,
            minimum_should_match => 2,
            prefix_length        => 2,
            lenient              => 1,
            slop                 => 10,
            type                 => 'boolean'
        }
    },
    {   bool => {
            must_not => [ {
                    multi_match => {
                        query                => "foo bar",
                        fields               => [ 'title', 'content' ],
                        use_dis_max          => 1,
                        tie_breaker          => 0.7,
                        boost                => 2,
                        operator             => 'and',
                        analyzer             => 'standard',
                        fuzziness            => 0.5,
                        fuzzy_rewrite        => 'constant_score_default',
                        rewrite              => 'constant_score_default',
                        max_expansions       => 1024,
                        minimum_should_match => 2,
                        prefix_length        => 2,
                        lenient              => 1,
                        slop                 => 10,
                        type                 => 'boolean'
                    }
                }
            ]
        }
    },
);

for my $op (qw(-qs -query_string)) {
    test_queries(
        "UNARY OPERATOR: $op",

        "$op: V",
        { $op => 'v' },
        { query_string => { query => 'v' } },

        "$op: UNDEF",
        { $op => undef },
        qr/HASHREF, SCALAR/,

        "$op: [V]",
        { $op => ['v'] },
        qr/HASHREF, SCALAR/,

        "$op: {}",
        {   $op => {
                query                        => 'v',
                allow_leading_wildcard       => 0,
                analyzer                     => 'default',
                analyze_wildcard             => 1,
                auto_generate_phrase_queries => 0,
                boost                        => 1,
                default_operator             => 'AND',
                enable_position_increments   => 1,
                fields                       => [ 'foo', 'bar' ],
                fuzzy_min_sim                => 0.5,
                fuzzy_prefix_length          => 2,
                fuzzy_rewrite                => 'constant_score_default',
                fuzzy_max_expansions         => 1024,
                lenient                      => 1,
                lowercase_expanded_terms     => 1,
                minimum_should_match         => 3,
                phrase_slop                  => 10,
                tie_breaker                  => 1.5,
                use_dis_max                  => 1,
                quote_analyzer               => 'standard',
                quote_field_suffix           => '.unstemmed'
            }
        },
        {   query_string => {
                query                        => 'v',
                allow_leading_wildcard       => 0,
                analyzer                     => 'default',
                analyze_wildcard             => 1,
                auto_generate_phrase_queries => 0,
                boost                        => 1,
                default_operator             => 'AND',
                enable_position_increments   => 1,
                fields                       => [ 'foo', 'bar' ],
                fuzzy_min_sim                => 0.5,
                fuzzy_prefix_length          => 2,
                fuzzy_rewrite                => 'constant_score_default',
                lenient                      => 1,
                fuzzy_max_expansions         => 1024,
                lowercase_expanded_terms     => 1,
                minimum_should_match         => 3,
                phrase_slop                  => 10,
                tie_breaker                  => 1.5,
                use_dis_max                  => 1,
                quote_analyzer               => 'standard',
                quote_field_suffix           => '.unstemmed'
            }
        },
    );
}

for my $op (qw(-not_qs -not_query_string)) {
    test_queries(
        "UNARY OPERATOR: $op",

        "$op: V",
        { $op => 'v' },
        { bool => { must_not => [ { query_string => { query => 'v' } } ] } },

        "$op: UNDEF",
        { $op => undef },
        qr/HASHREF, SCALAR/,

        "$op: [V]",
        { $op => ['v'] },
        qr/HASHREF, SCALAR/,

        "$op: {}",
        {   $op => {
                query                        => 'v',
                allow_leading_wildcard       => 0,
                analyzer                     => 'default',
                analyze_wildcard             => 1,
                auto_generate_phrase_queries => 0,
                boost                        => 1,
                default_operator             => 'AND',
                enable_position_increments   => 1,
                fields                       => [ 'foo', 'bar' ],
                fuzzy_min_sim                => 0.5,
                fuzzy_prefix_length          => 2,
                fuzzy_rewrite                => 'constant_score_default',
                fuzzy_max_expansions         => 1024,
                lenient                      => 1,
                lowercase_expanded_terms     => 1,
                minimum_should_match         => 3,
                phrase_slop                  => 10,
                tie_breaker                  => 1.5,
                use_dis_max                  => 1,
                quote_analyzer               => 'standard',
                quote_field_suffix           => '.unstemmed'
            }
        },
        {   bool => {
                must_not => [ {
                        query_string => {
                            query                        => 'v',
                            allow_leading_wildcard       => 0,
                            analyzer                     => 'default',
                            analyze_wildcard             => 1,
                            auto_generate_phrase_queries => 0,
                            boost                        => 1,
                            default_operator             => 'AND',
                            enable_position_increments   => 1,
                            fields                       => [ 'foo', 'bar' ],
                            fuzzy_min_sim                => 0.5,
                            fuzzy_prefix_length          => 2,
                            fuzzy_rewrite        => 'constant_score_default',
                            fuzzy_max_expansions => 1024,
                            lenient              => 1,
                            lowercase_expanded_terms => 1,
                            minimum_should_match     => 3,
                            phrase_slop              => 10,
                            tie_breaker              => 1.5,
                            use_dis_max              => 1,
                            quote_analyzer           => 'standard',
                            quote_field_suffix       => '.unstemmed'
                        }
                    }
                ]
            }
        },
    );
}

test_queries(
    'UNARY OPERATOR: -bool',

    'bool: V',
    { -bool => 'v' },
    qr/HASHREF/,

    'bool: {}',
    {   -bool => {
            must                        => { k => 'v' },
            must_not                    => { k => 'v' },
            should                      => { k => 'v' },
            minimum_number_should_match => 1,
            disable_coord               => 1,
            boost                       => 2,
        }
    },
    {   bool => {
            must                        => [ { match => { k => 'v' } } ],
            must_not                    => [ { match => { k => 'v' } } ],
            should                      => [ { match => { k => 'v' } } ],
            minimum_number_should_match => 1,
            disable_coord               => 1,
            boost                       => 2,
        }
    },

    'bool: {[]}',
    {   -bool => {
            must     => [ { k => 'v' }, { k => 'v' } ],
            must_not => [ { k => 'v' }, { k => 'v' } ],
            should   => [ { k => 'v' }, { k => 'v' } ]
        }
    },
    {   bool => {
            must => [ { match => { k => 'v' } }, { match => { k => 'v' } } ],
            must_not =>
                [ { match => { k => 'v' } }, { match => { k => 'v' } } ],
            should => [ { match => { k => 'v' } }, { match => { k => 'v' } } ]
        }
    },

    'bool: {[empty]}',
    { -bool => { must => [], must_not => undef, should => 'foo' } },
    { bool => { should => [ { match => { _all => 'foo' } } ] } },

    'not_bool: {}',
    {   -not_bool => {
            must     => [ { k => 'v' }, { k => 'v' } ],
            must_not => [ { k => 'v' }, { k => 'v' } ],
            should   => [ { k => 'v' }, { k => 'v' } ]
        }
    },
    {   bool => {
            must_not => [ {
                    bool => {
                        must => [
                            { match => { k => 'v' } },
                            { match => { k => 'v' } }
                        ],
                        must_not => [
                            { match => { k => 'v' } },
                            { match => { k => 'v' } }
                        ],
                        should => [
                            { match => { k => 'v' } },
                            { match => { k => 'v' } }
                        ]
                    }
                }
            ]
        }
    },
);

test_queries(
    'UNARY OPERATOR: -boosting',

    'boosting: v',
    { -boosting => 'v' },
    qr/HASHREF/,

    'boosting: {}',
    {   -boosting => {
            positive       => { k => 'v' },
            negative       => { k => 'v' },
            negative_boost => 1
        }
    },
    {   boosting => {
            positive       => { match => { k => 'v' } },
            negative       => { match => { k => 'v' } },
            negative_boost => 1
        }
    },

    'boosting: {[]}',
    {   -boosting => {
            positive       => [ { k => 'v' }, { k => 'v' } ],
            negative       => [ { k => 'v' }, { k => 'v' } ],
            negative_boost => 1
        }
    },
    {   boosting => {
            positive => {
                bool => {
                    should => [
                        { match => { k => 'v' } },
                        { match => { k => 'v' } }
                    ]
                }
            },
            negative => {
                bool => {
                    should => [
                        { match => { k => 'v' } },
                        { match => { k => 'v' } }
                    ]
                }
            },
            negative_boost => 1
        }
    },

    'not_boosting: {[]}',
    {   -not_boosting => {
            positive       => [ { k => 'v' }, { k => 'v' } ],
            negative       => [ { k => 'v' }, { k => 'v' } ],
            negative_boost => 1
        }
    },
    {   bool => {
            must_not => [ {
                    boosting => {
                        positive => {
                            bool => {
                                should => [
                                    { match => { k => 'v' } },
                                    { match => { k => 'v' } }
                                ]
                            }
                        },
                        negative => {
                            bool => {
                                should => [
                                    { match => { k => 'v' } },
                                    { match => { k => 'v' } }
                                ]
                            }
                        },
                        negative_boost => 1
                    }
                },
            ]
        }
    }

);

test_queries(
    'UNARY OPERATOR: -custom_boost',

    'custom_boost: V',
    { -custom_boost => 'v' },
    qr/HASHREF/,

    'custom_boost: {}',
    {   -custom_boost => {
            query        => { k => 'v' },
            boost_factor => 3
        }
    },
    {   custom_boost_factor => {
            query        => { match => { k => 'v' } },
            boost_factor => 3
        }
    },
);

for my $op (qw(-dis_max -dismax)) {
    test_queries(
        "UNARY OPERATOR: $op",

        "$op: V",
        { $op => 'v' },
        qr/ARRAYREF, HASHREF/,

        "$op: []",
        { $op => [ { k => 'v' }, { k => 'v' } ] },
        {   dis_max => {
                queries =>
                    [ { match => { k => 'v' } }, { match => { k => 'v' } } ]
            }
        },

        "$op: {}",
        {   $op => {
                queries     => [ { k => 'v' }, { k => 'v' } ],
                tie_breaker => 1,
                boost       => 2
            }
        },
        {   dis_max => {
                queries =>
                    [ { match => { k => 'v' } }, { match => { k => 'v' } } ],
                tie_breaker => 1,
                boost       => 2
            }
        },

    );
}

test_queries(
    "UNARY OPERATOR: -custom_score",
    "-custom_score: V",
    { -custom_score => 'V' },
    qr/HASHREF/,

    "-custom_score: {}",
    {   -custom_score => {
            query  => { k   => 'v' },
            script => 'script',
            lang   => 'lang',
            params => { foo => 'bar' }
        }
    },
    {   custom_score => {
            query  => { match => { k => 'v' } },
            script => 'script',
            lang   => 'lang',
            params => { foo => 'bar' }
        }
    },

    "-not_custom_score: {}",
    {   -not_custom_score => {
            query  => { k   => 'v' },
            script => 'script',
            lang   => 'lang',
            params => { foo => 'bar' }
        }
    },
    {   bool => {
            must_not => [ {
                    custom_score => {
                        query  => { match => { k => 'v' } },
                        script => 'script',
                        lang   => 'lang',
                        params => { foo => 'bar' }
                    }
                }
            ]
        }
    },
);

test_queries(
    'UNARY OPERATOR: -custom_filters_score',

    "-custom_filters_score: {filters:{}}",
    {   -custom_filters_score => {
            query   => { k      => 'v' },
            filters => { filter => { k => 'v' }, boost => 2 },
            score_mode => 'first',
            max_boost  => 10
        }
    },
    {   custom_filters_score => {
            query => { match => { k => 'v' } },
            filters => [ { filter => { term => { k => 'v' } }, boost => 2 } ],
            score_mode => 'first',
            max_boost  => 10
        }
    },

    "-custom_filters_score: {filters:[]}",
    {   -custom_filters_score => {
            query   => { k => 'v' },
            filters => [
                { filter => { k => 'v' }, boost => 2 },
                {   filter => { k   => 'v' },
                    script => 'script',
                    lang   => 'mvel',
                    params => { foo => 1 }
                }
            ],
            score_mode => 'first',
            max_boost  => 10
        }
    },
    {   custom_filters_score => {
            query   => { match => { k => 'v' } },
            filters => [
                { filter => { term => { k => 'v' } }, boost => 2 },
                {   filter => { term => { k => 'v' } },
                    script => 'script',
                    lang   => 'mvel',
                    params => { foo => 1 }
                }
            ],
            score_mode => 'first',
            max_boost  => 10
        }
    },
);

test_queries(
    'UNARY OPERATOR: has_parent, not_has_parent',

    'HAS_PARENT: V',
    { -has_parent => 'V' },
    qr/HASHREF/,

    'HAS_PARENT: %V',
    {   -has_parent => {
            query  => { foo => 'bar' },
            type   => 'foo',
            _scope => 'scope',
            boost  => 1
        }
    },
    {   has_parent => {
            query  => { match => { foo => 'bar' } },
            _scope => 'scope',
            type   => 'foo',
            boost  => 1
        }
    },

    'NOT_HAS_PARENT: %V',
    {   -not_has_parent => {
            query  => { foo => 'bar' },
            type   => 'foo',
            _scope => 'scope',
            boost  => 1
        }
    },
    {   bool => {
            must_not => [ {
                    has_parent => {
                        query  => { match => { foo => 'bar' } },
                        _scope => 'scope',
                        boost  => 1,
                        type   => 'foo'
                    }
                }
            ]
        }
    },

);

test_queries(
    'UNARY OPERATOR: has_child, not_has_child',

    'HAS_CHILD: V',
    { -has_child => 'V' },
    qr/HASHREF/,

    'HAS_CHILD: %V',
    {   -has_child => {
            query  => { foo => 'bar' },
            type   => 'foo',
            _scope => 'scope',
            boost  => 1
        }
    },
    {   has_child => {
            query  => { match => { foo => 'bar' } },
            _scope => 'scope',
            type   => 'foo',
            boost  => 1
        }
    },

    'NOT_HAS_CHILD: %V',
    {   -not_has_child => {
            query  => { foo => 'bar' },
            type   => 'foo',
            _scope => 'scope',
            boost  => 1
        }
    },
    {   bool => {
            must_not => [ {
                    has_child => {
                        query  => { match => { foo => 'bar' } },
                        _scope => 'scope',
                        boost  => 1,
                        type   => 'foo'
                    }
                }
            ]
        }
    },

);

test_queries(
    'UNARY OPERATOR: -top_children, -not_top_children',

    '-top_children: V',
    { -top_children => 'V' },
    qr/HASHREF/,

    '-top_children: %V',
    {   -top_children => {
            query              => { foo => 'bar' },
            type               => 'foo',
            _scope             => 'scope',
            score              => 'max',
            factor             => 10,
            incremental_factor => 2
        }
    },
    {   top_children => {
            query              => { match => { foo => 'bar' } },
            _scope             => 'scope',
            type               => 'foo',
            score              => 'max',
            factor             => 10,
            incremental_factor => 2
        }
    },

    '-not_top_children: %V',
    {   -not_top_children => {
            query              => { foo => 'bar' },
            type               => 'foo',
            _scope             => 'scope',
            score              => 'max',
            factor             => 10,
            incremental_factor => 2
        }
    },
    {   bool => {
            must_not => [ {
                    top_children => {
                        query  => { match => { foo => 'bar' } },
                        _scope => 'scope',
                        type   => 'foo',
                        ,
                        score              => 'max',
                        factor             => 10,
                        incremental_factor => 2
                    }
                },
            ]
        }
    },

);

test_queries(
    'UNARY OPERATOR: -filter -not_filter',
    'FILTER: {}',
    { -filter => { k => 'v' } },
    { constant_score => { filter => { term => { k => 'v' } } } },

    'NOT_FILTER: {}',
    { -not_filter => { k => 'v' } },
    {   constant_score =>
            { filter => { not => { filter => { term => { k => 'v' } } } } }
    },

    'QUERY/FILTER',
    { k => 'v', -filter => { k => 'v' } },
    {   filtered => {
            query  => { match => { k => 'v' } },
            filter => { term  => { k => 'v' } }
        }
    },
);

test_queries(
    'UNARY OPERATOR: -indices',

    '-indices: V',
    { -indices => 'V' },
    qr/HASHREF/,

    '-indices: {}',
    { -indices => { indices => 'foo', query => { foo => 1 } } },
    { indices => { indices => ['foo'], query => { match => { foo => 1 } } } },

    '-indices: {""}',
    {   -indices =>
            { indices => 'foo', query => { foo => 1 }, no_match_query => '' }
    },
    { indices => { indices => ['foo'], query => { match => { foo => 1 } } } },

    '-indices: {none}',
    {   -indices => {
            indices        => 'foo',
            query          => { foo => 1 },
            no_match_query => 'none'
        }
    },
    {   indices => {
            indices        => ['foo'],
            query          => { match => { foo => 1 } },
            no_match_query => 'none'
        }
    },

    '-indices: {all}',
    {   -indices => {
            indices        => 'foo',
            query          => { foo => 1 },
            no_match_query => 'all'
        }
    },
    {   indices => {
            indices        => ['foo'],
            query          => { match => { foo => 1 } },
            no_match_query => 'all'
        }
    },

    '-indices: {query}',
    {   -indices => {
            indices        => 'foo',
            query          => { foo => 1 },
            no_match_query => { foo => 2 }
        }
    },
    {   indices => {
            indices        => ['foo'],
            query          => { match => { foo => 1 } },
            no_match_query => { match => { foo => 2 } }
        }
    },
);

test_queries(
    'UNARY OPERATOR: -nested -not_nested',

    '-nested: V',
    { -nested => 'V' },
    qr/HASHREF/,

    '-nested: %V',
    {   -nested => {
            path       => 'foo',
            query      => { foo => 'bar' },
            score_mode => 'avg',
            _scope     => 'scope'
        }
    },
    {   nested => {
            path       => 'foo',
            query      => { match => { foo => 'bar' } },
            score_mode => 'avg',
            _scope     => 'scope'
        }
    },

    '-not_nested: %V',
    {   -not_nested => {
            path       => 'foo',
            query      => { foo => 'bar' },
            score_mode => 'avg',
            _scope     => 'scope'
        }
    },
    {   bool => {
            must_not => [ {
                    nested => {
                        path       => 'foo',
                        query      => { match => { foo => 'bar' } },
                        score_mode => 'avg',
                        _scope     => 'scope'
                    }
                }
            ]
        }
    },

);

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

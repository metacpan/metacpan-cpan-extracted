#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Exception;
use Test::Deep;
use utf8;

use lib 't/lib';

BEGIN {
    use_ok 'IndexConfig' || print 'Bail out';
}

my $model = new_ok 'IndexConfig';

isa_ok my $good = $model->namespace('good')->index, 'Elastic::Model::Index';
isa_ok my $bad  = $model->namespace('bad')->index,  'Elastic::Model::Index';

cmp_deeply $good->index_config(
    settings => { number_of_shards => 1 },
    types    => ['all_opts']
    ),
    {
    index    => "good",
    mappings => {
        all_opts => {
            _all       => { enabled => 0 },
            _timestamp => { enabled => 1, path => "timestamp" },
            dynamic           => "strict",
            numeric_detection => 1,
            properties        => {
                string => {
                    index_analyzer        => "custom",
                    search_analyzer       => "standard",
                    search_quote_analyzer => 'quoted',
                    type                  => "string",
                },
                timestamp => { type => "date" },
            },
        },
    },
    settings => {
        number_of_shards => 1,
        analysis         => {
            analyzer => {
                custom => {
                    char_filter => "map_ss",
                    filter      => [ "truncate_20", "lowercase" ],
                    tokenizer   => "edge_ngrams",
                },
                quoted => { tokenizer => "whitespace", },
            },
            char_filter => {
                map_ss => { mappings => [ "ß", "ss" ], type => "mapping" }
            },
            filter => { truncate_20 => { length => 20, type => "truncate" } },
            tokenizer => {
                edge_ngrams =>
                    { max_gram => 10, min_gram => 1, type => "edge_ngram" },
            },
        },
    },
    },
    'All options';

cmp_deeply $good->index_config( types => ['no_analyzer'] ),
    {
    index    => "good",
    mappings => {
        no_analyzer => {
            _all       => { enabled => 0 },
            _timestamp => { enabled => 1, path => "timestamp" },
            dynamic           => "strict",
            numeric_detection => 1,
            properties        => {
                string    => { type => "string", },
                timestamp => { type => "date" },
            },
        },
    },
    settings => {},
    },
    'No analyzer';

cmp_deeply $good->index_config(),
    {
    index    => "good",
    mappings => {
        all_opts => {
            _all       => { enabled => 0 },
            _timestamp => { enabled => 1, path => "timestamp" },
            dynamic           => "strict",
            numeric_detection => 1,
            properties        => {
                string => {
                    index_analyzer        => "custom",
                    search_analyzer       => "standard",
                    search_quote_analyzer => 'quoted',
                    type                  => "string",
                },
                timestamp => { type => "date" },
            }
        },
        no_analyzer => {
            _all       => { enabled => 0 },
            _timestamp => { enabled => 1, path => "timestamp" },
            dynamic           => "strict",
            numeric_detection => 1,
            properties        => {
                string    => { type => "string" },
                timestamp => { type => "date" }
            }
        },
    },
    settings => {
        analysis => {
            analyzer => {
                custom => {
                    char_filter => "map_ss",
                    filter      => [ "truncate_20", "lowercase" ],
                    tokenizer   => "edge_ngrams",
                },
                quoted => { tokenizer => "whitespace", },
            },
            char_filter => {
                map_ss => { mappings => [ "ß", "ss" ], type => "mapping" }
            },
            filter => { truncate_20 => { length => 20, type => "truncate" } },
            tokenizer => {
                edge_ngrams =>
                    { max_gram => 10, min_gram => 1, type => "edge_ngram" },
            },
        },
    },
    },
    'All good';

throws_ok sub { cmp_deeply $bad->index_config( types => ['bad_analyzer'] ) },
    qr/Unknown analyzer \(not_defined\)/, 'Bad analyzer';

throws_ok sub { cmp_deeply $bad->index_config( types => ['bad_tokenizer'] ) },
    qr/Unknown tokenizer \(foo\)/, 'Bad tokenizer';

done_testing;

1;

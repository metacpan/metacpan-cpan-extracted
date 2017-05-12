#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::String';

our @mapping = (
    'basic' => { type => 'string' },

    'options' => {
        type                  => 'string',
        index                 => 'not_analyzed',
        index_name            => 'foo',
        store                 => 'yes',
        term_vector           => 'with_positions_offsets',
        boost                 => 2,
        null_value            => 'nothing',
        index_analyzer        => 'my_index_analyzer',
        search_analyzer       => 'my_search_analyzer',
        search_quote_analyzer => 'my_quoted_analyzer',
        include_in_all        => 0
    },

    index_analyzer => {
        type           => 'string',
        index_analyzer => 'my_index_analyzer',
        analyzer       => 'my_analyzer'
    },

    search_analyzer => {
        type            => 'string',
        search_analyzer => 'my_search_analyzer',
        analyzer        => 'my_analyzer'
    },

    multi => {
        type   => "multi_field",
        fields => {
            multi_attr => {
                analyzer       => "foo",
                boost          => 2,
                index_analyzer => "bar",
                type           => "string"
            },
            one => {
                boost           => 1,
                index_analyzer  => "bar",
                search_analyzer => "baz",
                type            => "string",
            },
            two => {
                precision_step => 2,
                type           => "date"
            },
        },
    },

    mapping => { type => 'integer', store => 1 },
    bad_opt   => qr/doesn't understand 'precision_step'/,
    bad_multi => qr/doesn't understand 'format'/

);

do 't/10_typemaps/test_field.pl' or die $!;

1;

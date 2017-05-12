#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::Number';

our @mapping = (
    'basic' => { type => 'long' },

    'options' => {
        boost          => 2,
        include_in_all => 0,
        index          => "no",
        index_name     => "foo",
        null_value     => "nothing",
        precision_step => 2,
        store          => "yes",
        type           => "integer",
    },

    multi => {
        type   => "multi_field",
        fields => {
            multi_attr => { boost          => 2, type => "float" },
            one        => { precision_step => 4, type => "float" },
        },
    },

    bad_opt   => qr/doesn't understand 'analyzer'/,
    bad_multi => qr/doesn't understand 'analyzer'/

);

do 't/10_typemaps/test_field.pl' or die $!;

1;

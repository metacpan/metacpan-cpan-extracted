#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::Boolean';

our @mapping = (
    'basic' => { type => 'boolean', null_value => 0 },

    'options' => {
        boost          => 2,
        include_in_all => 0,
        index          => "no",
        index_name     => "foo",
        null_value     => "nothing",
        store          => "yes",
        type           => "boolean",
    },

    multi => {
        type   => "multi_field",
        fields => {
            multi_attr => { boost => 2, type => "boolean", null_value => 0 },
            one => { type => "string" },
        },
    },

    bad_opt   => qr/doesn't understand 'analyzer'/,
    bad_multi => qr/doesn't understand 'analyzer'/

);

do 't/10_typemaps/test_field.pl' or die $!;

1;

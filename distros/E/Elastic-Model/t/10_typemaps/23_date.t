#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::Date';

our @mapping = (
    'basic' => { type => 'date' },

    'options' => {
        boost          => 2,
        include_in_all => 0,
        index          => "no",
        index_name     => "foo",
        null_value     => "nothing",
        precision_step => 2,
        store          => "yes",
        type           => "date",
    },

    multi => {
        type   => "multi_field",
        fields => {
            multi_attr => { boost          => 2, type => "date" },
            one        => { precision_step => 2, type => "date" },
        },
    },

    bad_opt   => qr/doesn't understand 'analyzer'/,
    bad_multi => qr/doesn't understand 'analyzer'/

);

do 't/10_typemaps/test_field.pl' or die $!;

1;

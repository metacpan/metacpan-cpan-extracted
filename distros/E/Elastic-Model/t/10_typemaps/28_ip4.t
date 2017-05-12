#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::IP4';

our @mapping = (
    'basic' => { type => 'ip' },

    'options' => {
        boost          => 3,
        include_in_all => 1,
        index          => "no",
        index_name     => "foo",
        null_value     => "nothing",
        precision_step => 2,
        store          => "yes",
        type           => "ip",
    },

    multi => {
        type   => "multi_field",
        fields => {
            multi_attr => { type           => "ip" },
            one        => { precision_step => 2, type => "ip" },
        },
    },

    bad_opt   => qr/doesn't understand 'analyzer'/,
    bad_multi => qr/doesn't understand 'analyzer'/

);

do 't/10_typemaps/test_field.pl' or die $!;

1;

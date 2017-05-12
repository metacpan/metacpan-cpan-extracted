#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::Nested';

our @mapping = (
    'basic' => {
        type       => "nested",
        dynamic    => "strict",
        properties => {
            bar => { type => "string" },
            foo => {
                dynamic        => "strict",
                include_in_all => 0,
                properties     => { foo => { type => "string" } },
                type           => "object",
            },
        },
    },

    disabled => qr /doesn't understand 'enabled'/,

    options => {
        dynamic           => "true",
        include_in_all    => 0,
        include_in_root   => 1,
        include_in_parent => 1,
        path              => "full",
        properties        => {
            bar => { type => "string" },
            foo => {
                dynamic        => "strict",
                include_in_all => 0,
                properties     => { foo => { type => "string" } },
                type           => "object",
            },
        },
        type => "nested",
    },

    multi => qr/doesn't understand 'multi'/,
);

do 't/10_typemaps/test_field.pl' or die $!;

1;

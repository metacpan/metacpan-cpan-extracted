#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'FieldTest::Object';

our @mapping = (
    'basic' => {
        type       => "object",
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

    disabled => {
        type    => "object",
        enabled => 0
    },

    options => {
        dynamic        => "true",
        include_in_all => 0,
        path           => "full",
        properties     => {
            bar => { type => "string" },
            foo => {
                dynamic        => "strict",
                include_in_all => 0,
                properties     => { foo => { type => "string" } },
                type           => "object",
            },
        },
        type => "object",
    },

    multi => qr/doesn't understand 'multi'/,
);

do 't/10_typemaps/test_field.pl' or die $!;

1;

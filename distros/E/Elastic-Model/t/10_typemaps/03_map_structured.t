#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::Structured';
our @mapping    = (

    # TUPLES #
    'tuple' => {
        dynamic => "strict",
        properties =>
            { "0" => { type => "string" }, "1" => { type => "long" } },
        type => "object",
    },

    'tuple_optional' => {
        dynamic => "strict",
        properties =>
            { "0" => { type => "string" }, "1" => { type => "long" } },
        type => "object",
    },

    'tuple_empty' => { type => 'object', enabled => 0 },
    'tuple_blank' => { type => 'object', enabled => 0 },
    'tuple_bad' => qr/Couldn't find mapping for key/,

    # DICTS #

    'dict' => {
        dynamic    => "strict",
        properties => {
            "str" => { type => "string" },
            "int" => { type => "long" }
        },
        type => "object",
    },

    'dict_optional' => {
        dynamic    => "strict",
        properties => {
            "str" => { type => "string" },
            "int" => { type => "long" }
        },
        type => "object",
    },

    'dict_empty' => { type => 'object', enabled => 0 },
    'dict_blank' => { type => 'object', enabled => 0 },
    'dict_bad' => qr/Couldn't find mapping for key/,

    # MAPS #

    'map' => { type => 'object', enabled => 0 },

    'map_empty' => { type => 'object', enabled => 0 },
    'map_blank' => { type => 'object', enabled => 0 },
    'map_bad'   => { type => 'object', enabled => 0 },

    # OPTIONALS #

    'optional'       => { type => 'long' },
    'optional_blank' => { type => 'object', enabled => 0 },
    'optional_bad' => qr/No mapper found/,

    # COMBOS #

    'combo' => {
        type       => "object",
        dynamic    => "strict",
        properties => {
            dict => {
                dynamic    => "strict",
                properties => {
                    int => { type => "long" },
                    str => { type => "string" }
                },
                type => "object",
            },
            'map' => { enabled => 0, type => "object" },
            str   => { type    => "string" },
            tuple => {
                dynamic    => "strict",
                properties => {
                    "0" => { type => "long" },
                    "1" => { type => "string" }
                },
                type => "object",
            },
        },
    },

);

do 't/10_typemaps/test_mapping.pl' or die $!;

1;

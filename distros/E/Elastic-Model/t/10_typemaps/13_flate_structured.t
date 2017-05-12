#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::Structured';

our @fields = (

    # TUPLES #
    'tuple' => [
        'tuple', [ 'foo', 2 ], { 0 => 'foo', 1 => 2 }    #
    ],

    'tuple_optional' => [
        'tuple_optional_2', [ 'foo', 2 ], { 0 => 'foo', 1 => 2 },    #
        'tuple_optional_1', ['foo'], { 0 => 'foo' }                  #
    ],

    'tuple_empty' => [
        'tuple_empty', [], []                                        #
    ],

    'tuple_blank' => [
        'tuple_blank', [ \1 ], [ \1 ]                                #
    ],

    'tuple_bad' => qr/No ..flator found for key/,

    # DICTS #
    'dict' => [
        'dict', { str => 'Foo', int => 5 }, { str => 'Foo', int => 5 }    #
    ],

    'dict_optional' => [
        'dict_optional_2', { str => 'Foo', int => 5 },
        { str => 'Foo', int => 5 },                                       #
        'dict_optional_1', { int => 5 }, { int => 5 }                     #
    ],

    'dict_empty' => [ 'dict_empty', {}, {} ],

    'dict_blank' => [ 'dict_blank', { a => \1 }, { a => \1 }, ],

    'dict_bad' => qr/No ..flator found for key/,

    # MAPS #
    'map' => [
        'map', { foo => 1, bar => 2 }, { foo => 1, bar => 2 }             #
    ],

    'map_blank' =>
        [ 'map_blank', { foo => 1, 1 => 'foo' }, { foo => 1, 1 => 'foo' }, ],

    'map_empty' =>
        [ 'map_empty', { foo => 1, 1 => 'foo' }, { foo => 1, 1 => 'foo' }, ],

    'map_bad' => qr/No ..flator found for attribute/,

    # OPTIONALS @
    'optional' => [
        'optional', 123, 123    #
    ],

    'optional_blank' => [
        'optional_blank', 123, 123    #
    ],

    'optional_bad' => qr/No ..flator found for attribute/,

    # COMBOS #
    'combo' => [
        'combo_1',
        {   str  => 'foo',
            dict => { int => 1, str => 'bar' },
            map => { 5 => 'baz' },
            tuple => [ 5, 'baz' ]
        },
        {   str  => 'foo',
            dict => { int => 1, str => 'bar' },
            map   => { 5 => 'baz' },
            tuple => { 0 => 5, 1 => 'baz' }
        },

        'combo_2',
        {   str   => 'foo',
            dict  => { int => 1 },
            tuple => [5]
        },
        {   str   => 'foo',
            dict  => { int => 1 },
            tuple => { 0 => 5 }
        },
        ]

);

do 't/10_typemaps/test_flation.pl' or die $!;

1;

#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::Moose';
our @fields     = (
    'any' => [
        'undef', undef, undef,    #
        'zero',  0,     0,        #
        'str', Foo => 'Foo'       #
    ],

    'item' => [
        'undef', undef, undef,    #
        'zero',  0,     0,        #
        'str', Foo => 'Foo'       #
    ],

    'maybe' => [
        'undef', undef, undef,    #
        'zero',  0,     0,        #
        'str', Foo => 'Foo'       #
    ],

    'maybe_str' => [
        'undef', undef, undef,    #
        'zero',  0,     0,        #
        'str', Foo => 'Foo'       #
    ],

    'undef' => [
        'undef', undef, undef     #
    ],

    'defined' => [
        'zero', 0, 0,             #
        'str', Foo => 'Foo'       #
    ],

    'value' => [
        'zero', 0, 0,             #
        'str', Foo => 'Foo'       #
    ],

    'str' => [
        'str', Foo => 'Foo'       #
    ],

    'num' => [
        'zero',
        0 => 0,                   #
        'float',     1.5,  1.5,   #
        'neg_float', -1.5, -1.5   #
    ],

    'int' => [
        'zero',
        0 => 0,                   #
        'pos', 1,  1,             #
        'neg', -1, -1             #
    ],

    'ref' => [
        'ref', \5, \5             #
    ],

    'scalar_ref' => [
        'undef',      \undef, undef,    #
        'scalar_ref', \'foo', 'foo'     #
    ],

    'scalar_ref_str' => [
        'scalar_ref', \'foo', 'foo'     #
    ],

    'enum' => [
        'str', 'foo', 'foo'             #
    ],

    'array_ref' => [
        'empty', [], [],                #
        'str', [ 'foo', 'bar' ], [ 'foo', 'bar' ]    #
    ],

    'array_ref_str' => [
        'empty', [], [],                             #
        'str', [ 'foo', 'bar' ], [ 'foo', 'bar' ]    #
    ],

    'hash_ref' => [
        'empty', {}, {},                             #
        'str', { foo => 'one', bar => 'two' },       #
        { foo => 'one', bar => 'two' }               #
    ],

    'hash_ref_str' => [
        'empty', {}, {},                             #
        'str', { foo => 'one', bar => 'two' },       #
        { foo => 'one', bar => 'two' }               #
    ],

    'maybe_coderef'     => qr/No ..flator found/,
    'array_ref_coderef' => qr/No ..flator found/,
    'hash_ref_coderef'  => qr/No ..flator found/,
    'code_ref'          => qr/No ..flator found/,
    'glob_ref'          => qr/No ..flator found/,
    'regexp_ref'        => qr/No ..flator found/,
    'file_handle'       => qr/No ..flator found/,
    'union'             => qr/No ..flator found/,
    'type'              => qr/No ..flator found/,

);

do 't/10_typemaps/test_flation.pl' or die $!;

1;

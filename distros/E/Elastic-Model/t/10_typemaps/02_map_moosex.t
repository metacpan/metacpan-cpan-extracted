#!/usr/bin/perl

use strict;
use warnings;

our $test_class = 'TypeTest::MooseX';
our @mapping    = (
    'any'               => { type => 'object',  enabled    => 0 },
    'item'              => { type => 'object',  enabled    => 0 },
    'maybe'             => { type => 'object',  enabled    => 0 },
    'defined'           => { type => 'object',  enabled    => 0 },
    'value'             => { type => 'object',  enabled    => 0 },
    'ref'               => { type => 'object',  enabled    => 0 },
    'scalar_ref'        => { type => 'object',  enabled    => 0 },
    'array_ref'         => { type => 'object',  enabled    => 0 },
    'hash_ref'          => { type => 'object',  enabled    => 0 },
    'hash_ref_str'      => { type => 'object',  enabled    => 0 },
    'hash_ref_coderef'  => { type => 'object',  enabled    => 0 },
    'code_ref'          => { type => 'object',  enabled    => 0 },
    'glob_ref'          => { type => 'object',  enabled    => 0 },
    'file_handle'       => { type => 'object',  enabled    => 0 },
    'union'             => { type => 'object',  enabled    => 0 },
    'maybe_str'         => { type => 'string' },
    'maybe_bool'        => { type => 'boolean' },
    'maybe_coderef'     => { type => 'object',  enabled    => 0 },
    'bool'              => { type => 'boolean', null_value => 0 },
    'str'               => { type => 'string' },
    'scalar_ref_str'    => { type => 'string' },
    'array_ref_str'     => { type => 'string' },
    'array_ref_coderef' => { type => 'object',  enabled    => 0 },
    'subtype_str'       => { type => 'string' },
    'enum'              => {
        type  => 'string',
        index => 'not_analyzed'
    },
    'undef'      => { type => 'string', index => 'not_analyzed' },
    'regexp_ref' => { type => 'string', index => 'no' },
    'num'        => { type => 'float' },
    'int'        => { type => 'long' },
    'type' => qr/No mapper found/,
);

do 't/10_typemaps/test_mapping.pl' or die $!;

1;

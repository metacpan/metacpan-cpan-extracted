#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/base.pl');

command_is(['typemap_get'], {
    command => 'typemap_get',
    types   => [
        {
            type        => 'bool',
            name        => 'bool',
            xsi_type    => 'xsd:boolean',
        },
        {
            type        => 'float',
            name        => 'float',
            xsi_type    => 'xsd:float',
        },
        {
            type        => 'int',
            name        => 'int',
            xsi_type    => 'xsd:integer',
        },
        {
            type        => 'string',
            name        => 'string',
            xsi_type    => 'xsd:string',
        },
        {
            type        => 'undefined',
            name        => 'undef',
            xsi_type    => undef,
        },
        {
            type        => 'array',
            name        => 'ARRAY',
            xsi_type    => undef,
        },
        {
            type        => 'hash',
            name        => 'HASH',
            xsi_type    => undef,
        },
    ],
});

done_testing();

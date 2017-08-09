#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny;

validation_spec 'edit' => [
    name => [
        into => '+',
    ],
];

{
    my ($p, $e) = validate_form edit => {
        name => '42foo',
    };

    is $e, undef, 'no errors';
    is $p->{name}, 42, 'coercer gets 42, the number';
}

done_testing;

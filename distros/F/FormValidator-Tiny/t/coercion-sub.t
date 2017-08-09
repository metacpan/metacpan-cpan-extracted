#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny;

validation_spec 'edit' => [
    name => [
        into => sub { "$_$_" },
    ],
];

{
    my ($p, $e) = validate_form edit => {
        name => 'Foo',
    };

    is $e, undef, 'no errors';
    is $p->{name}, 'FooFoo', 'coercer concatted value to self';
}

done_testing;

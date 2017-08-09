#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :filters );

validation_spec 'edit' => [
    name => [
        into => '{}',
    ],
    name2 => [
        multiple => 1,
        into     => '{}',
    ],
    name3 => [
        into => '{}',
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name  => 'foo',
        name2 => 'foo',
        name2 => 'bar',
        name3 => { 'foo' => 'bar', 'baz' => 'qux' },
    ];

    is $e, undef, 'no errors';
    is $p->{name}, { 'foo' => 'foo' }, 'name is {foo=>foo}';
    is $p->{name2}, { 'foo' => 'bar' }, 'name is {foo=>bar}';
    is $p->{name3}, { 'foo' => 'bar', 'baz' => 'qux' },
        'name is {foo=>bar,baz=>qux}';
}

done_testing;

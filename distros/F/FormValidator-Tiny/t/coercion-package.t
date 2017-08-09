#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :filters );

package MyClass {
    sub new {
        my ($class, $stuff) = @_;
        bless { stuff => $stuff }, $class;
    }
}

validation_spec 'edit' => [
    name => [
        into => 'MyClass',
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name  => 'stuff',
    ];

    is $e, undef, 'no errors';
    isa_ok $p->{name}, 'MyClass';
    is $p->{name}{stuff}, 'stuff', 'name has MyClass->{stuff} set to stuff';
}

done_testing;

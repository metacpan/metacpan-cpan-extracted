#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :filters );

package Types::MyType {
    sub new {
        my ($class) = @_;
        bless {}, $class;
    }

    sub coerce {
        my ($type, $value) = @_;
        return "$value$value";
    }
}

sub MyType { Types::MyType->new }

validation_spec 'edit' => [
    name => [
        into => MyType,
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name  => 'stuff',
    ];

    is $e, undef, 'no errors';
    is $p->{name}, 'stuffstuff', 'name is coerced into MyType';
}

done_testing;

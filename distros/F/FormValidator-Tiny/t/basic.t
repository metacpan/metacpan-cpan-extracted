#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use ok('FormValidator::Tiny');
import FormValidator::Tiny(':predicates', ':filters');

my $edit = validation_spec 'edit' => [
    name => [
        required => 1,
        must     => limit_character_set('_', 'a-z', 'A-Z', '0-9'),
        must     => length_in_range(5, 16),
    ],
    age => [
        optional   => 1,
        must       => qr/^[0-9]+$/,
        with_error => 'Must be an integer.',
        into       => '+',
        must       => number_in_range(13, '*'),
    ],
];

{
    my ($p, $e) = validate_form edit => {
        name => 'Steve',
        age  => '14',
    };

    is $e, undef, 'no errors';
    is $p->{name}, 'Steve', 'got steve';
    is $p->{age}, 14, 'got 14';
}

{
    my ($p, $e) = validate_form edit => {
        age => '14',
    };

    is $e->{name}[0], 'Required.', 'got an error';
    is $p->{name}, undef, 'no steve';
    is $p->{age}, 14, 'got 14';
}

{
    my ($p, $e) = validate_form $edit => {
        name => 'Steve',
        age  => '14',
    };

    is $e, undef, 'no errors';
    is $p->{name}, 'Steve', 'got steve';
    is $p->{age}, 14, 'got 14';
}

{
    my ($p, $e) = validate_form $edit => {
        age => '14',
    };

    is $e->{name}[0], 'Required.', 'got an error';
    is $p->{name}, undef, 'no steve';
    is $p->{age}, 14, 'got 14';
}

done_testing;

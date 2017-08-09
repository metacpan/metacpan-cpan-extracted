#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :predicates );

sub red_team { ($_ eq 'red', 'I like team red.') }

validation_spec 'edit' => [
    name => [
        must => \&red_team,
        with_error => 'Neener neener neener!',
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name => 'blue',
    ];

    is $e, { name => [ 'Neener neener neener!' ] }, 'name has error';
    is $p->{name}, undef, 'name is red';
}

done_testing;

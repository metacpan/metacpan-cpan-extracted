#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :predicates );

sub red_team { ($_ eq 'red', 'I like team red.') }

validation_spec 'edit' => [
    name => [
        must => \&red_team,
    ],
    name2 => [
        must => \&red_team,
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name => 'red',
        name2 => 'blue',
    ];

    is $e, { name2 => [ 'I like team red.' ] }, 'name2 has error';
    is $p->{name}, 'red', 'name is red';
}

done_testing;

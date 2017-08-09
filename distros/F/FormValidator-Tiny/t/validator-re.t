#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :predicates );

my $team_red = qr/^red$/;

validation_spec 'edit' => [
    name => [
        must => $team_red,
    ],
    name2 => [
        must => $team_red,
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name => 'red',
        name2 => 'blue',
    ];

    is $e, { name2 => [ 'Incorrect.' ] }, 'name2 has error';
    is $p->{name}, 'red', 'name is red';
}

done_testing;

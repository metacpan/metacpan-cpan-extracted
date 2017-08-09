#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny;

validation_spec 'edit' => [
    name => [
        into => '?',
    ],
    name2 => [
        into => '?+',
    ],
    name3 => [
        into => '?perl',
    ],
];

{
    my ($p, $e) = validate_form edit => {
        name  => '0',
        name2 => '0',
        name3 => '0',
    };

    is $e, undef, 'no errors';
    ok $p->{name}, 'name is true';
    ok !$p->{name2}, 'name is false';
    ok !$p->{name3}, 'name is false';
}

{
    my ($p, $e) = validate_form edit => {
        name  => '1',
        name2 => '1',
        name3 => '1',
    };

    is $e, undef, 'no errors';
    ok $p->{name}, 'name is true';
    ok $p->{name2}, 'name is true';
    ok $p->{name3}, 'name is true';
}

{
    my ($p, $e) = validate_form edit => {
        name  => '',
        name2 => '',
        name3 => '',
    };

    is $e, undef, 'no errors';
    ok !$p->{name}, 'name is false';
    ok !$p->{name2}, 'name is false';
    ok !$p->{name3}, 'name is false';
}

{
    my ($p, $e) = validate_form edit => {
        name  => '0E0',
        name2 => '0E0',
        name3 => '0E0',
    };

    is $e, undef, 'no errors';
    ok $p->{name}, 'name is true';
    ok !$p->{name2}, 'name is false';
    ok $p->{name3}, 'name is true';
}

done_testing;

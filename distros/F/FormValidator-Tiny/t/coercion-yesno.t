#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :filters );

validation_spec 'edit' => [
    name => [
        into => '?yes!no',
    ],
    name2 => [
        into => '?yes!no',
    ],
    name3 => [
        into => '?yes!no',
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name  => 'yes',
        name2 => 'no',
        name3 => 'wth',
    ];

    is $e, { name3 => [ 'Enter "yes" or "no".' ] }, 'name3 error';
    ok $p->{name}, 'name is true';
    ok !$p->{name2}, 'name2 is false';
}

done_testing;

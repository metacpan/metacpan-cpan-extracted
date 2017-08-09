#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny;

sub be_red { ($_ eq 'red', 'RED!') }

my $edit = validation_spec [
    name => [
        required => 1,
        must     => \&be_red,
    ],
    name2 => [
        required => 0,
        must     => \&be_red,
    ],
    name3 => [
        optional => 1,
        must     => \&be_red,
    ],
    name4 => [
        optional => 0,
        must     => \&be_red,
    ],
];

{
    my ($p, $e) = validate_form $edit => [
        name  => 'red',
        name2 => 'red',
        name3 => 'red',
        name4 => 'red',
    ];

    is $e, undef, 'no errors';
    is $p->{name}, 'red', 'name is red';
    is $p->{name2}, 'red', 'name2 is red';
    is $p->{name3}, 'red', 'name3 is red';
    is $p->{name4}, 'red', 'name4 is red';
}

{
    my ($p, $e) = validate_form $edit => [
        name  => 'blue',
        name2 => 'blue',
        name3 => 'blue',
        name4 => 'blue',
    ];

    is $e, {
        name  => [ 'RED!' ],
        name2 => [ 'RED!' ],
        name3 => [ 'RED!' ],
        name4 => [ 'RED!' ],
    }, 'no errors';
    is $p->{name}, undef, 'name is undef';
    is $p->{name2}, undef, 'name2 is undef';
    is $p->{name3}, undef, 'name3 is undef';
    is $p->{name4}, undef, 'name4 is undef';
}

{
    my ($p, $e) = validate_form $edit => [
        name  => undef,
        name2 => undef,
        name3 => undef,
        name4 => undef,
    ];

    is $e, {
        name => [ 'Required.' ],
        name4 => [ 'Required.' ],
    }, 'no errors';
    is $p->{name}, undef, 'name is undef';
    is $p->{name2}, undef, 'name2 is undef';
    is $p->{name3}, undef, 'name3 is undef';
    is $p->{name4}, undef, 'name4 is undef';
}

done_testing;

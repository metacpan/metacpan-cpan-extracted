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
        multiple  => 1,
        each_must => \&red_team,
    ],
    name3 => [
        multiple  => 1,
        key_must  => \&red_team,
    ],
    name4 => [
        multiple   => 1,
        value_must => \&red_team,
    ],
    name5 => [
        multiple  => 1,
        into      => '{}',
        each_must => \&red_team,
    ],
    name6 => [
        multiple  => 1,
        into      => '{}',
        key_must  => \&red_team,
    ],
    name7 => [
        multiple   => 1,
        into      => '{}',
        value_must => \&red_team,
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name => 'red',
        name2 => 'red',
        name2 => 'red',
        name3 => 'red',
        name3 => 'red',
        name4 => 'red',
        name4 => 'red',
        name5 => 'red',
        name5 => 'red',
        name6 => 'red',
        name6 => 'red',
        name7 => 'red',
        name7 => 'red',
    ];

    is $e, undef, 'no errors';
    is $p->{name}, 'red', 'name is red';
    is $p->{name2}, [ 'red', 'red' ], 'name2 is [red,red]';
    is $p->{name3}, [ 'red', 'red' ], 'name3 is [red,red]';
    is $p->{name4}, [ 'red', 'red' ], 'name4 is [red,red]';
    is $p->{name5}, { 'red', 'red' }, 'name5 is {red,red}';
    is $p->{name6}, { 'red', 'red' }, 'name6 is {red,red}';
    is $p->{name7}, { 'red', 'red' }, 'name7 is {red,red}';
}

{
    my ($p, $e) = validate_form edit => [
        name => 'blue',
        name2 => 'red',
        name2 => 'blue',
        name3 => 'red',
        name3 => 'blue',
        name4 => 'red',
        name4 => 'blue',
        name5 => 'red',
        name5 => 'blue',
        name6 => 'red',
        name6 => 'blue',
        name7 => 'red',
        name7 => 'blue',
    ];

    is $e, {
        name => [ 'I like team red.' ],
        name2 => [ 'I like team red.' ],
        name4 => [ 'I like team red.' ],
        name5 => [ 'I like team red.' ],
        name7 => [ 'I like team red.' ],
    }, 'no errors';
    is $p->{name}, undef, 'name is undef';
    is $p->{name2}, undef, 'name2 is undef';
    is $p->{name3}, [ 'red', 'blue' ], 'name3 is [red,blue]';
    is $p->{name4}, undef, 'name4 is undef';
    is $p->{name5}, undef, 'name5 is undef';
    is $p->{name6}, { 'red', 'blue' }, 'name6 is {red,blue}';
    is $p->{name7}, undef, 'name7 is undef';
}

{
    my ($p, $e) = validate_form edit => [
    ];

    is $e, undef, 'no errors';
    is $p->{name}, undef, 'name is undef';
    is $p->{name2}, [], 'name2 is []';
    is $p->{name3}, [], 'name3 is []';
    is $p->{name4}, [], 'name4 is []';
    is $p->{name5}, {}, 'name5 is {}';
    is $p->{name6}, {}, 'name6 is {}';
    is $p->{name7}, {}, 'name7 is {}';
}

{
    my ($p, $e) = validate_form edit => [
        name => 'red',
        name2 => 'blue',
        name2 => 'red',
        name3 => 'blue',
        name3 => 'red',
        name4 => 'blue',
        name4 => 'red',
        name5 => 'blue',
        name5 => 'red',
        name6 => 'blue',
        name6 => 'red',
        name7 => 'blue',
        name7 => 'red',
    ];

    is $e, {
        name2 => [ 'I like team red.' ],
        name3 => [ 'I like team red.' ],
        name5 => [ 'I like team red.' ],
        name6 => [ 'I like team red.' ],
    }, 'no errors';
    is $p->{name}, 'red', 'name is red';
    is $p->{name2}, undef, 'name2 is undef';
    is $p->{name3}, undef, 'name3 is undef';
    is $p->{name4}, [ 'blue', 'red' ], 'name4 is [blue,red]';
    is $p->{name5}, undef, 'name5 is undef';
    is $p->{name6}, undef, 'name6 is undef';
    is $p->{name7}, { 'blue', 'red' }, 'name7 is {blue,red}';
}

{
    my ($p, $e) = validate_form edit => [
        name => 'blue',
        name2 => 'blue',
        name2 => 'blue',
        name3 => 'blue',
        name3 => 'blue',
        name4 => 'blue',
        name4 => 'blue',
        name5 => 'blue',
        name5 => 'blue',
        name6 => 'blue',
        name6 => 'blue',
        name7 => 'blue',
        name7 => 'blue',
    ];

    is $e, {
        name => [ 'I like team red.' ],
        name2 => [ 'I like team red.' ],
        name3 => [ 'I like team red.' ],
        name4 => [ 'I like team red.' ],
        name5 => [ 'I like team red.' ],
        name6 => [ 'I like team red.' ],
        name7 => [ 'I like team red.' ],
    }, 'no errors';
    is $p->{name}, undef, 'name is undef';
    is $p->{name2}, undef, 'name2 is undef';
    is $p->{name3}, undef, 'name3 is undef';
    is $p->{name4}, undef, 'name4 is undef';
    is $p->{name5}, undef, 'name5 is undef';
    is $p->{name6}, undef, 'name6 is undef';
    is $p->{name7}, undef, 'name7 is undef';
}

done_testing;

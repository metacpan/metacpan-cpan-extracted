#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( :validation :predicates );

package Types::One {
    sub new { bless {}, $_[0] }
    sub check { $_[1] eq 'red' }
}
sub TypeOne() { Types::One->new }

package Types::Two {
    sub new { bless {}, $_[0] }
    sub check { $_[1] eq 'red' }
    sub get_message { "Expected 'red' but got '$_[1]' instead." }
}
sub TypeTwo() { Types::Two->new }

package Types::Three {
    sub new { bless {}, $_[0] }
    sub validate { $_[1] eq 'red' ? undef : "Team red or bust!" }
}
sub TypeThree() { Types::Three->new }

validation_spec 'edit' => [
    name => [
        must => TypeOne,
    ],
    name2 => [
        must => TypeTwo,
    ],
    name3 => [
        must => TypeThree,
    ],
];

{
    my ($p, $e) = validate_form edit => [
        name => 'red',
        name2 => 'red',
        name3 => 'red',
    ];

    is $e, undef, 'no errors';
    is $p->{name}, 'red', 'name is red';
    is $p->{name2}, 'red', 'name1 is red';
    is $p->{name3}, 'red', 'name2 is red';
}

{
    my ($p, $e) = validate_form edit => [
        name => 'blue',
        name2 => 'blue',
        name3 => 'blue',
    ];

    is $e->{name}, [ 'Incorrect.' ], 'name has errors';
    is ref $e->{name2}[0], 'CODE', 'name2 error is a coderef';
    is $e->{name2}[0]->('blue'), "Expected 'red' but got 'blue' instead.",
        'name2 coderef outputs error when called';
    is $e->{name3}, [ 'Team red or bust!' ], 'name3 has errors';
    is $p->{name}, undef, 'name is undef';
    is $p->{name2}, undef, 'name1 is undef';
    is $p->{name3}, undef, 'name2 is undef';
}

package Types::Broken {
    sub new { bless {}, $_[0] }
}
sub TypeBroken() { Types::Broken->new }

ok dies {
    validation_spec 'edit2' => [
        name => [
            must => TypeBroken,
        ],
    ];
}, 'should die with an invalid type';

done_testing;

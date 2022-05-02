#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Util qw(query search simple_expression_query);
use Test::Deep;
use Test::More;

my $list = [
    {
        id      => 1,
        name    => 'Bob',
        age     => 34,
        married => 1,
        notes   => 'Enjoys bowling on Thursdays',
    },
    {
        id      => 2,
        name    => 'Ken',
        age     => 17,
        married => 0,
        notes   => 'Eats dessert first',
        color   => '',
    },
    {
        id      => 3,
        name    => 'Becky',
        age     => 25,
        married => 1,
        notes   => 'Listens to rap music on repeat',
        color   => 'orange',
    },
    {
        id      => 4,
        name    => 'Bobby',
        age     => 5,
        notes   => 'Loves candy and running around like a crazy person',
        color   => 'blue',
    },
];

subtest 'Declarative structure' => sub {
    my $result = search($list, name => 'Bob');
    cmp_deeply $result, [shallow($list->[0])], 'Find Bob'
        or diag explain $result;

    $result = search($list, name => 'Ken');
    cmp_deeply $result, [$list->[1]], 'Find Ken'
        or diag explain $result;

    $result = search($list, age => 25);
    cmp_deeply $result, [$list->[2]], 'Find Becky by age'
        or diag explain $result;

    $result = search($list, {name => 'Becky', age => 25});
    cmp_deeply $result, [$list->[2]], 'Find Becky by name AND age'
        or diag explain $result;

    $result = search($list, {name => 'Becky', age => 99});
    cmp_deeply $result, [], 'Miss Becky with wrong age'
        or diag explain $result;

    $result = search($list, [name => 'Becky', age => 17]);
    cmp_deeply $result, [$list->[1], $list->[2]], 'Find Ken and Becky with different criteria'
        or diag explain $result;

    $result = search($list, name => 'Becky', age => 17);
    cmp_deeply $result, [$list->[1], $list->[2]], 'Query list defaults to OR logic'
        or diag explain $result;

    $result = search($list, age => {'>=', 18});
    cmp_deeply $result, [$list->[0], $list->[2]], 'Find adults'
        or diag explain $result;

    $result = search($list, name => {'=~', qr/^Bob/});
    cmp_deeply $result, [$list->[0], $list->[3]], 'Find both Bobs'
        or diag explain $result;

    $result = search($list, -and => [name => 'Becky', age => 99]);
    cmp_deeply $result, [], 'Specify AND logic explicitly'
        or diag explain $result;

    $result = search($list, {name => 'Becky', age => 99});
    cmp_deeply $result, [], 'Specify AND logic implicitly'
        or diag explain $result;

    $result = search($list, '!' => 'married');
    cmp_deeply $result, [$list->[1], $list->[3]], 'Find unmarried (using normal operator)'
        or diag explain $result;

    $result = search($list, -false => 'married');
    cmp_deeply $result, [$list->[1], $list->[3]], 'Find unmarried (using special operator)'
        or diag explain $result;

    $result = search($list, -true => 'married');
    cmp_deeply $result, [$list->[0], $list->[2]], 'Find married persons (using special operator)'
        or diag explain $result;

    $result = search($list, -not => {name => {'=~', qr/^Bob/}});
    cmp_deeply $result, [$list->[1], $list->[2]], 'What about Bob? Inverse a complex query'
        or diag explain $result;

    $result = search($list, -nonempty => 'color');
    cmp_deeply $result, [$list->[2], $list->[3]], 'Find the colorful'
        or diag explain $result;

    $result = search($list, color => {ne => undef});
    cmp_deeply $result, [$list->[2], $list->[3]], 'Find the colorful (compare to undef)'
        or diag explain $result;

    $result = search($list, -empty => 'color');
    cmp_deeply $result, [$list->[0], $list->[1]], 'Find those without color'
        or diag explain $result;

    $result = search($list, color => {eq => undef});
    cmp_deeply $result, [$list->[0], $list->[1]], 'Find those without color (compare to undef)'
        or diag explain $result;

    $result = search($list, -defined => 'color');
    cmp_deeply $result, [$list->[1], $list->[2], $list->[3]], 'Find defined colors'
        or diag explain $result;

    $result = search($list, -undef => 'color');
    cmp_deeply $result, [$list->[0]], 'Find undefined colors'
        or diag explain $result;

    $result = search($list,
        -and => [
            name => {'=~', qr/^Bob/},
            -and => {
                name => {'ne', 'Bob'},
            },
        ],
        -not => {'!' => 'Bobby'},
    );
    cmp_deeply $result, [$list->[3]], 'Complex query'
        or diag explain $result;

    my $query = query(name => 'Ken');
    $result = search($list, $query);
    cmp_deeply $result, [$list->[1]], 'Search using a pre-compiled query'
        or diag explain $result;

    my $custom_query = sub { shift->{name} eq 'Bobby' };
    $result = search($list, $custom_query);
    cmp_deeply $result, [$list->[3]], 'Search using a custom query subroutine'
        or diag explain $result;
};

##############################################################################

subtest 'Simple expressions' => sub {
    my $simple_query = simple_expression_query('bob', qw{name notes});
    my $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[0], $list->[3]], 'Basic one-term expression'
        or diag explain $result;

    $result = search($list, \'bob', qw{name notes});
    cmp_deeply $result, [$list->[0], $list->[3]], 'Basic one-term expression on search'
        or diag explain $result;

    $simple_query = simple_expression_query(' Dessert  ', qw{notes});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[1]], 'Whitespace is ignored'
        or diag explain $result;

    $simple_query = simple_expression_query('to music', qw{notes});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[2]], 'Multiple terms'
        or diag explain $result;

    $simple_query = simple_expression_query('"to music"', qw{notes});
    $result = search($list, $simple_query);
    cmp_deeply $result, [], 'One quoted term'
        or diag explain $result;

    $simple_query = simple_expression_query('candy "CRAZY PERSON" ', qw{notes});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[3]], 'Multiple terms, one quoted term'
        or diag explain $result;

    $simple_query = simple_expression_query(" bob\tcandy\n\n", qw{name notes});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[3]], 'Multiple terms in different fields'
        or diag explain $result;

    $simple_query = simple_expression_query('music -repeat', qw{notes});
    $result = search($list, $simple_query);
    cmp_deeply $result, [], 'Multiple terms, one negative term'
        or diag explain $result;

    $simple_query = simple_expression_query('-bob', qw{name});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[1], $list->[2]], 'Negative term'
        or diag explain $result;

    $simple_query = simple_expression_query('bob -bobby', qw{name});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[0]], 'Multiple mixed terms'
        or diag explain $result;

    $simple_query = simple_expression_query(25, '==', qw{age});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[2]], 'Custom operator'
        or diag explain $result;

    $simple_query = simple_expression_query('-25', '==', qw{age});
    $result = search($list, $simple_query);
    cmp_deeply $result, [$list->[0], $list->[1], $list->[3]], 'Negative term, custom operator'
        or diag explain $result;
};

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use Markdown::Table;
use Test::More;

my $markdown = q~
This table shows all employees and their role.

| Id | Name | Role |
|---|---|---|
| 1 | John Smith | Testrole |
| 2 | Jane Smith | Admin |

And this is a second table showing something different

| ID | Dists |
|----|-------|
|  1 |   198 |
|  2 |    53 |
|  3 |    21 |
~;

my @tables = Markdown::Table->parse(
    $markdown,
);

is $tables[0]->get_table, '| Id | Name       | Role     |
|----|------------|----------|
|  1 | John Smith | Testrole |
|  2 | Jane Smith | Admin    |
';
is $tables[1]->get_table, '| ID | Dists |
|----|-------|
|  1 |   198 |
|  2 |    53 |
|  3 |    21 |
'
;

is_deeply $tables[0]->cols, [
    'Id', 'Name', 'Role'
];

is_deeply $tables[1]->cols, [
    'ID', 'Dists'
];

is_deeply $tables[0]->rows, [
    [ 1, 'John Smith', 'Testrole' ],
    [ 2, 'Jane Smith', 'Admin' ],
];

is_deeply $tables[1]->rows, [
    [ 1, 198 ],
    [ 2, 53 ],
    [ 3, 21 ],
];

done_testing();

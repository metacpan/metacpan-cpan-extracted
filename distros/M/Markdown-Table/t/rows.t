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
~;

my @tables = Markdown::Table->parse(
    $markdown,
);

is_deeply $tables[0]->cols, [
    qw/ Id Name Role /
];

is_deeply $tables[0]->rows, [
    [1, "John Smith", "Testrole"],
    [2, "Jane Smith", "Admin"],
];

done_testing();

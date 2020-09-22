#!/usr/bin/perl

use strict;
use warnings;

use Markdown::Table;
use Test::More;

my @columns = qw(Id Name Role);
my @data = (
    [ 1, 'John Smith', 'Testrole' ],
    [ 2, 'Jane Smith', 'Admin' ],
);

my $table = Markdown::Table->new(
    cols => \@columns,
    rows => \@data,
);

my $table_check = q~| Id | Name       | Role     |
|----|------------|----------|
|  1 | John Smith | Testrole |
|  2 | Jane Smith | Admin    |
~;

is $table->get_table, $table_check;


done_testing();

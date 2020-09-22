#!/usr/bin/perl

use strict;
use warnings;

use Markdown::Table;
use Test::More;

my $table   = Markdown::Table->new;
my @columns = qw(Id Name Role);
$table->set_cols( @columns );

my @data = (
    [ 1, 'John Smith', 'Testrole' ],
    [ 2, 'Jane Smith', 'Admin' ],
);

$table->add_rows( @data );

my $table_check = q~| Id | Name       | Role     |
|----|------------|----------|
|  1 | John Smith | Testrole |
|  2 | Jane Smith | Admin    |
~;

is $table->get_table, $table_check;

done_testing();

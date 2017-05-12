#!/usr/bin/perl -w

use lib qw(t/lib);
use strict;

BEGIN {
    use Test::More tests=>3;
    use_ok('Math::Vector::SortIndexes', qw(sort_indexes_descending 
                                          sort_indexes_ascending) );
}
my @vector = qw(44 22 33 11);
my @indexes1 = sort_indexes_ascending @vector; 
my @indexes2 = sort_indexes_descending @vector; 

is("@indexes1", "3 1 2 0");
is("@indexes2", "0 2 1 3");

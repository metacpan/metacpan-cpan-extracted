#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 12;

use Logic::TruthTable::Util qw(:all);

my $width = 4;
my(@terms, @col0, @col1);

#
# Test the minterms.
#
push_minterm_columns($_, $_ + 3, \@col1, \@col0) for (0 .. 7);
is_deeply(\@col1, [0, 3, 4, 7],
	"push_minterm_columns() col1: [" . join(",", @col1) . "]");

is_deeply(\@col0, [0, 2, 4, 6],
	"push_minterm_columns() col0: [" . join(",", @col0) . "]");

#
# Reset for maxterms.
#
@col0 = ();
@col1 = ();

push_maxterm_columns($_, $_ + 3, \@col1, \@col0) for (0 .. 7);
is_deeply(\@col1, [1, 2, 5, 6],
	"push_maxterm_columns() col1: [" . join(",", @col1) . "]");

is_deeply(\@col0, [1, 3, 5, 7],
	"push_maxterm_columns() col0: [" . join(",", @col0) . "]");

#
# Column 2 of a four-variable table looks like this:
#     "0000111100001111"
#
@terms = var_column($width, 2);
is_deeply(\@terms, [4, 5, 6, 7, 12, 13, 14, 15],
	"var_column(): [" . join(",", @terms) . "]");

@terms = rotate_terms($width, [1, 5, 6, 13, 15], 3);
is_deeply(\@terms, [4, 8, 9, 0, 2],
	"rotate_terms(): [" . join(",", @terms) . "]");

@terms = rotate_terms($width, [1, 5, 6, 13, 15], -3);
is_deeply(\@terms, [14, 2, 3, 10, 12],
	"rotate_terms(): [" . join(",", @terms) . "]");

@terms = rotate_terms($width, [1, 5, 6, 13, 15], 0);
is_deeply(\@terms, [1, 5, 6, 13, 15],
	"rotate_terms(): [" . join(",", @terms) . "]");

@terms = shift_terms($width, [1, 5, 6, 13], 3);
is_deeply(\@terms, [4, 8, 9],
	"shift_terms(): [" . join(",", @terms) . "]");

@terms = shift_terms($width, [1, 5, 6, 13], -3);
is_deeply(\@terms, [2, 3, 10],
	"shift_terms(): [" . join(",", @terms) . "]");

@terms = shift_terms($width, [1, 5, 6, 13, 15], 0);
is_deeply(\@terms, [1, 5, 6, 13, 15],
	"rotate_terms(): [" . join(",", @terms) . "]");

@terms = reverse_terms($width, [1, 5, 6, 13]);
is_deeply(\@terms, [14, 10, 9, 2],
	"reverse_terms(): [" . join(",", @terms) . "]");


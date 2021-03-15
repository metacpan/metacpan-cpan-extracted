#!perl
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('List::GroupingPriorityQueue') || print "Bail out!\n";
}

diag(
    "Testing List::GroupingPriorityQueue $List::GroupingPriorityQueue::VERSION, Perl $], $^X"
);

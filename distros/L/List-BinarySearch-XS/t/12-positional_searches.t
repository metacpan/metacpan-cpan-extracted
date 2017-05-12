#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use List::BinarySearch::XS qw( :all );

my @integers    = ( 100, 200, 300, 400, 500 );
my @strings      = qw( ape  bat  bear  cat  dog );

subtest
    "Test numeric search function that returns insert position upon no-match."
    => sub {
        plan tests => 6;
        is(
            ( binsearch_pos { $a <=> $b } 100, @integers ), 0,
            "binsearch_pos:    Found at position 0."
        );
        is(
            ( binsearch_pos { $a <=> $b } 50,  @integers ), 0,
            "binsearch_pos: Insert at position 0."
        );
        is(
            ( binsearch_pos { $a <=> $b } 300, @integers ), 2,
            "binsearch_pos: Found at position 2."
        );
        is(
            ( binsearch_pos { $a <=> $b } 350, @integers ), 3,
            "binsearch_pos: Insert at position 3."
        );
        is(
            ( binsearch_pos { $a <=> $b } 500, @integers ), 4,
            "binsearch_pos: Found at last position."
        );
        is(
            ( binsearch_pos { $a <=> $b } 550, @integers ), 5,
            "binsearch_pos: Insert after last position."
        );
        done_testing();
};

# my @strings      = qw( ape  bat  bear  cat  dog );

subtest
    "Test string search function that returns insert position upon no-match."
    => sub {
        plan tests => 6;
        is(
            ( binsearch_pos { $a cmp $b } 'ape', @strings ), 0,
            "binsearch_pos (cmp): Found at position 0."
        );
        is(
            ( binsearch_pos { $a cmp $b } 'ant', @strings ), 0,
            "binsearch_pos (cmp): Insert at position 0."
        );
        is(
            ( binsearch_pos { $a cmp $b } 'bear', @strings ), 2,
            "binsearch_pos (cmp): Found at position 2."
        );
        is(
            ( binsearch_pos { $a cmp $b } 'bafoon', @strings ), 1,
            "binsearch_pos (cmp): Insert at position 1."
        );
        is(
            ( binsearch_pos { $a cmp $b } 'dog', @strings ), 4,
            "binsearch_pos (cmp): Found at last position."
        );
        is(
            ( binsearch_pos { $a cmp $b } 'zebra', @strings ), 5,
            "binsearch_pos (cmp): Insert after last position."
        );
        done_testing();
};

done_testing();

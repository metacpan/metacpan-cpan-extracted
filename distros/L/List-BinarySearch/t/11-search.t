#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN{
  # Force pure-Perl testing.
  $ENV{List_BinarySearch_PP} = 1; ## no critic (local)
}

use List::BinarySearch qw( :all );

local( $a, $b ) = ( $a, $b );

my @integers    = ( 100, 200, 300, 400, 500 );
my @even_length = ( 100, 200, 300, 400, 500, 600 );
my @non_unique  = ( 100, 200, 200, 400, 400, 400, 500, 500 );
my @strings      = qw( ape  bat  bear  cat  dog      );
my @data_structs = (
    [ 100, 'ape' ],
    [ 200, 'bat' ],
    [ 300, 'bear' ],
    [ 400, 'cat' ],
    [ 500, 'dog' ],
);

subtest "Numeric comparator tests (odd-length list)." => sub {
    plan tests => 5;
    for my $ix ( 0 .. $#integers ) {
        is( binsearch( sub { $a <=> $b }, $integers[$ix], @integers ),
            $ix,
            "binsearch:           Integer ($integers[$ix]) "
                . "found in position ($ix)."
        );
    }
    done_testing();
};

subtest "Even length list tests." => sub {
    plan tests => 8;
    for my $ix ( 0 .. $#even_length ) {
        is( binsearch( sub { $a <=> $b }, $even_length[$ix], @even_length ),
            $ix,
            "binsearch:           Even-list: ($even_length[$ix])"
                . " found at index ($ix)."
        );
    }
    is( binsearch( sub { $a <=> $b }, 700, @even_length ),
        undef,
        "binsearch:           undef returned in scalar "
            . "context if no numeric match."
    );
    my @array = binsearch( sub { $a <=> $b }, 350, @even_length );
    is( scalar @array,
        0,
        "binsearch:           Empty list returned in list context "
            . "if no numeric match."
    );
    done_testing();
};

subtest "Non-unique key tests (stable search guarantee)." => sub {
    plan tests => 3;
    is( binsearch( sub { $a <=> $b }, 200, @non_unique ),
        1,
        "binsearch:           First non-unique key of 200 found at 1." );
    is( binsearch( sub { $a <=> $b }, 400, @non_unique ),
        3,
        "binsearch:           First occurrence of 400 found at 3 "
            . "(odd index)."
    );

    is( binsearch( sub { $a <=> $b }, 500, @non_unique ),
        6,
        "binsearch:           First occurrence of 500 found at 6 "
            . "(even index)."
    );

    done_testing();
};

subtest "String default comparator tests." => sub {
    plan tests => 6;
    for my $ix ( 0 .. $#strings ) {
        is( binsearch( sub { $a cmp $b }, $strings[$ix], @strings ),
            $ix,
            "binsearch:           "
                . "Strings: ($strings[$ix]) found at index ($ix)."
        );
    }
    is( binsearch( sub { $a cmp $b }, 'dave', @strings ),
        undef,
        "binsearch:           undef returned in scalar "
            . "context for no string match."
    );
    done_testing();
};

subtest "Complex data structure testing with custom comparator." => sub {
    plan tests => 6;
    for my $ix ( 0 .. $#data_structs ) {
        is( binsearch( sub { $a <=> $b->[0] }, $data_structs[$ix][0], @data_structs ),
            $ix,
            "binsearch:           Custom comparator test for test "
                . " element $ix."
        );
    }
    is( binsearch( sub { $a <=> $b->[0] }, 900, @data_structs ),
        undef,
        "binsearch:           undef returned for no match with "
            . "custom comparator."
    );
    done_testing();
};

my @new_test = ( 100, 200, 300 );
my $found_ix = binsearch { $a <=> $b } 200, @new_test;
is( $found_ix, 1, 'binsearch used $a and $b to find 200 at position 1.' );
$found_ix = binsearch_pos { $a <=> $b } 200, @new_test;
is( $found_ix, 1, 'binsearch_pos returns correct found index.' );
$found_ix = binsearch_pos { $a <=> $b } 250, @new_test;
is( $found_ix, 2, 'binsearch_pos returns correct insertion point.' );



done_testing();

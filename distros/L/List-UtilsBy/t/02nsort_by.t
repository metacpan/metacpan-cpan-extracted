#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw( nsort_by rev_nsort_by );

is_deeply( [ nsort_by { } ], [], 'empty list' );

is_deeply( [ nsort_by { $_ } 1 ], [ 1 ], 'unit list' );

is_deeply( [ nsort_by { my $ret = $_; undef $_; $ret } 10 ], [ 10 ], 'localises $_' );

is_deeply( [ nsort_by { $_ } 20, 25 ], [ 20, 25 ], 'identity function no-op' );
is_deeply( [ nsort_by { $_ } 25, 20 ], [ 20, 25 ], 'identity function on $_' );

is_deeply( [ nsort_by { $_[0] } 30, 35 ], [ 30, 35 ], 'identity function on $_[0]' );

is_deeply( [ nsort_by { length $_ } "a", "bbb", "cc" ], [ "a", "cc", "bbb" ], 'length function' );

# List context would yield the matches and fail, scalar context would yield
# the count and be correct
is_deeply( [ nsort_by { () = m/(a)/g } "apple", "hello", "armageddon" ], [ "hello", "apple", "armageddon" ], 'scalar context' );

is_deeply( [ rev_nsort_by { length $_ } "a", "bbb", "cc" ], [ "bbb", "cc", "a" ], 'reverse sort length function' );

done_testing;

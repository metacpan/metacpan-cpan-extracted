#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw( zip_by );

is_deeply( [ zip_by { } ], [], 'empty list' );

is_deeply( [ zip_by { [ @_ ] } [ "a" ], [ "b" ], [ "c" ] ], [ [ "a", "b", "c" ] ], 'singleton lists' );

is_deeply( [ zip_by { [ @_ ] } [ "a", "b", "c" ] ], [ [ "a" ], [ "b" ], [ "c" ] ], 'narrow lists' );

is_deeply( [ zip_by { [ @_ ] } [ "a1", "a2" ], [ "b1", "b2" ] ], [ [ "a1", "b1" ], [ "a2", "b2" ] ], 'zip with []' );

is_deeply( [ zip_by { join ",", @_ } [ "a1", "a2" ], [ "b1", "b2" ] ], [ "a1,b1", "a2,b2" ], 'zip with join()' );

is_deeply( [ zip_by { [ @_ ] } [ 1 .. 3 ], [ 1 .. 2 ] ], [ [ 1, 1 ], [ 2, 2 ], [ 3, undef ] ], 'non-rectangular adds undef' );

is_deeply( { zip_by { @_ } [qw( one two three )], [ 1, 2, 3 ] }, { one => 1, two => 2, three => 3 }, 'itemfunc can return lists' );

done_testing;

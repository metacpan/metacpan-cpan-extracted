#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw( partition_by );

is_deeply( { partition_by { } }, {}, 'empty list' );

is_deeply( { partition_by { $_ } "a" }, { a => [ "a" ] }, 'unit list' );

is_deeply( { partition_by { my $ret = $_; undef $_; $ret } "a" }, { a => [ "a" ] }, 'localises $_' );

is_deeply( { partition_by { "all" } "a", "b" }, { all => [ "a", "b" ] }, 'constant function preserves order' );
is_deeply( { partition_by { "all" } "b", "a" }, { all => [ "b", "a" ] }, 'constant function preserves order' );

is_deeply( { partition_by { $_[0] } "b", "a" }, { a => [ "a" ], b => [ "b" ] }, 'identity function on $_[0]' );

is_deeply( { partition_by { length $_ } "a", "b", "cc", "dd", "eee" },
           { 1 => [ "a", "b" ], 2 => [ "cc", "dd" ], 3 => [ "eee" ] }, 'length function' );

done_testing;

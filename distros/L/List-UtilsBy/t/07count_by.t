#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw( count_by );

is_deeply( { count_by { } }, {}, 'empty list' );

is_deeply( { count_by { $_ } "a" }, { a => 1 }, 'unit list' );

is_deeply( { count_by { "all" } "a", "b" }, { all => 2 }, 'constant function' );

is_deeply( { count_by { $_[0] } "b", "a" }, { a => 1, b => 1 }, 'identity function on $_[0]' );

is_deeply( { count_by { length $_ } "a", "b", "cc", "dd", "eee" },
           { 1 => 2, 2 => 2, 3 => 1 }, 'length function' );

done_testing;

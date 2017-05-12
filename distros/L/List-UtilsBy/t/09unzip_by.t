#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw( unzip_by );

is_deeply( [ unzip_by { } ], [], 'empty list' );

is_deeply( [ unzip_by { $_ } "a", "b", "c" ], [ [ "a", "b", "c" ] ], 'identity function' );

is_deeply( [ unzip_by { $_, $_ } "a", "b", "c" ], [ [ "a", "b", "c" ], [ "a", "b", "c" ] ], 'clone function' );

is_deeply( [ unzip_by { m/(.)/g } "a1", "b2", "c3" ], [ [ "a", "b", "c" ], [ 1, 2, 3 ] ], 'regexp match function' );

is_deeply( [ unzip_by { m/(.)/g } "a", "b2", "c" ], [ [ "a", "b", "c" ], [ undef, 2, undef ] ], 'non-rectangular adds undef' );

done_testing;

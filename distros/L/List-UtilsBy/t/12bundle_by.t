#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw( bundle_by );

is_deeply( [ bundle_by { $_[0] } 1, (1, 2, 3) ], [ 1, 2, 3 ], 'bundle_by 1' );

is_deeply( [ bundle_by { $_[0] } 2, (1, 2, 3, 4) ], [ 1, 3 ], 'bundle_by 2 first' );
is_deeply( [ bundle_by { @_ } 2, (1, 2, 3, 4) ], [ 1, 2, 3, 4 ], 'bundle_by 2 all' );
is_deeply( [ bundle_by { [ @_ ] } 2, (1, 2, 3, 4) ], [ [ 1, 2 ], [ 3, 4 ] ], 'bundle_by 2 [all]' );

is_deeply( { bundle_by { uc $_[1] => $_[0] } 2, qw( a b c d ) }, { B => "a", D => "c" }, 'bundle_by 2 constructing hash' );

is_deeply( [ bundle_by { [ @_ ] } 2, (1, 2, 3) ], [ [ 1, 2 ], [ 3 ] ], 'bundle_by 2 yields short final bundle' );

done_testing;

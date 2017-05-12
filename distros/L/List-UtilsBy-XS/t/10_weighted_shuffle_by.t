use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw(weighted_shuffle_by);

is_deeply( [ weighted_shuffle_by { } ], [], 'empty list' );
is_deeply( [ weighted_shuffle_by { 1 } "a" ], [ "a" ], 'unit list' );

my @vals = weighted_shuffle_by { 1 } "a", "b", "c";
is_deeply( [ sort @vals ], [ "a", "b", "c" ], 'set of return values' );

@vals = weighted_shuffle_by { ord $_ } "a", "b", "c";
is_deeply( [ sort @vals ], [ "a", "b", "c" ], 'set of return values' );

done_testing;

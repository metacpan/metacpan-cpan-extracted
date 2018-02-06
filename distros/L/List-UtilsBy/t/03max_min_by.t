#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use List::UtilsBy qw(
   max_by nmax_by
   min_by nmin_by
   minmax_by nminmax_by
);

# max_by
{
   is_deeply( [ max_by {} ], [], 'empty list yields empty' );

   is_deeply( ( scalar max_by { $_ } 10 ), 10, 'unit list yields value in scalar context' );
   is_deeply( [ max_by { $_ } 10 ], [ 10 ], 'unit list yields unit list value' );

   is_deeply( ( scalar max_by { $_ } 10, 20 ), 20, 'identity function on $_' );
   is_deeply( ( scalar max_by { $_[0] } 10, 20 ), 20, 'identity function on $_[0]' );

   is_deeply( ( scalar max_by { length $_ } "a", "ccc", "bb" ), "ccc", 'length function' );

   is_deeply( ( scalar max_by { length $_ } "a", "ccc", "bb", "ddd" ), "ccc", 'ties yield first in scalar context' );
   is_deeply( [ max_by { length $_ } "a", "ccc", "bb", "ddd" ], [ "ccc", "ddd" ], 'ties yield all maximal in list context' );

   is_deeply( ( scalar nmax_by { $_ } 10, 20 ), 20, 'nmax_by alias' );
}

# min_by
{
   is_deeply( [ min_by {} ], [], 'empty list yields empty' );

   is_deeply( ( scalar min_by { $_ } 10 ), 10, 'unit list yields value in scalar context' );
   is_deeply( [ min_by { $_ } 10 ], [ 10 ], 'unit list yields unit list value' );

   is_deeply( ( scalar min_by { $_ } 10, 20 ), 10, 'identity function on $_' );
   is_deeply( ( scalar min_by { $_[0] } 10, 20 ), 10, 'identity function on $_[0]' );

   is_deeply( ( scalar min_by { length $_ } "a", "ccc", "bb" ), "a", 'length function' );

   is_deeply( ( scalar min_by { length $_ } "a", "ccc", "bb", "e" ), "a", 'ties yield first in scalar context' );
   is_deeply( [ min_by { length $_ } "a", "ccc", "bb", "ddd", "e" ], [ "a", "e" ], 'ties yield all minimal in list context' );

   is_deeply( ( scalar nmin_by { $_ } 10, 20 ), 10, 'nmin_by alias' );
}

# minmax_by
{
   is_deeply( [ minmax_by {} ], [], 'empty list yields empty' );

   is_deeply( [ minmax_by { $_ } 10 ], [ 10, 10, ], 'unit list yields value twice' );

   is_deeply( [ minmax_by { $_ } 10, 20, 30, 40, 50 ], [ 10, 50 ], 'identity function on $_' );
   is_deeply( [ minmax_by { $_[0] } 10, 20, 30, 40, 50 ], [ 10, 50 ], 'identity function on $_[0]' );

   is_deeply( [ minmax_by { $_ } 50, 40, 30, 20, 10 ], [ 10, 50 ], 'identity function on reversed input' );

   is_deeply( [ minmax_by { length $_ } "a", "ccc", "bb" ], [ "a", "ccc" ], 'length function' );

   is_deeply( [ nminmax_by { $_ } 10 ], [ 10, 10, ], 'nminmax_by alias' );
}

done_testing;

#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use List::Keywords 'all';

# Basic true/false testing
ok( !(all { $_ < 10 } 1 .. 20), 'not all list values below ten' );
ok(  (all { $_ < 10 } 1 .. 9), 'all list values below ten' );

# short-circuiting
{
   my @seen;
   all { push @seen, $_; $_ < 20 } 10, 20, 30, 40;
   is_deeply( \@seen, [ 10, 20 ], 'short-circuits after first false result' );
}

# stack discipline
{
   is_deeply( [ 1, 2, (all { $_ eq "x" } "x", "x"), 3, 4 ],
      [ 1, 2, 1, 3, 4 ], 'all() preserves stack discipline' );
}

done_testing;

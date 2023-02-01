#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use List::Keywords 'all';

# Basic true/false testing
ok( !(all { $_ < 10 } 1 .. 20), 'not all list values below ten' );
ok(  (all { $_ < 10 } 1 .. 9), 'all list values below ten' );

# all empty list is true
{
   my $invoked;
   ok( (all { $invoked } ()), 'all on empty list is true' );
   ok( !$invoked, 'all on empty list did not invoke block' );
}

# all failure yields false in list context
{
   my @ret;
   @ret = all { $_ > 10 } 1 .. 9;
   ok( !!@ret, 'all nothing yielded false in list context' );

   @ret = all { $_ > 10 } ();
   ok( !!@ret, 'all nothing yielded false in list context on empty input' );
}

# short-circuiting
{
   my @seen;
   all { push @seen, $_; $_ < 20 } 10, 20, 30, 40;
   is( \@seen, [ 10, 20 ], 'short-circuits after first false result' );
}

# stack discipline
{
   is( [ 1, 2, (all { $_ eq "x" } "x", "x"), 3, 4 ],
      [ 1, 2, 1, 3, 4 ], 'all() preserves stack discipline' );
}

# all my $x { BLOCK }
{
   ok( (all my $x { $x < 10 } 1 .. 9), 'list contains all values found by all my $x' );
}

done_testing;

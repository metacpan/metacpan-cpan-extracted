#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use List::Keywords 'any';

# Basic true/false testing
ok(  (any { $_ > 10 } 1 .. 20), 'list contains a value above ten' );
ok( !(any { $_ > 10 } 1 .. 9), 'list does not contain a value above ten' );

# any empty list is false
{
   my $invoked;
   my $ret = any { $invoked++ } ();
   ok( defined $ret, 'any on empty list is defined' );
   ok( !$ret, 'any on empty list is false' );
   ok( !$invoked, 'any on empty list did not invoke block' );
}

# any failure yields false in list context
{
   my @ret;
   @ret = any { $_ > 10 } 1 .. 9;
   ok( !!@ret, 'any nothing yielded false in list context' );

   @ret = any { $_ > 10 } ();
   ok( !!@ret, 'any nothing yielded false in list context on empty input' );
}

# short-circuiting
{
   my @seen;
   any { push @seen, $_; $_ > 10 } 10, 20, 30, 40;
   is( \@seen, [ 10, 20 ], 'short-circuits after first true result' );
}

# stack discipline
{
   is( [ 1, 2, (any { $_ eq "x" } "x", "y"), 3, 4 ],
      [ 1, 2, 1, 3, 4 ], 'any() preserves stack discipline' );
}

# any my $x { BLOCK }
{
   ok( (any my $x { $x > 10 } 1 .. 20), 'list contains a value found by any my $x' );
}

done_testing;

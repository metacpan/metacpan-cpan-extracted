#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use List::Keywords 'any';

# Basic true/false testing
ok(  (any { $_ > 10 } 1 .. 20), 'list contains a value above ten' );
ok( !(any { $_ > 10 } 1 .. 9), 'list does not contain a value above ten' );

# any empty list is false
{
   my $invoked;
   ok( !(any { $invoked++ } ()), 'any on empty list is false' );
   ok( !$invoked, 'any on empty list did not invoke block' );
}

# short-circuiting
{
   my @seen;
   any { push @seen, $_; $_ > 10 } 10, 20, 30, 40;
   is_deeply( \@seen, [ 10, 20 ], 'short-circuits after first true result' );
}

# stack discipline
{
   is_deeply( [ 1, 2, (any { $_ eq "x" } "x", "y"), 3, 4 ],
      [ 1, 2, 1, 3, 4 ], 'any() preserves stack discipline' );
}

done_testing;

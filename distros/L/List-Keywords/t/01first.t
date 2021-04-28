#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use List::Keywords 'first';

# Basic true/false testing
is( (first { $_ > 10 } 1 .. 20), 11, 'list contains a value above ten' );
ok( !(first { $_ > 10 } 1 .. 9), 'list does not contain a value above ten' );

# first empty list is undef
{
   my $invoked;
   my $ret = first { $invoked++ } ();
   ok( !defined $ret, 'first on empty list is not defined' );
   ok( !$invoked, 'first on empty list did not invoke block' );
}

# short-circuiting
{
   my @seen;
   first { push @seen, $_; $_ > 10 } 10, 20, 30, 40;
   is_deeply( \@seen, [ 10, 20 ], 'short-circuits after first true result' );
}

# stack discipline
{
   is_deeply( [ 1, 2, (first { $_ eq "x" } "x", "y"), 3, 4 ],
      [ 1, 2, "x", 3, 4 ], 'first() preserves stack discipline' );
}

done_testing;

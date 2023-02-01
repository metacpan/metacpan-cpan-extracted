#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Refcount;

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
   is( \@seen, [ 10, 20 ], 'short-circuits after first true result' );
}

# stack discipline
{
   is( [ 1, 2, (first { $_ eq "x" } "x", "y"), 3, 4 ],
      [ 1, 2, "x", 3, 4 ], 'first() preserves stack discipline' );
}

# first my $x { BLOCK }
{
   local $_ = "outer";
   my @dollarsmudge;

   is( (first my $x { push @dollarsmudge, $_; $x > 10 } 1 .. 20), 11,
      'list contains a value found by first my $x' );
   is( \@dollarsmudge, [ ("outer")x11 ],
      '$_ was untouched during first my $x block' );
}

# refcounts
{
   my $arr = [];
   is_oneref( $arr, '$arr has one reference before test' );

   my $result;

   $result = first { defined $_ } undef, $arr, undef;
   is_refcount( $arr, 2, '$arr has two references after first BLOCK' );

   $result = first my $x { defined $x } undef, $arr, undef;
   is_refcount( $arr, 2, '$arr has two references after first my $x BLOCK' );

   undef $result;
   is_oneref( $arr, '$arr has one reference at end of test' );
}

done_testing;

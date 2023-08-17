#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0 0.000148;  # is_refcount

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

# variable is aliased to input list; mutations are visible
{
   my @input;
   my $output;

   $output = first { ++$_ } @input = (1);
   is( $output, 2, 'result value sees modification of $_' );
   is( \@input, [ 2 ], 'input list sees modification of $_' );

   $output = first my $x { ++$x } @input = (1);
   is( $output, 2, 'result value sees modification of lexical $x' );
   is( \@input, [ 2 ], 'input list sees modification of lexical $x' );
}

# result is aliased to input list; mutations are visible
{
   my @input;

   sub incr { $_[0]++ }

   incr first { 1 } @input = (1);
   is( \@input, [ 2 ], 'result was aliased to input list of $_' );

   incr first my $x { 1 } @input = (1);
   is( \@input, [ 2 ], 'result was aliased to input list of lexical $x' );
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

# unimport
{
   no List::Keywords 'first';

   sub first { return "normal function" }

   is( first, "normal function", 'first() parses as a normal function call' );
}

done_testing;

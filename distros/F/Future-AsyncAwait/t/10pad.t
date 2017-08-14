#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

use List::Util qw( sum );

# single scalar
{
   async sub with_scalar
   {
      my $scalar = "true";
      await $_[0];
      return $scalar;
   }

   my $f1 = Future->new;
   my $fret = with_scalar( $f1 );

   ok( !$fret->is_ready, '$fret is not immediate with_scalar' );

   $f1->done;
   is( scalar $fret->get, "true", '$fret now ready after done' );
}

# single array
{
   async sub with_array
   {
      my @array = (1, 2, 3);
      await $_[0];
      return sum @array;
   }

   my $f1 = Future->new;
   my $fret = with_array( $f1 );

   ok( !$fret->is_ready, '$fret is not immediate with_array' );

   $f1->done;
   is( scalar $fret->get, 6, '$fret now ready after done' );
}

# outside
{
   my $capture = "outer";

   my $closure = async sub {
      await $_[0];
      return $capture;
   };

   my $f1 = Future->new;
   my $fret = $closure->( $f1 );

   $f1->done;
   is( scalar $fret->get, "outer", '$fret now ready after done for closure' );
}

# captured variables of nested subs
{
   async sub with_inner_subs
   {
      my @F = @_;

      my $captured = "A";
      my $subB = sub {
         $captured .= "B";
      };

      await $F[0];

      $subB->();

      $captured .= "C";

      my $subD = sub {
         $captured .= "D";
      };

      await $F[1];

      $subD->();

      $captured .= "E";

      return $captured;
   }

   my $f1 = Future->new;
   my $f2 = Future->new;
   my $fret = with_inner_subs( $f1, $f2 );

   $f1->done;
   $f2->done;
   is( scalar $fret->get, "ABCDE", '$fret now ready after done for inner subs' );
}

done_testing;

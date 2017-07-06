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

done_testing;

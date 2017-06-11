#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait qw( async );

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
   my $f2 = with_scalar( $f1 );

   ok( !$f2->is_ready, '$f2 is not immediate with_scalar' );

   $f1->done;
   is( scalar $f2->get, "true", '$f2 now ready after done' );
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
   my $f2 = with_array( $f1 );

   ok( !$f2->is_ready, '$f2 is not immediate with_array' );

   $f1->done;
   is( scalar $f2->get, 6, '$f2 now ready after done' );
}

done_testing;

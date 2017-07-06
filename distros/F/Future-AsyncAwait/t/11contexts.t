#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# if await in cond
{
   async sub with_if_cond
   {
      if( await $_[0] ) {
         return "true";
      }
      else {
         return "false";
      }
   }

   my $f1 = Future->new;
   my $fret = with_if_cond( $f1 );

   ok( !$fret->is_ready, '$fret not immediate with_if_cond' );

   $f1->done( 1 );
   is( scalar $fret->get, "true", '$fret now ready after done' );
}

# if await in body
{
   async sub with_if_body
   {
      if( $_[0] ) {
         return await $_[1];
      }
      else {
         return "immediate";
      }
   }

   my $f1 = Future->new;
   my $fret = with_if_body( 1, $f1 );

   $f1->done( "defer" );
   is( scalar $fret->get, "defer", '$fret now ready after done in if body' );

   $fret = with_if_body( 0, undef );

   is( scalar $fret->get, "immediate", '$fret now ready after done in if body immediate' );
}

# foreach LIST
# foreach @ARRAY
# foreach 'a..'c'
# foreach 1..3

done_testing;

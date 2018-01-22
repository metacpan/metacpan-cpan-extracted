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

# do await in body
{
   async sub with_do_body
   {
      return 1 + do {
         my $f = $_[0];
         await $f;
      };
   }

   my $f1 = Future->new;
   my $fret = with_do_body( $f1 );

   $f1->done( 10 );
   is( scalar $fret->get, 11, '$fret now ready after done in do body' );
}

# await in eval{}
{
   async sub with_eval
   {
      my $f = shift;

      local $@;
      my $ret = eval {
         await $f;
         return "tried";
      } or die $@;
      return "($ret)";
   }

   my $f1 = Future->new;
   my $fret = with_eval( $f1 );

   $f1->done;
   is( scalar $fret->get, "(tried)", '$fret now ready after done in eval' );
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# while await in body
{
   my @F = map { Future->new } 1 .. 3;

   async sub with_while_body
   {
      while( @F ) {
         await $F[0];
         shift @F;
      }
      return "end while";
   }

   my $fret = with_while_body();

   $F[0]->done;
   $F[0]->done;
   $F[0]->done;

   is( scalar $fret->get, "end while", '$fret now ready after while loop with body finishes' );
}

# while await in condition
{
   my @F = map { Future->new } 1 .. 3;

   async sub with_while_cond
   {
      while( await $F[0] ) {
         shift @F;
      }
      return "end while";
   }

   my $fret = with_while_cond();

   $F[0]->done( 1 );
   $F[0]->done( 1 );
   $F[0]->done( 0 );

   is( scalar $fret->get, "end while", '$fret now ready after while loop with cond finishes' );
}

# last inside while await
{
   my $f1 = Future->new;

   async sub with_while_last
   {
      while( 1 ) {
         await $f1;
         last;
      }
      return "end while";
   }

   my $fret = with_while_last();

   $f1->done;

   is( scalar $fret->get, "end while", '$fret now ready after while loop with last' );
}

# next inside while await
{
   my $f1 = Future->new;

   async sub with_while_next
   {
      my $continue = 1;
      while( $continue ) {
         await $f1;
         $continue = 0;
         next;
         die "Unreachable";
      }
      return "end while";
   }

   my $fret = with_while_next();

   $f1->done;

   is( scalar $fret->get, "end while", '$fret now ready after while loop with next' );
}

done_testing;

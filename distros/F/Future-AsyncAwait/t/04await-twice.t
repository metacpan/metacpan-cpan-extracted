#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

# await twice from function
{
   my @futures;
   sub another_f
   {
      push @futures, my $f = Future->new;
      return $f;
   }

   async sub wait_twice
   {
      await another_f();
      await another_f();
   }

   my $fret = wait_twice;
   ok( my $f1 = shift @futures, '$f1 created' );

   $f1->done;
   ok( my $f2 = shift @futures, '$f2 created' );

   $f2->done( "result" );

   is( scalar $fret->get, "result", '$fret->get from double await by func' );
}

# await twice from pad
{
   async sub wait_for_both
   {
      my ( $f1, $f2 ) = @_;
      return await( $f1 ) + await( $f2 );
   }

   my $f1 = Future->new;
   my $f2 = Future->new;

   my $fret = wait_for_both( $f1, $f2 );

   $f1->done( 12 );

   $f2->done( 34 );

   is( scalar $fret->get, 46, '$fret->get from double await by pad' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;

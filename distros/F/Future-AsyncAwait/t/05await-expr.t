#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

{
   async sub await_within_expr
   {
      return 1 + await( $_[0] ) + 3;
   }

   my $f1 = Future->new;
   my $fret = await_within_expr( $f1 );

   $f1->done( 2 );

   is( scalar $fret->get, 6, '$fret yields correct result for mid-expression await' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;

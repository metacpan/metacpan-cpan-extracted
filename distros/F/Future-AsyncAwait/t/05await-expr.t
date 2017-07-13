#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

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

done_testing;

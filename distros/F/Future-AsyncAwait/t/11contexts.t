#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait qw( async );

# if
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
   my $f2 = with_if_cond( $f1 );

   ok( !$f2->is_ready, '$f2 not immediate with_if_cond' );

   $f1->done( 1 );
   is( scalar $f2->get, "true", '$f2 now ready after done' );
}

# while
# foreach LIST
# foreach @ARRAY
# foreach 'a..'c'
# foreach 1..3

done_testing;

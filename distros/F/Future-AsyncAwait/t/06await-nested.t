#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# await through two nested async sub calls
# See also RT123062
{
   my $f = Future->new;

   async sub inner
   {
      await $f;
   }

   async sub outer
   {
      await inner();
   }

   my $fret = outer();
   $f->done( "value" );

   is( scalar $fret->get, "value", '$fret->get through two nested async subs' );
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

my $before;
my $after;

# next LABEL
{
   async sub with_next_label
   {
      my $f = shift;

      LABEL: foreach my $tmp (1) {
         await $f;
         next LABEL;
         fail( "unreachable" );
      }

      return "OK";
   }

   my $f = Future->new;
   my $fret = with_next_label( $f );
   $f->done;
   ok( $fret->get, 'next LABEL' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;

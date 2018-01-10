#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# creating a closure inside an async sub

# before await
{
   my $f1 = Future->new;
   my $sub;
   async sub closure_before
   {
      my $x;  # just to create a real closure
      $sub = sub { $x++; 123 };

      await $f1;
   }

   my $f = closure_before();

   $f1->done( 45 );
   is( $f->get, 45, 'result of async sub' );
   is( $sub->(), 123, 'result of closure before' );
}

# after await
{
   my $f1 = Future->new;
   my $sub;
   async sub closure_after
   {
      my $ret = await $f1;

      my $x;  # just to create a real closure
      $sub = sub { $x++; 123 };

      return $ret;
   }

   my $f = closure_after();

   $f1->done( 45 );
   is( $f->get, 45, 'result of async sub' );
   is( $sub->(), 123, 'result of closure after' );
}

done_testing;

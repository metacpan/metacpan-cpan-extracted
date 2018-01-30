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
      my $x = 44;  # just to create a real closure
      $sub = sub { $x++; 123 };

      $sub->();

      await $f1;

      return $x;
   }

   my $f = closure_before();

   $f1->done;
   is( $f->get, 45, 'result of async sub' );
   is( $sub->(), 123, 'result of closure before' );
}

# after await
{
   my $f1 = Future->new;
   my $sub;
   async sub closure_after
   {
      await $f1;

      my $x = 44;
      $sub = sub { $x++; 123 };

      $sub->();

      return $x;
   }

   my $f = closure_after();

   $f1->done;
   is( $f->get, 45, 'result of async sub' );
   is( $sub->(), 123, 'result of closure after' );
}

done_testing;

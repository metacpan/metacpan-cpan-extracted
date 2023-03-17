#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

$^V ge v5.24.0 or
   plan skip_all => "This test requires perl 5.24.0";

use Future;

use Future::AsyncAwait;

# RT130683
{
   my @waitf;

   async sub do_wait
   {
      push @waitf, my $f = Future->new;
      await $f;
   }

   async sub check_args
   {
      await do_wait;
      is( scalar @_, 9, 'Snail still has 9 values in it' )
         or diag( "Snail is: <@_>" );
   }

   async sub run
   {
      my @args = 1 .. 9;
      await check_args @args;
   }

   my $f = run();
   ( shift @waitf )->done;
   $f->get;
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

my $f;
my $failure;

async sub inner
{
   my $ret = await $f;
   die $failure if defined $failure;
   return $ret;
}

async sub outer
{
   await inner();
}

# await through two nested async sub calls
# See also RT123062
{
   $f = Future->new;

   my $fret = outer();
   $f->done( "value" );

   is( scalar $fret->get, "value", '$fret->get through two nested async subs' );
}

# die after double await
# See also RT126037
{
   $f = Future->new;

   my $fret = outer();
   $failure = "Oopsie\n";

   $f->done( "result" );

   is( scalar $fret->failure, "Oopsie\n", '$fret->failure through two nested async subs' );
}

# await through two nested async method calls
{
   my $f = Future->new;

   package TestObj {
      async sub inner {
         await $f;
      }

      async sub outer {
         my $mth = "inner";
         await shift->$mth;
      }
   }

   my $fret = TestObj->outer();
   $f->done( "value" );

   is( scalar $fret->get, "value", '$fret->get through two nested async methods' );
}

# await twice nested
{
   my @f;

   async sub f2
   {
      await $f[0];
   }

   async sub f1
   {
      await f2();
      await f2();
   }

   @f = map { Future->new } 1 .. 2;
   my $fret = f1();
   ( shift @f )->done( "result" ) while @f;

   is( scalar $fret->get, "result", '$fret->get through nested double wait' );
}

# nested failure
{
    my $f = Future->new;

    async sub func_fail {
        await $f;
    }
    async sub func_fail_wrap {
        await func_fail();
    }

    my $fret = func_fail_wrap();
    $f->fail("aiee\n");

    is( $fret->failure, "aiee\n", "nested fail" );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;

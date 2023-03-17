#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;
use Test::Future::Deferred;

use Future::AsyncAwait;

my $orig_cxstack_ix = Future::AsyncAwait::__cxstack_ix;

# Await immediate
{
   my $f = Future->done( "imm" );

   is( await $f, "imm", 'toplevel await immediate yields result' );
}

# Await deferred
{
   # We can't easily `await` a pending future, then complete it in the usual
   # way, because we get suspended. But a deferred version will work fine
   my $f = Test::Future::Deferred->done_later( "later" );

   is( await $f, "later", 'toplevel await deferred yields result' );
}

is( Future::AsyncAwait::__cxstack_ix, $orig_cxstack_ix,
   'cxstack_ix did not grow during the test' );

done_testing;

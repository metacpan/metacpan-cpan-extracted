#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Test::Future::Deferred;

# done
{
   my $f = Test::Future::Deferred->done_later( "result" );

   ok( !$f->is_done, '$f not yet ready' );
   is( scalar $f->get, "result", '$f->get yields result anyway' );
}

# fail
{
   my $f = Test::Future::Deferred->fail_later( "oops\n" );

   ok( !$f->is_failed, '$f not yet ready' );
   is( dies { $f->get }, "oops\n", '$f->get throws exception anyway' );
}

# failure
{
   my $f = Test::Future::Deferred->fail_later( "oops\n" );

   ok( !$f->is_failed, '$f not yet ready' );
   is( $f->failure, "oops\n", '$f->failure returns exception anyway' );
}

# flush
{
   my $f = Test::Future::Deferred->done_later( "later" );

   ok( !$f->is_done, '$f not yet ready' );
   Test::Future::Deferred->flush;
   ok( $f->is_done, '$f is ready after ->flush' );
}

done_testing;

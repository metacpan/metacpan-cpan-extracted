#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;

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
   is( exception { $f->get }, "oops\n", '$f->get throws exception anyway' );
}

# failure
{
   my $f = Test::Future::Deferred->fail_later( "oops\n" );

   ok( !$f->is_failed, '$f not yet ready' );
   is( $f->failure, "oops\n", '$f->failure returns exception anyway' );
}

done_testing;

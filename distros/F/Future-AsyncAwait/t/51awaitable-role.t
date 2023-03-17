#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

eval { require Role::Tiny; 1 } or
   plan skip_all => "No Role::Tiny";

use Future::AsyncAwait::Awaitable;

pass( "doesn't crash" );

package Test::NotAwaitable {
   require Role::Tiny::With;
   Role::Tiny::With->import;

   ::ok( !eval {
      with( "Future::AsyncAwait::Awaitable" );
   }, 'Test package is not Future::AsyncAwait::Awaitable' );
   # Possibly a fragile test, in case of changes of error message text
   ::like( $@, qr/^Can't apply Future::AsyncAwait::Awaitable to Test::NotAwaitable /,
      'exception from unapplicable role' );
}

done_testing;

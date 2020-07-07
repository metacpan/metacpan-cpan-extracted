#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

eval { require Role::Tiny; 1 } or
   plan skip_all => "No Role::Tiny";

use Future::AsyncAwait::Awaitable;

pass( "doesn't crash" );

package Test::NotAwaitable {
   require Role::Tiny::With;
   Role::Tiny::With->import;

   Test::More::ok( !eval {
      with( "Future::AsyncAwait::Awaitable" );
   }, 'Test package is not Future::AsyncAwait::Awaitable' );
   # Possibly a fragile test, in case of changes of error message text
   Test::More::like( $@, qr/^Can't apply Future::AsyncAwait::Awaitable to Test::NotAwaitable /,
      'exception from unapplicable role' );
}

done_testing;

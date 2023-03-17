#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

package SubclassOfFuture {
   use base qw( Future );
}

{
   use Future::AsyncAwait future_class => "SubclassOfFuture";
   BEGIN {
      # gutwrenching
      ok( defined $^H{"Future::AsyncAwait/future"}, '%^H is set inside block' );
   }

   async sub func { return 123 }
}

# Is %^H well-behaved?
{
   ok( !defined $^H{"Future::AsyncAwait/future"}, '%^H restored outside block' );
}

{
   my $f = func();

   isa_ok( $f, [ "SubclassOfFuture" ], 'result of async sub func' );

   is( $f->get, 123, '$f->get' );
}

done_testing;

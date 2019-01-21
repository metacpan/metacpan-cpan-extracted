#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

# immediate done ANON scalar
{
   my $func = async sub {
      return 5;
   };

   my $f = $func->();

   isa_ok( $f, "Future", '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is( scalar $f->get, 5, '$f->get' );
}

# immediate done named scalar
{
   async sub func_10 {
      return 10;
   };

   my $f = func_10();

   isa_ok( $f, "Future", '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is( scalar $f->get, 10, '$f->get' );
}

# immediate done list
{
   async sub func_list {
      return 1 .. 5
   };

   my $f = func_list();

   isa_ok( $f, "Future", '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is_deeply( [ $f->get ], [ 1 .. 5 ], '$f->get' );
}

# immediate fail
{
   async sub func_die
   {
      die "Failure\n";
   }

   my $f = func_die();

   isa_ok( $f, "Future", '$f' );

   ok( $f->is_ready, '$f is immediate' );
   is( scalar $f->failure, "Failure\n", '$f->failure' );
}

# immediate done list in list context
{
   my @ret = (async sub { return 1, 2, 3 })->( 4, 5, 6 );

   is( scalar @ret, 1, 'async sub returns 1 value in list context' ) or
      diag( "async sub returned <@ret>" );
   isa_ok( shift @ret, "Future", 'Single result was a Future' );
}

done_testing;

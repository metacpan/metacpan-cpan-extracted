#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait qw( async );

async sub identity
{
   await $_[0];
}

# scalar
{
   my $f1 = Future->done( "result" );
   my $f2 = identity( $f1 );

   isa_ok( $f2, "Future", 'identity() returns a Future' );

   ok( $f2->is_ready, '$f2 is immediate for done scalar' );
   is( scalar $f2->get, "result", '$f2->get for done scalar' );
}

# list
{
   my $f1 = Future->done( list => "goes", "here" );
   my $f2 = identity( $f1 );

   isa_ok( $f2, "Future", 'identity() returns a Future' );

   ok( $f2->is_ready, '$f2 is immediate for done list' );
   is_deeply( [ $f2->get ], [qw( list goes here )], '$f2->get for done list' );
}

# stack discipline test
{
   my $f1 = Future->done( 4, 5 );
   my $f2 = (async sub {
      1, 2, [ 3, await $f1, 6 ], 7, 8
   })->();

   is_deeply( [ $f2->get ],
              [ 1, 2, [ 3, 4, 5, 6 ], 7, 8 ],
              'async/await respects stack discipline' );
}

# failure
{
   my $f1 = Future->fail( "It failed\n" );
   my $f2 = identity( $f1 );

   isa_ok( $f2, "Future", 'identity() returns a Future' );

   ok( $f2->is_ready, '$f2 is immediate for fail' );
   is( $f2->failure, "It failed\n", '$f2->failure for fail' );
}

done_testing;

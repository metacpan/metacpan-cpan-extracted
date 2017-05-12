#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait qw( async );

my $before;
my $after;

async sub identity
{
   await $_[0];
}

# scalar
{
   my $f1 = Future->new;
   my $f2 = identity( $f1 );

   isa_ok( $f2, "Future", 'identity() returns a Future' ) and do {
      ok( !$f2->is_ready, '$f2 is not immediate for pending scalar' );
   };

   $f1->done( "result" );
   is( scalar $f2->get, "result", '$f2->get for scalar' );
}

# list
{
   my $f1 = Future->new;
   my $f2 = identity( $f1 );

   isa_ok( $f2, "Future", 'identity() returns a Future' );

   $f1->done( list => "goes", "here" );
   is_deeply( [ $f2->get ], [qw( list goes here )], '$f2->get for list' );
}

async sub makelist
{
   1, 2, [ 3, await $_[0], 6 ], 7, 8
}

# stack discipline test
{
   my $f1 = Future->new;
   my $f2 = makelist( $f1 );

   $f1->done( 4, 5 );

   is_deeply( [ $f2->get ],
              [ 1, 2, [ 3, 4, 5, 6 ], 7, 8 ],
              'async/await respects stack discipline' );
}

# failure
{
   my $f1 = Future->new;
   my $f2 = identity( $f1 );

   isa_ok( $f2, "Future", 'identity() returns a Future' );

   $f1->fail( "It failed\n" );

   is( $f2->failure, "It failed\n", '$f2->failure for fail' );
}

done_testing;

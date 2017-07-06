#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

async sub identity
{
   await $_[0];
}

# scalar
{
   my $f1 = Future->done( "result" );
   my $fret = identity( $f1 );

   isa_ok( $fret, "Future", 'identity() returns a Future' );

   ok( $fret->is_ready, '$fret is immediate for done scalar' );
   is( scalar $fret->get, "result", '$fret->get for done scalar' );
}

# list
{
   my $f1 = Future->done( list => "goes", "here" );
   my $fret = identity( $f1 );

   isa_ok( $fret, "Future", 'identity() returns a Future' );

   ok( $fret->is_ready, '$fret is immediate for done list' );
   is_deeply( [ $fret->get ], [qw( list goes here )], '$fret->get for done list' );
}

# stack discipline test
{
   my $f1 = Future->done( 4, 5 );
   my $fret = (async sub {
      1, 2, [ 3, await $f1, 6 ], 7, 8
   })->();

   is_deeply( [ $fret->get ],
              [ 1, 2, [ 3, 4, 5, 6 ], 7, 8 ],
              'async/await respects stack discipline' );
}

# failure
{
   my $f1 = Future->fail( "It failed\n" );
   my $fret = identity( $f1 );

   isa_ok( $fret, "Future", 'identity() returns a Future' );

   ok( $fret->is_ready, '$fret is immediate for fail' );
   is( $fret->failure, "It failed\n", '$fret->failure for fail' );
}

done_testing;

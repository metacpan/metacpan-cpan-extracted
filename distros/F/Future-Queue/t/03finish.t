#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Future;
use Future::Queue;

# push before shift
{
   my $queue = Future::Queue->new;

   $queue->push( "ITEM" );
   $queue->finish;

   my $f1 = $queue->shift;
   my $f2 = $queue->shift;

   is( $f1->result, "ITEM", '$f1->result' );
   is_deeply( [ $f2->result ], [], '$f2->result' );

   ok( !defined eval { $queue->push( "MORE" ) },
      '->push after ->finish is an error' );
   like( $@, qr/^Cannot ->push more items to a Future::Queue that has been finished /,
      'Exception from ->push after ->finish' );
}

# shift before push
{
   my $queue = Future::Queue->new;

   my $f1 = $queue->shift;
   my $f2 = $queue->shift;

   $queue->push( "ITEM" );
   $queue->finish;

   is( $f1->result, "ITEM", '$f1->result' );
   is_deeply( [ $f2->result ], [], '$f2->result' );
}

done_testing;

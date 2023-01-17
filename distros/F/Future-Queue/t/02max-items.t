#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Future;
use Future::Queue;

{
   my $queue = Future::Queue->new( max_items => 5 );

   $queue->push( $_ ) for 1 .. 5;

   my $push_f = $queue->push( 6 );

   ok( !$push_f->is_done, '$queue->push returned pending Future' );

   my $shift_f = $queue->shift;

   ok( $push_f->is_done, 'push future now done after shift' );
}

done_testing;

#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

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

# RT151010
{
   my $queue = Future::Queue->new( max_items => 5 );

   my @pushf = map { $queue->push( $_ ) } 'a' .. 'q';

   # Should not spinlock in deep recursion
   my @shiftf = map { $queue->shift_atmost( 2 ) } 1 .. 9;

   is( [ map { $_->state } @pushf ], [ ("done") x 17 ],
      'all push futures completed' );
   is( [ map { $_->state } @shiftf ], [ ("done") x 9 ],
      'all shift futures completed' );
}

done_testing;

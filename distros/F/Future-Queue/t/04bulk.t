#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;
use Future::Queue;

# bulk-push before shift
{
   my $queue = Future::Queue->new;

   $queue->push( qw( A B C ) );

   is( $queue->shift->result, "A", 'shift 1' );
   is( $queue->shift->result, "B", 'shift 2' );
   is( $queue->shift->result, "C", 'shift 3' );
}

# push before bulk-shift
{
   my $queue = Future::Queue->new;

   $queue->push( $_ ) for qw( A B C D );

   is( [ $queue->shift_atmost( 3 )->result ], [qw( A B C )],
      '->shift_atmost can yield multiple' );

   is( [ $queue->shift_atmost( 3 )->result ], [qw( D )],
      '->shift_atmost yields when non-empty' );

   ok( !$queue->shift_atmost( 3 )->is_ready,
      '->shift_atmost pending when empty' );
}

# shift before bulk-push
{
   my $queue = Future::Queue->new;

   my $f1 = $queue->shift;
   my $f2 = $queue->shift;
   my $f3 = $queue->shift;

   $queue->push( qw( A B C ) );

   is( $f1->result, "A", 'shift 1' );
   is( $f2->result, "B", 'shift 2' );
   is( $f3->result, "C", 'shift 3' );
}

# bulk-shift before push
{
   my $queue = Future::Queue->new;

   my $f1 = $queue->shift_atmost( 3 );
   my $f2 = $queue->shift_atmost( 3 );

   $queue->push( $_ ) for qw( A B C );

   is( [ $f1->result ], [qw( A )],
      'shift_atmost yielded first pushed item' );

   is( [ $f2->result ], [qw( B )],
      'shift_atmost again yielded second pushed item' );
}

# bulk-shift before bulk-push
{
   my $queue = Future::Queue->new;

   my $f1 = $queue->shift_atmost( 3 );
   my $f2 = $queue->shift_atmost( 3 );

   $queue->push( qw( A B C D ) );

   is( [ $f1->result ], [qw( A B C )],
      'shift_atmost yielded first three pushed items' );

   is( [ $f2->result ], [qw( D )],
      'shift_atmost again yielded remaining pushed item' );
}

# bulk-push with max_items
{
   my $queue = Future::Queue->new( max_items => 3 );

   my $push_f = $queue->push( qw( A B C D E ) );

   ok( !$push_f->is_done, 'bulk push not yet ready while over-size' );

   $queue->shift->result;
   ok( !$push_f->is_done, 'bulk push still not ready after first shift' );

   $queue->shift->result;

   ok( $push_f->is_done, 'bulk push ready after second shift' );
}

done_testing;

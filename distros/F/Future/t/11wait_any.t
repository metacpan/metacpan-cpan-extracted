#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Identity;
use Test::Refcount;

use Future;

# First done
{
   my $f1 = Future->new;
   my $f2 = Future->new;

   my $future = Future->wait_any( $f1, $f2 );
   is_oneref( $future, '$future has refcount 1 initially' );

   # Two refs; one lexical here, one in $future
   is_refcount( $f1, 2, '$f1 has refcount 2 after adding to ->wait_any' );
   is_refcount( $f2, 2, '$f2 has refcount 2 after adding to ->wait_any' );

   is_deeply( [ $future->pending_futures ],
              [ $f1, $f2 ],
              '$future->pending_futures before any ready' );

   is_deeply( [ $future->ready_futures ],
              [],
              '$future->done_futures before any ready' );

   my @on_ready_args;
   $future->on_ready( sub { @on_ready_args = @_ } );

   ok( !$future->is_ready, '$future not yet ready' );
   is( scalar @on_ready_args, 0, 'on_ready not yet invoked' );

   $f1->done( one => 1 );

   is_deeply( [ $future->pending_futures ],
              [],
              '$future->pending_futures after $f1 ready' );

   is_deeply( [ $future->ready_futures ],
              [ $f1, $f2 ],
              '$future->ready_futures after $f1 ready' );

   is_deeply( [ $future->done_futures ],
              [ $f1 ],
              '$future->done_futures after $f1 ready' );

   is_deeply( [ $future->cancelled_futures ],
              [ $f2 ],
              '$future->cancelled_futures after $f1 ready' );

   is( scalar @on_ready_args, 1, 'on_ready passed 1 argument' );
   identical( $on_ready_args[0], $future, 'Future passed to on_ready' );
   undef @on_ready_args;

   ok( $future->is_ready, '$future now ready after f1 ready' );
   is_deeply( [ $future->get ], [ one => 1 ], 'results from $future->get' );

   is_refcount( $future, 1, '$future has refcount 1 at end of test' );
   undef $future;

   is_refcount( $f1,   1, '$f1 has refcount 1 at end of test' );
   is_refcount( $f2,   1, '$f2 has refcount 1 at end of test' );
}

# First fails
{
   my $f1 = Future->new;
   my $f2 = Future->new;

   my $future = Future->wait_any( $f1, $f2 );

   $f1->fail( "It fails\n" );

   ok( $future->is_ready, '$future now ready after a failure' );

   is( $future->failure, "It fails\n", '$future->failure yields exception' );

   is( exception { $future->get }, "It fails\n", '$future->get throws exception' );

   ok( $f2->is_cancelled, '$f2 cancelled after a failure' );
}

# immediately done
{
   my $f1 = Future->done;

   my $future = Future->wait_any( $f1 );

   ok( $future->is_ready, '$future of already-ready sub already ready' );
}

# cancel propagation
{
   my $f1 = Future->new;
   my $c1;
   $f1->on_cancel( sub { $c1++ } );

   my $future = Future->wait_all( $f1 );

   $future->cancel;

   is( $c1, 1, '$future->cancel marks subs cancelled' );
}

# cancelled convergent
{
   my $f1 = Future->new;
   my $f2 = Future->new;

   my $future = Future->wait_any( $f1, $f2 );

   $f1->cancel;

   ok( !$future->is_ready, '$future not yet ready after first cancellation' );

   $f2->done( "result" );

   ok( $future->is_ready, '$future is ready' );

   is_deeply( [ $future->done_futures ],
              [ $f2 ],
              '->done_futures with cancellation' );
   is_deeply( [ $future->cancelled_futures ],
              [ $f1 ],
              '->cancelled_futures with cancellation' );

   my $f3 = Future->new;
   $future = Future->wait_any( $f3 );

   $f3->cancel;

   ok( $future->is_ready, '$future is ready after final cancellation' );

   like( scalar $future->failure, qr/ cancelled/, 'Failure mentions cancelled' );
}

# wait_any on none
{
   my $f = Future->wait_any( () );

   ok( $f->is_ready, 'wait_any on no Futures already done' );
   is( scalar $f->failure, "Cannot ->wait_any with no subfutures",
       '->get on empty wait_any is empty' );
}

done_testing;

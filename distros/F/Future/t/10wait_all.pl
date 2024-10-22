use v5.10;
use strict;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Future;

use constant FUTURE_HAS_CONVERGENT_ALSO => ( !defined $Future::XS::VERSION or $Future::XS::VERSION >= 0.13 );

{
   my $f1 = Future->new;
   my $f2 = Future->new;

   my $future = Future->wait_all( $f1, $f2 );
   is_oneref( $future, '$future has refcount 1 initially' );

   # Two refs; one lexical here, one in $future
   is_refcount( $f1, 2, '$f1 has refcount 2 after adding to ->wait_all' );
   is_refcount( $f2, 2, '$f2 has refcount 2 after adding to ->wait_all' );

   is( [ $future->pending_futures ],
              [ $f1, $f2 ],
              '$future->pending_futures before any ready' );

   is( [ $future->ready_futures ],
              [],
              '$future->done_futures before any ready' );

   my @on_ready_args;
   $future->on_ready( sub { @on_ready_args = @_ } );

   ok( !$future->is_ready, '$future not yet ready' );
   is( scalar @on_ready_args, 0, 'on_ready not yet invoked' );

   $f1->done( one => 1 );

   is( [ $future->pending_futures ],
       [ $f2 ],
       '$future->pending_futures after $f1 ready' );

   is( [ $future->ready_futures ],
       [ $f1 ],
       '$future->ready_futures after $f1 ready' );

   is( [ $future->done_futures ],
       [ $f1 ],
       '$future->done_futures after $f1 ready' );

   ok( !$future->is_ready, '$future still not yet ready after f1 ready' );
   is( scalar @on_ready_args, 0, 'on_ready not yet invoked' );

   $f2->done( two => 2 );

   is( scalar @on_ready_args, 1, 'on_ready passed 1 argument' );
   ref_is( $on_ready_args[0], $future, 'Future passed to on_ready' );
   undef @on_ready_args;

   ok( $future->is_ready, '$future now ready after f2 ready' );
   my @results = $future->result;
   ref_is( $results[0], $f1, 'Results[0] from $future->result is f1' );
   ref_is( $results[1], $f2, 'Results[1] from $future->result is f2' );
   undef @results;

   is( [ $future->pending_futures ],
       [],
       '$future->pending_futures after $f2 ready' );

   is( [ $future->ready_futures ],
       [ $f1, $f2 ],
       '$future->ready_futures after $f2 ready' );

   is( [ $future->done_futures ],
       [ $f1, $f2 ],
       '$future->done_futures after $f2 ready' );

   is_refcount( $future, 1, '$future has refcount 1 at end of test' );
   undef $future;

   is_refcount( $f1,   1, '$f1 has refcount 1 at end of test' );
   is_refcount( $f2,   1, '$f2 has refcount 1 at end of test' );
}

# immediately done
{
   my $f1 = Future->done;

   my $future = Future->wait_all( $f1 );

   ok( $future->is_ready, '$future of already-ready sub already ready' );
   my @results = $future->result;
   ref_is( $results[0], $f1, 'Results from $future->result of already ready' );
}

# one immediately done
{
   my $f1 = Future->done;
   my $f2 = Future->new;

   my $future = Future->wait_all( $f1, $f2 );

   ok( !$future->is_ready, '$future of partially-done subs not yet ready' );

   $f2->done;

   ok( $future->is_ready, '$future of completely-done subs already ready' );
   my @results = $future->result;
   ref_is( $results[0], $f1, 'Results from $future->result of already ready' );
}

# cancel propagation
{
   my $f1 = Future->new;
   my $c1;
   $f1->on_cancel( sub { $c1++ } );

   my $f2 = Future->new;
   my $c2;
   $f2->on_cancel( sub { $c2++ } );

   my $future = Future->wait_all( $f1, $f2 );

   $f2->done;

   $future->cancel;

   is( $c1, 1,     '$future->cancel marks subs cancelled' );
   is( $c2, undef, '$future->cancel ignores ready subs' );
}

# 'also' subs don't get cancelled
if( FUTURE_HAS_CONVERGENT_ALSO ) {
   my $falso = Future->new;
   my $calso;
   $falso->on_cancel( sub { $calso++ } );

   my $future = Future->wait_all( also => $falso );

   $future->cancel;

   is( $calso, undef, '$future->cancel does not cancel $falso' );
}

# cancelled convergent
{
   my $f1 = Future->new;
   my $f2 = Future->new;

   my $future = Future->wait_all( $f1, $f2 );

   $f1->done( "result" );
   $f2->cancel;

   ok( $future->is_ready, '$future of cancelled sub is ready after final cancellation' );

   is( [ $future->done_futures ],
       [ $f1 ],
       '->done_futures with cancellation' );
   is( [ $future->cancelled_futures ],
       [ $f2 ],
       '->cancelled_futures with cancellation' );
}

# wait_all on none
{
   my $f = Future->wait_all( () );

   ok( $f->is_ready, 'wait_all on no futures already done' );
   is( [ $f->result ], [], '->result on empty wait_all is empty' );
}

# With a cancelled subfuture (RT144459)
foreach ([ precancelled => 0 ], [ postcancelled => 1 ])
{
   my ( $title, $cancel_after ) = @$_;

   my $f1 = Future->new;
   my $f2 = Future->new;

   $f2->cancel if !$cancel_after;

   my $f = Future->wait_all( $f1, $f2 );

   $f2->cancel if $cancel_after;

   ok( !$f->is_ready, "wait_all is pending before f1 done for $title" );

   $f1->done;

   ok( $f->is_done, "wait_all now done after f1 done for $title" );
}

done_testing;

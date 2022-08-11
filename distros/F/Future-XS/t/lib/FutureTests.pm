package FutureTests;

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Identity;
use Test::Refcount;

use Exporter 'import';
our @EXPORT = qw(
   test_future_done
   test_future_fail
   test_future_cancel
   test_future_then
   test_future_else
   test_future_thenelse
   test_future_followedby
   test_future_catch
   test_future_transform
   test_future_wait_all
   test_future_wait_any
   test_future_needs_all
   test_future_needs_any
   test_future_label
);

sub test_future_done
{
   my ( $class ) = @_;

   # done
   {
      my $future = $class->new;

      ok( defined $future, '$future defined' );
      isa_ok( $future, $class, '$future' );
      is_oneref( $future, '$future has refcount 1 initially' );

      ok( !$future->is_ready, '$future not yet ready' );
      is( $future->state, "pending", '$future->state before done' );

      my @on_ready_args;
      identical( $future->on_ready( sub { @on_ready_args = @_ } ), $future, '->on_ready returns $future' );

      my @on_done_args;
      identical( $future->on_done( sub { @on_done_args = @_ } ), $future, '->on_done returns $future' );
      identical( $future->on_fail( sub { die "on_fail called for done future" } ), $future, '->on_fail returns $future' );

      identical( $future->done( result => "here" ), $future, '->done returns $future' );

      is( scalar @on_ready_args, 1, 'on_ready passed 1 argument' );
      identical( $on_ready_args[0], $future, 'Future passed to on_ready' );
      undef @on_ready_args;

      is_deeply( \@on_done_args, [ result => "here" ], 'Results passed to on_done' );

      ok( $future->is_ready, '$future is now ready' );
      ok( $future->is_done, '$future is done' );
      ok( !$future->is_failed, '$future is not failed' );
      is( $future->state, "done", '$future->state after done' );
      is_deeply( [ $future->result ], [ result => "here" ], 'Results from $future->result' );
      is( scalar $future->result, "result", 'Result from scalar $future->result' );

      is_oneref( $future, '$future has refcount 1 at end of test' );
   }

   # done chaining
   {
      my $future = $class->new;

      my $f1 = $class->new;
      my $f2 = $class->new;

      $future->on_done( $f1 );
      $future->on_ready( $f2 );

      my @on_done_args_1;
      $f1->on_done( sub { @on_done_args_1 = @_ } );
      my @on_done_args_2;
      $f2->on_done( sub { @on_done_args_2 = @_ } );

      $future->done( chained => "result" );

      is_deeply( \@on_done_args_1, [ chained => "result" ], 'Results chained via ->on_done( $f )' );
      is_deeply( \@on_done_args_2, [ chained => "result" ], 'Results chained via ->on_ready( $f )' );
   }

   # immediately done
   {
      my $future = $class->done( already => "done" );

      my @on_done_args;
      identical( $future->on_done( sub { @on_done_args = @_; } ), $future, '->on_done returns future for immediate' );
      my $on_fail;
      identical( $future->on_fail( sub { $on_fail++; } ), $future, '->on_fail returns future for immediate' );

      is_deeply( \@on_done_args, [ already => "done" ], 'Results passed to on_done for immediate future' );
      ok( !$on_fail, 'on_fail not invoked for immediate future' );

      my $f1 = $class->new;
      my $f2 = $class->new;

      $future->on_done( $f1 );
      $future->on_ready( $f2 );

      ok( $f1->is_ready, 'Chained ->on_done for immediate future' );
      ok( $f1->is_done, 'Chained ->on_done is done for immediate future' );
      is_deeply( [ $f1->result ], [ already => "done" ], 'Results from chained via ->on_done for immediate future' );
      ok( $f2->is_ready, 'Chained ->on_ready for immediate future' );
      ok( $f2->is_done, 'Chained ->on_ready is done for immediate future' );
      is_deeply( [ $f2->result ], [ already => "done" ], 'Results from chained via ->on_ready for immediate future' );
   }

   # references are not retained in results
   {
      my $guard = {};
      my $future = $class->new;

      is_oneref( $guard, '$guard has refcount 1 before ->done' );

      $future->done( $guard );

      is_refcount( $guard, 2, '$guard has refcount 2 before destroying $future' );

      undef $future;

      is_oneref( $guard, '$guard has refcount 1 at end of test' );
   }

   # references are not retained in callbacks
   {
      my $guard = {};
      my $future = $class->new;

      is_oneref( $guard, '$guard has refcount 1 before ->on_done' );

      $future->on_done( do { my $ref = $guard; sub { $ref = $ref } } );

      is_refcount( $guard, 2, '$guard has refcount 2 after ->on_done' );

      $future->done();

      is_oneref( $guard, '$guard has refcount 1 after ->done' );
   }
}

sub test_future_fail
{
   my ( $class ) = @_;

   # fail
   {
      my $future = $class->new;

      $future->on_done( sub { die "on_done called for failed future" } );
      my $failure;
      $future->on_fail( sub { ( $failure ) = @_; } );

      identical( $future->fail( "Something broke" ), $future, '->fail returns $future' );

      ok( $future->is_ready, '$future->fail marks future ready' );
      ok( !$future->is_done, '$future->fail does not mark future done' );
      ok( $future->is_failed, '$future->fail marks future as failed' );
      is( $future->state, "failed", '$future->state after fail' );

      is( scalar $future->failure, "Something broke", '$future->failure yields exception' );
      my $file = __FILE__;
      my $line = __LINE__ + 1;
      like( exception { $future->result }, qr/^Something broke at \Q$file line $line\E\.?\n$/, '$future->result throws exception' );

      is( $failure, "Something broke", 'Exception passed to on_fail' );
   }

   {
      my $future = $class->new;

      $future->fail( "Something broke", further => "details" );

      ok( $future->is_ready, '$future->fail marks future ready' );

      is( scalar $future->failure, "Something broke", '$future->failure yields exception' );
      is_deeply( [ $future->failure ], [ "Something broke", "further", "details" ],
            '$future->failure yields details in list context' );
   }

   # fail chaining
   {
      my $future = $class->new;

      my $f1 = $class->new;
      my $f2 = $class->new;

      $future->on_fail( $f1 );
      $future->on_ready( $f2 );

      my $failure_1;
      $f1->on_fail( sub { ( $failure_1 ) = @_ } );
      my $failure_2;
      $f2->on_fail( sub { ( $failure_2 ) = @_ } );

      $future->fail( "Chained failure" );

      is( $failure_1, "Chained failure", 'Failure chained via ->on_fail( $f )' );
      is( $failure_2, "Chained failure", 'Failure chained via ->on_ready( $f )' );
   }

   # immediately failed
   {
      my $future = $class->fail( "Already broken" );

      my $on_done;
      identical( $future->on_done( sub { $on_done++; } ), $future, '->on_done returns future for immediate' );
      my $failure;
      identical( $future->on_fail( sub { ( $failure ) = @_; } ), $future, '->on_fail returns future for immediate' );

      is( $failure, "Already broken", 'Exception passed to on_fail for already-failed future' );
      ok( !$on_done, 'on_done not invoked for immediately-failed future' );

      my $f1 = $class->new;
      my $f2 = $class->new;

      $future->on_fail( $f1 );
      $future->on_ready( $f2 );

      ok( $f1->is_ready, 'Chained ->on_done for immediate future' );
      is_deeply( [ $f1->failure ], [ "Already broken" ], 'Results from chained via ->on_done for immediate future' );
      ok( $f2->is_ready, 'Chained ->on_ready for immediate future' );
      is_deeply( [ $f2->failure ], [ "Already broken" ], 'Results from chained via ->on_ready for immediate future' );
   }

   # die
   {
      my $future = $class->new;

      $future->on_done( sub { die "on_done called for failed future" } );
      my $failure;
      $future->on_fail( sub { ( $failure ) = @_; } );

      my $file = __FILE__;
      my $line = __LINE__+1;
      identical( $future->die( "Something broke" ), $future, '->die returns $future' );

      ok( $future->is_ready, '$future->die marks future ready' );

      is( scalar $future->failure, "Something broke at $file line $line\n", '$future->failure yields exception' );
      is( exception { $future->result }, "Something broke at $file line $line\n", '$future->result throws exception' );

      is( $failure, "Something broke at $file line $line\n", 'Exception passed to on_fail' );
   }

   # references are not retained
   {
      my $guard = {};

      my $future = $class->new;

      is_oneref( $guard, '$guard has refcount 1 before ->done' );

      $future->fail( "Oops" => $guard );

      is_refcount( $guard, 2, '$guard has refcount 2 before destroying $future' );

      undef $future;

      is_oneref( $guard, '$guard has refcount 1 at end of test' );
   }

   # references are not retained in callbacks
   {
      my $guard = {};
      my $future = $class->new;

      is_oneref( $guard, '$guard has refcount 1 before ->on_fail' );

      $future->on_fail( do { my $ref = $guard; sub { $ref = $ref } } );

      is_refcount( $guard, 2, '$guard has refcount 2 after ->on_fail' );

      $future->fail( "Oops" );

      is_oneref( $guard, '$guard has refcount 1 after ->fail' );
   }
}

sub test_future_cancel
{
   my ( $class ) = @_;

   # cancel
   {
      my $future = $class->new;

      my $cancelled;

      identical( $future->on_cancel( sub { $cancelled .= "1" } ), $future, '->on_cancel returns $future' );
      $future->on_cancel( sub { $cancelled .= "2" } );

      my $ready;
      $future->on_ready( sub { $ready++ if shift->is_cancelled } );

      $future->on_done( sub { die "on_done called for cancelled future" } );
      $future->on_fail( sub { die "on_fail called for cancelled future" } );

      $future->on_ready( my $ready_f = $class->new );
      $future->on_done( my $done_f = $class->new );
      $future->on_fail( my $fail_f = $class->new );

      $future->cancel;

      ok( $future->is_ready, '$future->cancel marks future ready' );

      ok( $future->is_cancelled, '$future->cancelled now true' );
      is( $cancelled, "21",      '$future cancel blocks called in reverse order' );

      is( $ready, 1, '$future on_ready still called by cancel' );

      ok( $ready_f->is_cancelled, 'on_ready chained future cnacelled after cancel' );
      ok( !$done_f->is_ready, 'on_done chained future not ready after cancel' );
      ok( !$fail_f->is_ready, 'on_fail chained future not ready after cancel' );
      is( $future->state, "cancelled", '$future->state after ->cancel' );

      like( exception { $future->result }, qr/cancelled/, '$future->result throws exception by cancel' );

      is( exception { $future->cancel }, undef,
         '$future->cancel a second time is OK' );

      $done_f->cancel;
      $fail_f->cancel;
   }

   # immediately cancelled
   {
      my $future = $class->new;
      $future->cancel;

      my $ready_called;
      $future->on_ready( sub { $ready_called++ } );
      my $done_called;
      $future->on_done( sub { $done_called++ } );
      my $fail_called;
      $future->on_fail( sub { $fail_called++ } );

      $future->on_ready( my $ready_f = $class->new );
      $future->on_done( my $done_f = $class->new );
      $future->on_fail( my $fail_f = $class->new );

      is( $ready_called, 1, 'on_ready invoked for already-cancelled future' );
      ok( !$done_called, 'on_done not invoked for already-cancelled future' );
      ok( !$fail_called, 'on_fail not invoked for already-cancelled future' );

      ok( $ready_f->is_cancelled, 'on_ready chained future cnacelled for already-cancelled future' );
      ok( !$done_f->is_ready, 'on_done chained future not ready for already-cancelled future' );
      ok( !$fail_f->is_ready, 'on_fail chained future not ready for already-cancelled future' );

      $done_f->cancel;
      $fail_f->cancel;
   }

   # cancel chaining
   {
      my $f1 = $class->new;
      my $f2 = $class->new;
      my $f3 = $class->new;

      $f1->on_cancel( $f2 );
      $f1->on_cancel( $f3 );

      is_oneref( $f1, '$f1 has refcount 1 after on_cancel chaining' );
      is_refcount( $f2, 2, '$f2 has refcount 2 after on_cancel chaining' );
      is_refcount( $f3, 2, '$f3 has refcount 2 after on_cancel chaining' );

      $f3->done;
      is_oneref( $f3, '$f3 has refcount 1 after done in cancel chain' );

      my $cancelled;
      $f2->on_cancel( sub { $cancelled++ } );

      $f1->cancel;
      is( $cancelled, 1, 'Chained cancellation' );
   }

   # ->done on cancelled
   {
      my $f = $class->new;
      $f->cancel;

      ok( eval { $f->done( "ignored" ); 1 }, '->done on cancelled future is ignored' );
      ok( eval { $f->fail( "ignored" ); 1 }, '->fail on cancelled future is ignored' );
   }

   # without_cancel
   {
      my $f1 = $class->new;
      is_oneref( $f1, '$f1 has single reference initially' );

      my $f2 = $f1->without_cancel;
      is_refcount( $f1, 2, '$f1 has two references after ->without_cancel' );

      $f2->cancel;
      ok( !$f1->is_cancelled, '$f1 not cancelled just because $f2 is' );

      my $f3 = $f1->without_cancel;
      $f1->done( "result" );

      ok( $f3->is_ready, '$f3 ready when $f1 is' );
      is_deeply( [ $f3->result ], [ "result" ], 'result of $f3' );
      is_oneref( $f1, '$f1 has one reference after done' );

      $f1 = $class->new;
      $f2 = $f1->without_cancel;

      $f1->cancel;
      ok( $f2->is_cancelled, '$f1 cancelled still cancels $f2' );
   }

   # references are not retained in callbacks
   {
      my $guard = {};
      my $future = $class->new;

      is_oneref( $guard, '$guard has refcount 1 before ->on_cancel' );

      $future->on_cancel( do { my $ref = $guard; sub { $ref = $ref } } );

      is_refcount( $guard, 2, '$guard has refcount 2 after ->on_cancel' );

      $future->cancel;

      is_oneref( $guard, '$guard has refcount 1 after ->cancel' );
   }
}

sub test_future_then
{
   my ( $class ) = @_;

   # then success
   {
      my $f1 = $class->new;

      my $f2;
      my $fseq = $f1->then(
         sub {
            is( $_[0], "f1 result", 'then done block passed result of $f1' );
            return $f2 = $class->new;
         }
      );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );

      ok( !$f2, '$f2 not yet defined before $f1 done' );

      $f1->done( "f1 result" );

      ok( defined $f2, '$f2 now defined after $f1 done' );

      undef $f1;
      is_oneref( $fseq, '$fseq has refcount 1 after $f1 done and dropped' );

      ok( !$fseq->is_ready, '$fseq not yet done before $f2 done' );

      $f2->done( results => "here" );

      ok( $fseq->is_ready, '$fseq is done after $f2 done' );
      is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );

      undef $f2;
      is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   }

   # then failure in f1
   {
      my $f1 = $class->new;

      my $fseq = $f1->then(
         sub { die "then of failed future should not be invoked" }
      );

      $f1->fail( "A failure\n" );

      ok( $fseq->is_ready, '$fseq is now ready after $f1 fail' );

      is( scalar $fseq->failure, "A failure\n", '$fseq fails when $f1 fails' );
   }

   # then failure in f2
   {
      my $f1 = $class->new;

      my $f2;
      my $fseq = $f1->then(
         sub { return $f2 = $class->new }
      );

      $f1->done;
      $f2->fail( "Another failure\n" );

      ok( $fseq->is_ready, '$fseq is now ready after $f2 fail' );

      is( scalar $fseq->failure, "Another failure\n", '$fseq fails when $f2 fails' );
   }

   # code dies
   {
      my $f1 = $class->new;

      my $fseq = $f1->then( sub {
         die "It fails\n";
      } );

      ok( !defined exception { $f1->done }, 'exception not propagated from done call' );

      ok( $fseq->is_ready, '$fseq is ready after code exception' );
      is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception' );
   }

   # immediately done
   {
      my $f1 = $class->done( "Result" );

      my $f2;
      my $fseq = $f1->then(
         sub { return $f2 = $class->new }
      );

      ok( defined $f2, '$f2 defined for immediate done' );

      $f2->done( "Final" );

      ok( $fseq->is_ready, '$fseq already ready for immediate done' );
      is( scalar $fseq->result, "Final", '$fseq->result for immediate done' );
   }

   # immediately fail
   {
      my $f1 = $class->fail( "Failure\n" );

      my $fseq = $f1->then(
         sub { die "then of immediately-failed future should not be invoked" }
      );

      ok( $fseq->is_ready, '$fseq already ready for immediate fail' );
      is( scalar $fseq->failure, "Failure\n", '$fseq->failure for immediate fail' );
   }

   # done fallthrough
   {
      my $f1 = $class->new;
      my $fseq = $f1->then;

      $f1->done( "fallthrough result" );

      ok( $fseq->is_ready, '$fseq is ready' );
      is( scalar $fseq->result, "fallthrough result", '->then done fallthrough' );
   }

   # fail fallthrough
   {
      my $f1 = $class->new;
      my $fseq = $f1->then;

      $f1->fail( "fallthrough failure\n" );

      ok( $fseq->is_ready, '$fseq is ready' );
      is( scalar $fseq->failure, "fallthrough failure\n", '->then fail fallthrough' );
   }

   # then cancel
   {
      my $f1 = $class->new;
      my $fseq = $f1->then( sub { die "then done of cancelled future should not be invoked" } );

      $fseq->cancel;

      ok( $f1->is_cancelled, '$f1 is cancelled by $fseq cancel' );

      $f1 = $class->new;
      my $f2;
      $fseq = $f1->then( sub { return $f2 = $class->new } );

      $f1->done;
      $fseq->cancel;

      ok( $f2->is_cancelled, '$f2 cancelled by $fseq cancel' );
   }

   # then dropping $fseq doesn't fail ->done
   {
      local $SIG{__WARN__} = sub {};

      my $f1 = $class->new;
      my $fseq = $f1->then( sub { return $class->done() } );

      undef $fseq;

      is( exception { $f1->done; }, undef,
         'Dropping $fseq does not cause $f1->done to die' );
   }
}

sub test_future_else
{
   my ( $class ) = @_;

   # else success
   {
      my $f1 = $class->new;

      my $fseq = $f1->else(
         sub { die "else of successful future should not be invoked" }
      );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );

      $f1->done( results => "here" );

      is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq succeeds when $f1 succeeds' );

      undef $f1;
      is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   }

   # else failure
   {
      my $f1 = $class->new;

      my $f2;
      my $fseq = $f1->else(
         sub {
            is( $_[0], "f1 failure\n", 'then fail block passed result of $f1' );
            return $f2 = $class->new;
         }
      );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );

      ok( !$f2, '$f2 not yet defined before $f1 fails' );

      $f1->fail( "f1 failure\n" );

      undef $f1;
      is_oneref( $fseq, '$fseq has refcount 1 after $f1 fail and dropped' );

      ok( defined $f2, '$f2 now defined after $f1 fails' );

      ok( !$fseq->is_ready, '$fseq not yet done before $f2 done' );

      $f2->done( results => "here" );

      ok( $fseq->is_ready, '$fseq is done after $f2 done' );
      is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );

      undef $f2;
      is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   }

   # Double failure
   {
      my $f1 = $class->new;

      my $f2;
      my $fseq = $f1->else(
         sub { return $f2 = $class->new }
      );

      $f1->fail( "First failure\n" );
      $f2->fail( "Another failure\n" );

      is( scalar $fseq->failure, "Another failure\n", '$fseq fails when $f2 fails' );
   }

   # code dies
   {
      my $f1 = $class->new;

      my $fseq = $f1->else( sub {
         die "It fails\n";
      } );

      ok( !defined exception { $f1->fail( "bork" ) }, 'exception not propagated from fail call' );

      ok( $fseq->is_ready, '$fseq is ready after code exception' );
      is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception' );
   }

   # immediate fail
   {
      my $f1 = $class->fail( "Failure\n" );

      my $f2;
      my $fseq = $f1->else(
         sub { return $f2 = $class->new }
      );

      ok( defined $f2, '$f2 defined for immediate fail' );

      $f2->fail( "Another failure\n" );

      ok( $fseq->is_ready, '$fseq already ready for immediate fail' );
      is( scalar $fseq->failure, "Another failure\n", '$fseq->failure for immediate fail' );
   }

   # immediate done
   {
      my $f1 = $class->done( "It works" );

      my $fseq = $f1->else(
         sub { die "else block invoked for immediate done future" }
      );

      ok( $fseq->is_ready, '$fseq already ready for immediate done' );
      is( scalar $fseq->result, "It works", '$fseq->result for immediate done' );
   }

   # else cancel
   {
      my $f1 = $class->new;
      my $fseq = $f1->else( sub { die "else of cancelled future should not be invoked" } );

      $fseq->cancel;

      ok( $f1->is_cancelled, '$f1 is cancelled by $fseq cancel' );

      $f1 = $class->new;
      my $f2;
      $fseq = $f1->else( sub { return $f2 = $class->new } );

      $f1->fail( "A failure\n" );
      $fseq->cancel;

      ok( $f2->is_cancelled, '$f2 cancelled by $fseq cancel' );
   }
}

sub test_future_thenelse
{
   my ( $class ) = @_;

   # then done
   {
      my $f1 = $class->new;

      my $fdone;
      my $fseq = $f1->then(
         sub {
            is( $_[0], "f1 result", '2-arg then done block passed result of $f1' );
            return $fdone = $class->new;
         },
         sub {
            die "then fail block should not be invoked";
         },
      );

      $f1->done( "f1 result" );

      ok( defined $fdone, '$fdone now defined after $f1 done' );

      $fdone->done( results => "here" );

      ok( $fseq->is_ready, '$fseq is done after $fdone done' );
      is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );
   }

   # then fail
   {
      my $f1 = $class->new;

      my $ffail;
      my $fseq = $f1->then(
         sub {
            die "then done block should not be invoked";
         },
         sub {
            is( $_[0], "The failure\n", '2-arg then fail block passed failure of $f1' );
            return $ffail = $class->new;
         },
      );

      $f1->fail( "The failure\n" );

      ok( defined $ffail, '$ffail now defined after $f1 fail' );

      $ffail->done( fallback => "result" );

      ok( $fseq->is_ready, '$fseq is done after $ffail fail' );
      is_deeply( [ $fseq->result ], [ fallback => "result" ], '$fseq->result returns results' );
   }

   # then done fails doesn't trigger fail block
   {
      my $f1 = $class->new;

      my $fdone;
      my $fseq = $f1->then(
         sub {
            $fdone = $class->new;
         },
         sub {
            die "then fail block should not be invoked";
         },
      );

      $f1->done( "Done" );
      $fdone->fail( "The failure\n" );

      ok( $fseq->is_ready, '$fseq is ready after $fdone fail' );
      ok( scalar $fseq->failure, '$fseq failed after $fdone fail' );
   }
}

sub test_future_followedby
{
   my ( $class ) = @_;

   {
      my $f1 = $class->new;

      my $called = 0;
      my $fseq = $f1->followed_by( sub {
         $called++;
         identical( $_[0], $f1, 'followed_by block passed $f1' );
         return $_[0];
      } );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );
      # Two refs; one in lexical $f1, one in $fseq's cancellation closure
      is_refcount( $f1, 2, '$f1 has refcount 2 initially' );

      is( $called, 0, '$called before $f1 done' );

      $f1->done( results => "here" );

      is( $called, 1, '$called after $f1 done' );

      ok( $fseq->is_ready, '$fseq is done after $f1 done' );
      is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );

      is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
      is_oneref( $f1, '$f1 has refcount 1 before EOF' );
   }

   {
      my $f1 = $class->new;

      my $called = 0;
      my $fseq = $f1->followed_by( sub {
         $called++;
         identical( $_[0], $f1, 'followed_by block passed $f1' );
         return $_[0];
      } );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );

      is( $called, 0, '$called before $f1 done' );

      $f1->fail( "failure\n" );

      is( $called, 1, '$called after $f1 failed' );

      ok( $fseq->is_ready, '$fseq is ready after $f1 failed' );
      is_deeply( [ $fseq->failure ], [ "failure\n" ], '$fseq->failure returns failure' );

      is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   }

   # code dies
   {
      my $f1 = $class->new;

      my $fseq = $f1->followed_by( sub {
         die "It fails\n";
      } );

      ok( !defined exception { $f1->done }, 'exception not propagated from code call' );

      ok( $fseq->is_ready, '$fseq is ready after code exception' );
      is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception' );
   }

   # Cancellation
   {
      my $f1 = $class->new;

      my $fseq = $f1->followed_by(
         sub { die "followed_by of cancelled future should not be invoked" }
      );

      $fseq->cancel;

      ok( $f1->is_cancelled, '$f1 cancelled by $fseq->cancel' );

      $f1 = $class->new;
      my $f2 = $class->new;

      $fseq = $f1->followed_by( sub { $f2 } );

      $f1->done;
      $fseq->cancel;

      ok( $f2->is_cancelled, '$f2 cancelled by $fseq->cancel' );

      $f1 = $class->done;
      $f2 = $class->new;

      $fseq = $f1->followed_by( sub { $f2 } );

      $fseq->cancel;

      ok( $f2->is_cancelled, '$f2 cancelled by $fseq->cancel on $f1 immediate' );
   }

   # immediately done
   {
      my $f1 = $class->done;

      my $called = 0;
      my $fseq = $f1->followed_by(
         sub { $called++; return $_[0] }
      );

      is( $called, 1, 'followed_by block invoked immediately for already-done' );
   }

   # immediately done
   {
      my $f1 = $class->fail("Failure\n");

      my $called = 0;
      my $fseq = $f1->followed_by(
         sub { $called++; return $_[0] }
      );

      is( $called, 1, 'followed_by block invoked immediately for already-failed' );
   }

   # immediately code dies
   {
      my $f1 = $class->done;

      my $fseq;

      ok( !defined exception {
         $fseq = $f1->followed_by( sub {
            die "It fails\n";
         } );
      }, 'exception not propagated from ->followed_by on immediate' );

      ok( $fseq->is_ready, '$fseq is ready after code exception on immediate' );
      is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception on immediate' );
   }
}

sub test_future_catch
{
   my ( $class ) = @_;

   # catch success
   {
      my $f1 = $class->new;

      my $fseq = $f1->catch(
         test => sub { die "catch of successful future should not be invoked" },
      );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );

      $f1->done( results => "here" );

      is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq succeeds when $f1 succeeds' );

      undef $f1;
      is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   }

   # catch matching failure
   {
      my $f1 = $class->new;

      my $f2;
      my $fseq = $f1->catch(
         test => sub {
            is( $_[0], "f1 failure\n", 'catch block passed result of $f1' );
            return $f2 = $class->done;
         },
      );

      ok( defined $fseq, '$fseq defined' );
      isa_ok( $fseq, $class, '$fseq' );

      is_oneref( $fseq, '$fseq has refcount 1 initially' );

      $f1->fail( "f1 failure\n", test => );

      undef $f1;
      is_oneref( $fseq, '$fseq has refcount 1 after $f1 fail and dropped' );

      ok( defined $f2, '$f2 now defined after $f1 fails' );

      ok( $fseq->is_ready, '$fseq is done after $f2 done' );
   }

   # catch non-matching failure
   {
      my $f1 = $class->new;

      my $fseq = $f1->catch(
         test => sub { die "catch of non-matching Failure should not be invoked" },
      );

      $f1->fail( "f1 failure\n", different => );

      ok( $fseq->is_ready, '$fseq is done after $f1 fail' );
      is( scalar $fseq->failure, "f1 failure\n", '$fseq failure' );
   }

   # catch default handler
   {
      my $fseq = $class->fail( "failure", other => )
         ->catch(
            test => sub { die "'test' catch should not match" },
            sub { $class->done( default => "handler" ) },
         );

      is_deeply( [ $fseq->result ], [ default => "handler" ],
         '->catch accepts a default handler' );
   }

   # catch via 'then'
   {
      is( scalar ( $class->fail( "message", test => )
               ->then( sub { die "then &done should not be invoked" },
                  test => sub { $class->done( 1234 ) },
                  sub { die "then &fail should not be invoked" } )->result ),
         1234, 'catch semantics via ->then' );
   }
}

sub test_future_transform
{
   my ( $class ) = @_;

   # Result transformation
   {
      my $f1 = $class->new;

      my $future = $f1->transform(
         done => sub { result => @_ },
      );

      $f1->done( 1, 2, 3 );

      is_deeply( [ $future->result ], [ result => 1, 2, 3 ], '->transform result' );
   }

   # Failure transformation
   {
      my $f1 = $class->new;

      my $future = $f1->transform(
         fail => sub { "failure\n" => @_ },
      );

      $f1->fail( "something failed\n" );

      is_deeply( [ $future->failure ], [ "failure\n" => "something failed\n" ], '->transform failure' );
   }

   # code dies
   {
      my $f1 = $class->new;

      my $future = $f1->transform(
         done => sub { die "It fails\n" },
      );

      $f1->done;

      is_deeply( [ $future->failure ], [ "It fails\n" ], '->transform catches exceptions' );
   }

   # Cancellation
   {
      my $f1 = $class->new;

      my $cancelled;
      $f1->on_cancel( sub { $cancelled++ } );

      my $future = $f1->transform;

      $future->cancel;
      is( $cancelled, 1, '->transform cancel' );
   }
}

sub test_future_wait_all
{
   my ( $class ) = @_;

   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->wait_all( $f1, $f2 );
      is_oneref( $future, '$future has refcount 1 initially' );

      # Two refs; one lexical here, one in $future
      is_refcount( $f1, 2, '$f1 has refcount 2 after adding to ->wait_all' );
      is_refcount( $f2, 2, '$f2 has refcount 2 after adding to ->wait_all' );

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
                 [ $f2 ],
                 '$future->pending_futures after $f1 ready' );

      is_deeply( [ $future->ready_futures ],
                 [ $f1 ],
                 '$future->ready_futures after $f1 ready' );

      is_deeply( [ $future->done_futures ],
                 [ $f1 ],
                 '$future->done_futures after $f1 ready' );

      ok( !$future->is_ready, '$future still not yet ready after f1 ready' );
      is( scalar @on_ready_args, 0, 'on_ready not yet invoked' );

      $f2->done( two => 2 );

      is( scalar @on_ready_args, 1, 'on_ready passed 1 argument' );
      identical( $on_ready_args[0], $future, 'Future passed to on_ready' );
      undef @on_ready_args;

      ok( $future->is_ready, '$future now ready after f2 ready' );
      my @results = $future->result;
      identical( $results[0], $f1, 'Results[0] from $future->result is f1' );
      identical( $results[1], $f2, 'Results[1] from $future->result is f2' );
      undef @results;

      is_deeply( [ $future->pending_futures ],
                 [],
                 '$future->pending_futures after $f2 ready' );

      is_deeply( [ $future->ready_futures ],
                 [ $f1, $f2 ],
                 '$future->ready_futures after $f2 ready' );

      is_deeply( [ $future->done_futures ],
                 [ $f1, $f2 ],
                 '$future->done_futures after $f2 ready' );

      is_refcount( $future, 1, '$future has refcount 1 at end of test' );
      undef $future;

      is_refcount( $f1,   1, '$f1 has refcount 1 at end of test' );
      is_refcount( $f2,   1, '$f2 has refcount 1 at end of test' );
   }

   # immediately done
   {
      my $f1 = $class->done;

      my $future = $class->wait_all( $f1 );

      ok( $future->is_ready, '$future of already-ready sub already ready' );
      my @results = $future->result;
      identical( $results[0], $f1, 'Results from $future->result of already ready' );
   }

   # one immediately done
   {
      my $f1 = $class->done;
      my $f2 = $class->new;

      my $future = $class->wait_all( $f1, $f2 );

      ok( !$future->is_ready, '$future of partially-done subs not yet ready' );

      $f2->done;

      ok( $future->is_ready, '$future of completely-done subs already ready' );
      my @results = $future->result;
      identical( $results[0], $f1, 'Results from $future->result of already ready' );
   }

   # cancel propagation
   {
      my $f1 = $class->new;
      my $c1;
      $f1->on_cancel( sub { $c1++ } );

      my $f2 = $class->new;
      my $c2;
      $f2->on_cancel( sub { $c2++ } );

      my $future = $class->wait_all( $f1, $f2 );

      $f2->done;

      $future->cancel;

      is( $c1, 1,     '$future->cancel marks subs cancelled' );
      is( $c2, undef, '$future->cancel ignores ready subs' );
   }

   # cancelled convergent
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->wait_all( $f1, $f2 );

      $f1->done( "result" );
      $f2->cancel;

      ok( $future->is_ready, '$future of cancelled sub is ready after final cancellation' );

      is_deeply( [ $future->done_futures ],
                 [ $f1 ],
                 '->done_futures with cancellation' );
      is_deeply( [ $future->cancelled_futures ],
                 [ $f2 ],
                 '->cancelled_futures with cancellation' );
   }

   # wait_all on none
   {
      my $f = $class->wait_all( () );

      ok( $f->is_ready, 'wait_all on no futures already done' );
      is_deeply( [ $f->result ], [], '->result on empty wait_all is empty' );
   }
}

sub test_future_wait_any
{
   my ( $class ) = @_;

   # First done
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->wait_any( $f1, $f2 );
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
      is_deeply( [ $future->result ], [ one => 1 ], 'results from $future->result' );

      is_refcount( $future, 1, '$future has refcount 1 at end of test' );
      undef $future;

      is_refcount( $f1,   1, '$f1 has refcount 1 at end of test' );
      is_refcount( $f2,   1, '$f2 has refcount 1 at end of test' );
   }

   # First fails
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->wait_any( $f1, $f2 );

      $f1->fail( "It fails\n" );

      ok( $future->is_ready, '$future now ready after a failure' );

      is( $future->failure, "It fails\n", '$future->failure yields exception' );

      is( exception { $future->result }, "It fails\n", '$future->result throws exception' );

      ok( $f2->is_cancelled, '$f2 cancelled after a failure' );
   }

   # immediately done
   {
      my $f1 = $class->done;

      my $future = $class->wait_any( $f1 );

      ok( $future->is_ready, '$future of already-ready sub already ready' );
   }

   # cancel propagation
   {
      my $f1 = $class->new;
      my $c1;
      $f1->on_cancel( sub { $c1++ } );

      my $future = $class->wait_all( $f1 );

      $future->cancel;

      is( $c1, 1, '$future->cancel marks subs cancelled' );
   }

   # cancelled convergent
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->wait_any( $f1, $f2 );

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

      my $f3 = $class->new;
      $future = $class->wait_any( $f3 );

      $f3->cancel;

      ok( $future->is_ready, '$future is ready after final cancellation' );

      like( scalar $future->failure, qr/ cancelled/, 'Failure mentions cancelled' );
   }

   # wait_any on none
   {
      my $f = $class->wait_any( () );

      ok( $f->is_ready, 'wait_any on no futures already done' );
      is( scalar $f->failure, "Cannot ->wait_any with no subfutures",
          '->result on empty wait_any is empty' );
   }
}

sub test_future_needs_all
{
   my ( $class ) = @_;

   # All done
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->needs_all( $f1, $f2 );
      is_oneref( $future, '$future has refcount 1 initially' );

      # Two refs; one lexical here, one in $future
      is_refcount( $f1, 2, '$f1 has refcount 2 after adding to ->needs_all' );
      is_refcount( $f2, 2, '$f2 has refcount 2 after adding to ->needs_all' );

      my $ready;
      $future->on_ready( sub { $ready++ } );

      ok( !$future->is_ready, '$future not yet ready' );

      $f1->done( one => 1 );
      $f2->done( two => 2 );

      is( $ready, 1, '$future is now ready' );

      ok( $future->is_ready, '$future now ready after f2 ready' );
      is_deeply( [ $future->result ], [ one => 1, two => 2 ], '$future->result after f2 ready' );

      is_refcount( $future, 1, '$future has refcount 1 at end of test' );
      undef $future;

      is_refcount( $f1, 1, '$f1 has refcount 1 at end of test' );
      is_refcount( $f2, 1, '$f2 has refcount 1 at end of test' );
   }

   # One fails
   {
      my $f1 = $class->new;
      my $f2 = $class->new;
      my $c2;
      $f2->on_cancel( sub { $c2++ } );

      my $future = $class->needs_all( $f1, $f2 );

      my $ready;
      $future->on_ready( sub { $ready++ } );

      ok( !$future->is_ready, '$future not yet ready' );

      $f1->fail( "It fails" );

      is( $ready, 1, '$future is now ready' );

      ok( $future->is_ready, '$future now ready after f1 fails' );
      is( $future->failure, "It fails", '$future->failure yields exception' );
      my $file = __FILE__;
      my $line = __LINE__ + 1;
      like( exception { $future->result }, qr/^It fails at \Q$file line $line\E\.?\n$/, '$future->result throws exception' );

      is( $c2, 1, 'Unfinished child future cancelled on failure' );

      is_deeply( [ $future->pending_futures ],
                 [],
                 '$future->pending_futures after $f1 failure' );

      is_deeply( [ $future->ready_futures ],
                 [ $f1, $f2 ],
                 '$future->ready_futures after $f1 failure' );

      is_deeply( [ $future->done_futures ],
                 [],
                 '$future->done_futures after $f1 failure' );

      is_deeply( [ $future->failed_futures ],
                 [ $f1 ],
                 '$future->failed_futures after $f1 failure' );

      is_deeply( [ $future->cancelled_futures ],
                 [ $f2 ],
                 '$future->cancelled_futures after $f1 failure' );
   }

   # immediately done
   {
      my $future = $class->needs_all( $class->done );

      ok( $future->is_ready, '$future of already-done sub already ready' );
   }

   # immediately fails
   {
      my $future = $class->needs_all( $class->fail("F1"), $class->done );

      ok( $future->is_ready, '$future of already-failed sub already ready' );
   }

   # cancel propagation
   {
      my $f1 = $class->new;
      my $c1;
      $f1->on_cancel( sub { $c1++ } );

      my $f2 = $class->new;
      my $c2;
      $f2->on_cancel( sub { $c2++ } );

      my $future = $class->needs_all( $f1, $f2 );

      $f2->done;

      $future->cancel;

      is( $c1, 1,     '$future->cancel marks subs cancelled' );
      is( $c2, undef, '$future->cancel ignores ready subs' );
   }

   # cancelled convergent
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->needs_all( $f1, $f2 );

      $f1->cancel;

      ok( $future->is_ready, '$future of cancelled sub is ready after first cancellation' );

      like( scalar $future->failure, qr/ cancelled/, 'Failure mentions cancelled' );
   }

   # needs_all on none
   {
      my $f = $class->needs_all( () );

      ok( $f->is_ready, 'needs_all on no futures already done' );
      is_deeply( [ $f->result ], [], '->result on empty needs_all is empty' );
   }
}

sub test_future_needs_any
{
   my ( $class ) = @_;

   # One done
   {
      my $f1 = $class->new;
      my $f2 = $class->new;
      my $c2;
      $f2->on_cancel( sub { $c2++ } );

      my $future = $class->needs_any( $f1, $f2 );
      is_oneref( $future, '$future has refcount 1 initially' );

      # Two refs; one lexical here, one in $future
      is_refcount( $f1, 2, '$f1 has refcount 2 after adding to ->needs_any' );
      is_refcount( $f2, 2, '$f2 has refcount 2 after adding to ->needs_any' );

      my $ready;
      $future->on_ready( sub { $ready++ } );

      ok( !$future->is_ready, '$future not yet ready' );

      $f1->done( one => 1 );

      is( $ready, 1, '$future is now ready' );

      ok( $future->is_ready, '$future now ready after f1 ready' );
      is_deeply( [ $future->result ], [ one => 1 ], 'results from $future->result' );

      is_deeply( [ $future->pending_futures ],
                 [],
                 '$future->pending_futures after $f1 done' );

      is_deeply( [ $future->ready_futures ],
                 [ $f1, $f2 ],
                 '$future->ready_futures after $f1 done' );

      is_deeply( [ $future->done_futures ],
                 [ $f1 ],
                 '$future->done_futures after $f1 done' );

      is_deeply( [ $future->failed_futures ],
                 [],
                 '$future->failed_futures after $f1 done' );

      is_deeply( [ $future->cancelled_futures ],
                 [ $f2 ],
                 '$future->cancelled_futures after $f1 done' );

      is_refcount( $future, 1, '$future has refcount 1 at end of test' );
      undef $future;

      is_refcount( $f1, 1, '$f1 has refcount 1 at end of test' );
      is_refcount( $f2, 1, '$f2 has refcount 1 at end of test' );

      is( $c2, 1, 'Unfinished child future cancelled on failure' );
   }

   # One fails
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->needs_any( $f1, $f2 );

      my $ready;
      $future->on_ready( sub { $ready++ } );

      ok( !$future->is_ready, '$future not yet ready' );

      $f1->fail( "Partly fails" );

      ok( !$future->is_ready, '$future not yet ready after $f1 fails' );

      $f2->done( two => 2 );

      ok( $future->is_ready, '$future now ready after $f2 done' );
      is_deeply( [ $future->result ], [ two => 2 ], '$future->result after $f2 done' );

      is_deeply( [ $future->done_futures ],
                 [ $f2 ],
                 '$future->done_futures after $f2 done' );

      is_deeply( [ $future->failed_futures ],
                 [ $f1 ],
                 '$future->failed_futures after $f2 done' );
   }

   # All fail
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->needs_any( $f1, $f2 );

      my $ready;
      $future->on_ready( sub { $ready++ } );

      ok( !$future->is_ready, '$future not yet ready' );

      $f1->fail( "Partly fails" );

      $f2->fail( "It fails" );

      is( $ready, 1, '$future is now ready' );

      ok( $future->is_ready, '$future now ready after f2 fails' );
      is( $future->failure, "It fails", '$future->failure yields exception' );
      my $file = __FILE__;
      my $line = __LINE__ + 1;
      like( exception { $future->result }, qr/^It fails at \Q$file line $line\E\.?\n$/, '$future->result throws exception' );

      is_deeply( [ $future->failed_futures ],
                 [ $f1, $f2 ],
                 '$future->failed_futures after all fail' );
   }

   # immediately done
   {
      my $future = $class->needs_any( $class->fail("F1"), $class->done );

      ok( $future->is_ready, '$future of already-done sub already ready' );
   }

   # immediately fails
   {
      my $future = $class->needs_any( $class->fail("F1") );

      ok( $future->is_ready, '$future of already-failed sub already ready' );
      $future->failure;
   }

   # cancel propagation
   {
      my $f1 = $class->new;
      my $c1;
      $f1->on_cancel( sub { $c1++ } );

      my $f2 = $class->new;
      my $c2;
      $f2->on_cancel( sub { $c2++ } );

      my $future = $class->needs_all( $f1, $f2 );

      $f2->fail( "booo" );

      $future->cancel;

      is( $c1, 1,     '$future->cancel marks subs cancelled' );
      is( $c2, undef, '$future->cancel ignores ready subs' );
   }

   # cancelled convergent
   {
      my $f1 = $class->new;
      my $f2 = $class->new;

      my $future = $class->needs_any( $f1, $f2 );

      $f1->cancel;

      ok( !$future->is_ready, '$future not yet ready after first cancellation' );

      $f2->done( "result" );

      is_deeply( [ $future->done_futures ],
                 [ $f2 ],
                 '->done_futures with cancellation' );
      is_deeply( [ $future->cancelled_futures ],
                 [ $f1 ],
                 '->cancelled_futures with cancellation' );

      my $f3 = $class->new;
      $future = $class->needs_any( $f3 );

      $f3->cancel;

      ok( $future->is_ready, '$future is ready after final cancellation' );

      like( scalar $future->failure, qr/ cancelled/, 'Failure mentions cancelled' );
   }

   # needs_any on none
   {
      my $f = $class->needs_any( () );

      ok( $f->is_ready, 'needs_any on no futures already done' );
      is( scalar $f->failure, "Cannot ->needs_any with no subfutures",
          '->result on empty needs_any is empty' );
   }
}

sub test_future_label
{
   my ( $class ) = @_;

   my $f = $class->new;

   identical( $f->set_label( "the label" ), $f, '->set_label returns $f' );

   is( $f->label, "the label", '->label returns the label' );

   $f->cancel;
}

0x55AA;

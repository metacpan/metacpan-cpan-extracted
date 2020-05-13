#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2020 -- leonerd@leonerd.org.uk

package IO::Async::LoopTests;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
   run_tests
);

use Test::More;
use Test::Fatal;
use Test::Metrics::Any;
use Test::Refcount;

use IO::Async::Test qw();

use IO::Async::OS;

use IO::File;
use Fcntl qw( SEEK_SET );
use POSIX qw( SIGTERM );
use Socket qw( sockaddr_family AF_UNIX );
use Time::HiRes qw( time );

our $VERSION = '0.77';

# Abstract Units of Time
use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

# The loop under test. We keep it in a single lexical here, so we can use
# is_oneref tests in the individual test suite functions
my $loop;
END { undef $loop }

=head1 NAME

C<IO::Async::LoopTests> - acceptance testing for L<IO::Async::Loop> subclasses

=head1 SYNOPSIS

 use IO::Async::LoopTests;
 run_tests( 'IO::Async::Loop::Shiney', 'io' );

=head1 DESCRIPTION

This module contains a collection of test functions for running acceptance
tests on L<IO::Async::Loop> subclasses. It is provided as a facility for
authors of such subclasses to ensure that the code conforms to the Loop API
required by L<IO::Async>.

=head1 TIMING

Certain tests require the use of timers or timed delays. Normally these are
counted in units of seconds. By setting the environment variable
C<TEST_QUICK_TIMERS> to some true value, these timers run 10 times quicker,
being measured in units of 0.1 seconds instead. This value may be useful when
running the tests interactively, to avoid them taking too long. The slower
timers are preferred on automated smoke-testing machines, to help guard
against false negatives reported simply because of scheduling delays or high
system load while testing.

 TEST_QUICK_TIMERS=1 ./Build test

=cut

=head1 FUNCTIONS

=cut

=head2 run_tests

   run_tests( $class, @tests )

Runs a test or collection of tests against the loop subclass given. The class
being tested is loaded by this function; the containing script does not need
to C<require> or C<use> it first.

This function runs C<Test::More::plan> to output its expected test count; the
containing script should not do this.

=cut

sub run_tests
{
   my ( $testclass, @tests ) = @_;

   ( my $file = "$testclass.pm" ) =~ s{::}{/}g;

   eval { require $file };
   if( $@ ) {
      BAIL_OUT( "Unable to load $testclass - $@" );
   }

   foreach my $test ( @tests ) {
      $loop = $testclass->new;

      isa_ok( $loop, $testclass, '$loop' );

      is( IO::Async::Loop->new, $loop, 'magic constructor yields $loop' );

      # Kill the reference in $ONE_TRUE_LOOP so as not to upset the refcounts
      # and to ensure we get a new one each time
      undef $IO::Async::Loop::ONE_TRUE_LOOP;

      is_oneref( $loop, '$loop has refcount 1' );

      __PACKAGE__->can( "run_tests_$test" )->();

      is_oneref( $loop, '$loop has refcount 1 finally' );
   }

   done_testing;
}

sub wait_for(&)
{
   # Bounce via here so we don't upset refcount tests by having loop
   # permanently set in IO::Async::Test
   IO::Async::Test::testing_loop( $loop );

   # Override prototype - I know what I'm doing
   &IO::Async::Test::wait_for( @_ );

   IO::Async::Test::testing_loop( undef );
}

sub time_between(&$$$)
{
   my ( $code, $lower, $upper, $name ) = @_;

   my $start = time;
   $code->();
   my $took = ( time - $start ) / AUT;

   cmp_ok( $took, '>=', $lower, "$name took at least $lower seconds" ) if defined $lower;
   cmp_ok( $took, '<=', $upper * 3, "$name took no more than $upper seconds" ) if defined $upper;
   if( $took > $upper and $took <= $upper * 3 ) {
      diag( "$name took longer than $upper seconds - this may just be an indication of a busy testing machine rather than a bug" );
   }
}

=head1 TEST SUITES

The following test suite names exist, to be passed as a name in the C<@tests>
argument to C<run_tests>:

=cut

=head2 io

Tests the Loop's ability to watch filehandles for IO readiness

=cut

sub run_tests_io
{
   {
      my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot create socket pair - $!";
      $_->blocking( 0 ) for $S1, $S2;

      my $readready  = 0;
      my $writeready = 0;
      $loop->watch_io(
         handle => $S1,
         on_read_ready => sub { $readready = 1 },
      );

      is_oneref( $loop, '$loop has refcount 1 after watch_io on_read_ready' );
      is( $readready, 0, '$readready still 0 before ->loop_once' );

      $loop->loop_once( 0.1 );

      is( $readready, 0, '$readready when idle' );

      $S2->syswrite( "data\n" );

      # We should still wait a little while even thought we expect to be ready
      # immediately, because talking to ourself with 0 poll timeout is a race
      # condition - we can still race with the kernel.

      $loop->loop_once( 0.1 );

      is( $readready, 1, '$readready after loop_once' );

      # Ready $S1 to clear the data
      $S1->getline; # ignore return

      $loop->unwatch_io(
         handle => $S1,
         on_read_ready => 1,
      );

      $loop->watch_io(
         handle => $S1,
         on_read_ready => sub { $readready = 1 },
      );

      $readready = 0;
      $S2->syswrite( "more data\n" );

      $loop->loop_once( 0.1 );

      is( $readready, 1, '$readready after ->unwatch_io/->watch_io' );

      $S1->getline; # ignore return

      $loop->watch_io(
         handle => $S1,
         on_write_ready => sub { $writeready = 1 },
      );

      is_oneref( $loop, '$loop has refcount 1 after watch_io on_write_ready' );

      $loop->loop_once( 0.1 );

      is( $writeready, 1, '$writeready after loop_once' );

      $loop->unwatch_io(
         handle => $S1,
         on_write_ready => 1,
      );

      $readready = 0;
      $loop->loop_once( 0.1 );

      is( $readready, 0, '$readready before HUP' );

      $S2->close;

      $readready = 0;
      $loop->loop_once( 0.1 );

      is( $readready, 1, '$readready after HUP' );

      $loop->unwatch_io(
         handle => $S1,
         on_read_ready => 1,
      );
   }

   # HUP of pipe - can be different to sockets on some architectures
   {
      my ( $Prd, $Pwr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
      $_->blocking( 0 ) for $Prd, $Pwr;

      my $readready = 0;
      $loop->watch_io(
         handle => $Prd,
         on_read_ready => sub { $readready = 1 },
      );

      $loop->loop_once( 0.1 );

      is( $readready, 0, '$readready before pipe HUP' );

      $Pwr->close;

      $readready = 0;
      $loop->loop_once( 0.1 );

      is( $readready, 1, '$readready after pipe HUP' );

      $loop->unwatch_io(
         handle => $Prd,
         on_read_ready => 1,
      );
   }

   SKIP: {
      $loop->_CAN_ON_HANGUP or skip "Loop cannot watch_io for on_hangup", 2;

      SKIP: {
         my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";
         $_->blocking( 0 ) for $S1, $S2;

         sockaddr_family( $S1->sockname ) == AF_UNIX or skip "Cannot reliably detect hangup condition on non AF_UNIX sockets", 1;

         my $hangup = 0;
         $loop->watch_io(
            handle => $S1,
            on_hangup => sub { $hangup = 1 },
         );

         $S2->close;

         $loop->loop_once( 0.1 );

         is( $hangup, 1, '$hangup after socket close' );

         $loop->unwatch_io(
            handle => $S1,
            on_hangup => 1,
         );
      }

      my ( $Prd, $Pwr ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
      $_->blocking( 0 ) for $Prd, $Pwr;

      my $hangup = 0;
      $loop->watch_io(
         handle => $Pwr,
         on_hangup => sub { $hangup = 1 },
      );

      $Prd->close;

      $loop->loop_once( 0.1 );

      is( $hangup, 1, '$hangup after pipe close for writing' );

      $loop->unwatch_io(
         handle => $Pwr,
         on_hangup => 1,
      );
   }

   # Check that combined read/write handlers can cancel each other
   {
      my ( $S1, $S2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";
      $_->blocking( 0 ) for $S1, $S2;

      my $callcount = 0;
      $loop->watch_io(
         handle => $S1,
         on_read_ready => sub {
            $callcount++;
            $loop->unwatch_io( handle => $S1, on_read_ready => 1, on_write_ready => 1 );
         },
         on_write_ready => sub {
            $callcount++;
            $loop->unwatch_io( handle => $S1, on_read_ready => 1, on_write_ready => 1 );
         },
      );

      $S2->close;

      $loop->loop_once( 0.1 );

      is( $callcount, 1, 'read/write_ready can cancel each other' );
   }

   # Check that cross-connected handlers can cancel each other
   {
      my ( $SA1, $SA2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";
      my ( $SB1, $SB2 ) = IO::Async::OS->socketpair or die "Cannot socketpair - $!";
      $_->blocking( 0 ) for $SA1, $SA2, $SB1, $SB2;

      my @handles = ( $SA1, $SB1 );

      my $callcount = 0;
      $loop->watch_io(
         handle => $_,
         on_write_ready => sub {
            $callcount++;
            $loop->unwatch_io( handle => $_, on_write_ready => 1 ) for @handles;
         },
      ) for @handles;

      $loop->loop_once( 0.1 );

      is( $callcount, 1, 'write_ready on crosslinked handles can cancel each other' );
   }

   # Check that error conditions that aren't true read/write-ability are still
   # invoked
   {
      my ( $S1, $S2 ) = IO::Async::OS->socketpair( 'inet', 'dgram' ) or die "Cannot create AF_INET/SOCK_DGRAM connected pair - $!";
      $_->blocking( 0 ) for $S1, $S2;
      $S2->close;

      my $readready = 0;
      $loop->watch_io(
         handle => $S1,
         on_read_ready => sub { $readready = 1 },
      );

      $S1->syswrite( "Boo!" );

      $loop->loop_once( 0.1 );

      is( $readready, 1, 'exceptional socket invokes on_read_ready' );

      $loop->unwatch_io(
         handle => $S1,
         on_read_ready => 1,
      );
   }

   # Check that regular files still report read/writereadiness
   {
      my $F = IO::File->new_tmpfile or die "Cannot create temporary file - $!";

      $F->print( "Here's some content\n" );
      $F->seek( 0, SEEK_SET );

      my $readready  = 0;
      my $writeready = 0;
      $loop->watch_io(
         handle => $F,
         on_read_ready  => sub { $readready = 1 },
         on_write_ready => sub { $writeready = 1 },
      );

      $loop->loop_once( 0.1 );

      is( $readready,  1, 'regular file is readready' );
      is( $writeready, 1, 'regular file is writeready' );

      $loop->unwatch_io(
         handle => $F,
         on_read_ready  => 1,
         on_write_ready => 1,
      );
   }
}

=head2 timer

Tests the Loop's ability to handle timer events

=cut

sub run_tests_timer
{
   my $done = 0;
   # New watch/unwatch API

   cmp_ok( abs( $loop->time - time ), "<", 0.1, '$loop->time gives the current time' );

   $loop->watch_time( after => 2 * AUT, code => sub { $done = 1; } );

   is_oneref( $loop, '$loop has refcount 1 after watch_time' );

   time_between {
      my $now = time;
      $loop->loop_once( 5 * AUT );

      # poll might have returned just a little early, such that the TimerQueue
      # doesn't think anything is ready yet. We need to handle that case.
      while( !$done ) {
         die "It should have been ready by now" if( time - $now > 5 * AUT );
         $loop->loop_once( 0.1 * AUT );
      }
   } 1.5, 2.5, 'loop_once(5) while waiting for watch_time after';

   $loop->watch_time( at => time + 2 * AUT, code => sub { $done = 2; } );

   time_between {
      my $now = time;
      $loop->loop_once( 5 * AUT );

      # poll might have returned just a little early, such that the TimerQueue
      # doesn't think anything is ready yet. We need to handle that case.
      while( !$done ) {
         die "It should have been ready by now" if( time - $now > 5 * AUT );
         $loop->loop_once( 0.1 * AUT );
      }
   } 1.5, 2.5, 'loop_once(5) while waiting for watch_time at';

   my $cancelled_fired = 0;
   my $id = $loop->watch_time( after => 1 * AUT, code => sub { $cancelled_fired = 1 } );
   $loop->unwatch_time( $id );
   undef $id;

   $loop->loop_once( 2 * AUT );

   ok( !$cancelled_fired, 'unwatched watch_time does not fire' );

   $loop->watch_time( after => -1, code => sub { $done = 1 } );

   $done = 0;

   time_between {
      $loop->loop_once while !$done;
   } 0, 0.1, 'loop_once while waiting for negative interval timer';

   {
      my $done;

      my $id;
      $id = $loop->watch_time( after => 1 * AUT, code => sub {
         $loop->unwatch_time( $id ); undef $id;
      });

      $loop->watch_time( after => 1.1 * AUT, code => sub {
         $done++;
      });

      wait_for { $done };

      is( $done, 1, 'Other timers still fire after self-cancelling one' );
   }

   # Legacy enqueue/requeue/cancel API
   $done = 0;

   $loop->enqueue_timer( delay => 2 * AUT, code => sub { $done = 1; } );

   is_oneref( $loop, '$loop has refcount 1 after enqueue_timer' );

   time_between {
      my $now = time;
      $loop->loop_once( 5 * AUT );

      # poll might have returned just a little early, such that the TimerQueue
      # doesn't think anything is ready yet. We need to handle that case.
      while( !$done ) {
         die "It should have been ready by now" if( time - $now > 5 * AUT );
         $loop->loop_once( 0.1 * AUT );
      }
   } 1.5, 2.5, 'loop_once(5) while waiting for timer';

   SKIP: {
      skip "Unable to handle sub-second timers accurately", 3 unless $loop->_CAN_SUBSECOND_ACCURATELY;

      # Check that short delays are achievable in one ->loop_once call
      foreach my $delay ( 0.001, 0.01, 0.1 ) {
         my $done;
         my $count = 0;
         my $start = time;

         $loop->enqueue_timer( delay => $delay, code => sub { $done++ } );

         while( !$done ) {
            $loop->loop_once( 1 );
            $count++;
            last if time - $start > 5; # bailout
         }

         is( $count, 1, "One ->loop_once(1) sufficient for a single $delay second timer" );
      }
   }

   $cancelled_fired = 0;
   $id = $loop->enqueue_timer( delay => 1 * AUT, code => sub { $cancelled_fired = 1 } );
   $loop->cancel_timer( $id );
   undef $id;

   $loop->loop_once( 2 * AUT );

   ok( !$cancelled_fired, 'cancelled timer does not fire' );

   $id = $loop->enqueue_timer( delay => 1 * AUT, code => sub { $done = 2; } );
   $id = $loop->requeue_timer( $id, delay => 2 * AUT );

   $done = 0;

   time_between {
      $loop->loop_once( 1 * AUT );

      is( $done, 0, '$done still 0 so far' );

      my $now = time;
      $loop->loop_once( 5 * AUT );

      # poll might have returned just a little early, such that the TimerQueue
      # doesn't think anything is ready yet. We need to handle that case.
      while( !$done ) {
         die "It should have been ready by now" if( time - $now > 5 * AUT );
         $loop->loop_once( 0.1 * AUT );
      }
   } 1.5, 2.5, 'requeued timer of delay 2';

   is( $done, 2, '$done is 2 after requeued timer' );
}

=head2 signal

Tests the Loop's ability to watch POSIX signals

=cut

sub run_tests_signal
{
   unless( IO::Async::OS->HAVE_SIGNALS ) {
      SKIP: { skip "This OS does not have signals", 14; }
      return;
   }

   my $caught = 0;

   $loop->watch_signal( TERM => sub { $caught++ } );

   is_oneref( $loop, '$loop has refcount 1 after watch_signal' );

   $loop->loop_once( 0.1 );

   is( $caught, 0, '$caught idling' );

   kill SIGTERM, $$;

   is( $caught, 0, '$caught before ->loop_once' );

   $loop->loop_once( 0.1 );

   is( $caught, 1, '$caught after ->loop_once' );

   kill SIGTERM, $$;

   is( $caught, 1, 'second raise is still deferred' );

   $loop->loop_once( 0.1 );

   is( $caught, 2, '$caught after second ->loop_once' );

   is_oneref( $loop, '$loop has refcount 1 before unwatch_signal' );

   $loop->unwatch_signal( 'TERM' );

   is_oneref( $loop, '$loop has refcount 1 after unwatch_signal' );

   my ( $cA, $cB );

   my $idA = $loop->attach_signal( TERM => sub { $cA = 1 } );
   my $idB = $loop->attach_signal( TERM => sub { $cB = 1 } );

   is_oneref( $loop, '$loop has refcount 1 after 2 * attach_signal' );

   kill SIGTERM, $$;

   $loop->loop_once( 0.1 );

   is( $cA, 1, '$cA after raise' );
   is( $cB, 1, '$cB after raise' );

   $loop->detach_signal( 'TERM', $idA );

   undef $cA;
   undef $cB;

   kill SIGTERM, $$;

   $loop->loop_once( 0.1 );

   is( $cA, undef, '$cA after raise' );
   is( $cB, 1,     '$cB after raise' );

   $loop->detach_signal( 'TERM', $idB );

   ok( exception { $loop->attach_signal( 'this signal name does not exist', sub {} ) },
       'Bad signal name fails' );

   undef $caught;
   $loop->attach_signal( TERM => sub { $caught++ } );

   $loop->post_fork;

   kill SIGTERM, $$;

   $loop->loop_once( 0.1 );

   is( $caught, 1, '$caught SIGTERM after ->post_fork' );
}

=head2 idle

Tests the Loop's support for idle handlers

=cut

sub run_tests_idle
{
   my $called = 0;

   my $id = $loop->watch_idle( when => 'later', code => sub { $called = 1 } );

   ok( defined $id, 'idle watcher id is defined' );

   is( $called, 0, 'deferred sub not yet invoked' );

   time_between { $loop->loop_once( 3 * AUT ) } undef, 1.0, 'loop_once(3) with deferred sub';

   is( $called, 1, 'deferred sub called after loop_once' );

   $loop->watch_idle( when => 'later', code => sub {
      $loop->watch_idle( when => 'later', code => sub { $called = 2 } )
   } );

   $loop->loop_once( 1 );

   is( $called, 1, 'inner deferral not yet invoked' );

   $loop->loop_once( 1 );

   is( $called, 2, 'inner deferral now invoked' );

   $called = 2; # set it anyway in case previous test fails

   $id = $loop->watch_idle( when => 'later', code => sub { $called = 20 } );

   $loop->unwatch_idle( $id );

   time_between { $loop->loop_once( 1 * AUT ) } 0.5, 1.5, 'loop_once(1) with unwatched deferral';

   is( $called, 2, 'unwatched deferral not called' );

   $id = $loop->watch_idle( when => 'later', code => sub { $called = 3 } );
   my $timer_id = $loop->watch_time( after => 5, code => sub {} );

   $loop->loop_once( 1 );

   is( $called, 3, '$loop->later still invoked with enqueued timer' );

   $loop->unwatch_time( $timer_id );

   $loop->later( sub { $called = 4 } );

   $loop->loop_once( 1 );

   is( $called, 4, '$loop->later shortcut works' );
}

=head2 process

Tests the Loop's support for watching child processes by PID

(Previously called C<child>)

=cut

sub run_in_child(&)
{
   my $kid = fork;
   defined $kid or die "Cannot fork() - $!";
   return $kid if $kid;

   shift->();
   die "Fell out of run_in_child!\n";
}

sub run_tests_process
{
   my $kid = run_in_child {
      exit( 3 );
   };

   my $exitcode;

   $loop->watch_process( $kid => sub { ( undef, $exitcode ) = @_; } );

   is_oneref( $loop, '$loop has refcount 1 after watch_process' );
   ok( !defined $exitcode, '$exitcode not defined before ->loop_once' );

   undef $exitcode;
   wait_for { defined $exitcode };

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after child exit' );
   is( ($exitcode >> 8), 3,     'WEXITSTATUS($exitcode) after child exit' );

   SKIP: {
      skip "This OS does not have signals", 1 unless IO::Async::OS->HAVE_SIGNALS;

      # We require that SIGTERM perform its default action; i.e. terminate the
      # process. Ensure this definitely happens, in case the test harness has it
      # ignored or handled elsewhere.
      local $SIG{TERM} = "DEFAULT";

      $kid = run_in_child {
         sleep( 10 );
         # Just in case the parent died already and didn't kill us
         exit( 0 );
      };

      $loop->watch_process( $kid => sub { ( undef, $exitcode ) = @_; } );

      kill SIGTERM, $kid;

      undef $exitcode;
      wait_for { defined $exitcode };

      is( ($exitcode & 0x7f), SIGTERM, 'WTERMSIG($exitcode) after SIGTERM' );
   }

   my %kids;

   $loop->watch_process( 0 => sub { my ( $kid ) = @_; delete $kids{$kid} } );

   %kids = map { run_in_child { exit 0 } => 1 } 1 .. 3;

   is( scalar keys %kids, 3, 'Waiting for 3 child processes' );

   wait_for { !keys %kids };
   ok( !keys %kids, 'All child processes reclaimed' );

   # Legacy API name
   $kid = run_in_child { exit 2 };

   undef $exitcode;
   $loop->watch_child( $kid => sub { ( undef, $exitcode ) = @_; } );
   wait_for { defined $exitcode };

   is( ($exitcode >> 8), 2, '$exitcode after child exit from legacy ->watch_child' );
}
*run_tests_child = \&run_tests_process; # old name

=head2 control

Tests that the C<run>, C<stop>, C<loop_once> and C<loop_forever> methods
behave correctly

=cut

sub run_tests_control
{
   time_between { $loop->loop_once( 0 ) } 0, 0.1, 'loop_once(0) when idle';

   time_between { $loop->loop_once( 2 * AUT ) } 1.5, 2.5, 'loop_once(2) when idle';

   $loop->watch_time( after => 0.1, code => sub { $loop->stop( result => "here" ) } );

   local $SIG{ALRM} = sub { die "Test timed out before ->stop" };
   alarm( 1 );

   my @result = $loop->run;

   alarm( 0 );

   is_deeply( \@result, [ result => "here" ], '->stop arguments returned by ->run' );

   $loop->watch_time( after => 0.1, code => sub { $loop->stop( result => "here" ) } );

   my $result = $loop->run;

   is( $result, "result", 'First ->stop argument returned by ->run in scalar context' );

   $loop->watch_time( after => 0.1, code => sub {
      SKIP: {
         unless( $loop->can( 'is_running' ) ) {
            diag "Unsupported \$loop->is_running";
            skip "Unsupported \$loop->is_running", 1;
         }

         ok( $loop->is_running, '$loop->is_running' );
      }

      $loop->watch_time( after => 0.1, code => sub { $loop->stop( "inner" ) } );
      my @result = $loop->run;
      $loop->stop( @result, "outer" );
   } );

   @result = $loop->run;

   is_deeply( \@result, [ "inner", "outer" ], '->run can be nested properly' );

   $loop->watch_time( after => 0.1, code => sub { $loop->loop_stop } );

   local $SIG{ALRM} = sub { die "Test timed out before ->loop_stop" };
   alarm( 1 );

   $loop->loop_forever;

   alarm( 0 );

   ok( 1, '$loop->loop_forever interruptable by ->loop_stop' );
}

=head2 metrics

Tests that metrics are generated appropriately using L<Metrics::Any>.

=cut

sub run_tests_metrics
{
   my $loopclass = ref $loop;

   return unless $IO::Async::Metrics::METRICS;

   # We should already at least have the loop-type metric
   is_metrics(
      {
         "io_async_loops class:$loopclass" => 1,
      },
      'Constructing the loop creates a loop type metric'
   );

   # The very first call won't create timing metrics because it isn't armed yet.
   $loop->loop_once( 0 );

   is_metrics_from(
      sub { $loop->loop_once( 0.1 ) },
      {
         io_async_processing_count => 1,
         io_async_processing_total => Test::Metrics::Any::positive,
      },
      'loop_once(0) creates timing metrics'
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

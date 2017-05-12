#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Identity;
use Test::Refcount;

use IO::Async::Routine;

use IO::Async::Channel;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

sub test_with_model
{
   my ( $model ) = @_;

   {
      my $calls   = IO::Async::Channel->new;
      my $returns = IO::Async::Channel->new;

      my $routine = IO::Async::Routine->new(
         model => $model,
         channels_in  => [ $calls ],
         channels_out => [ $returns ],
         code => sub {
            while( my $args = $calls->recv ) {
               last if ref $args eq "SCALAR";

               my $ret = 0;
               $ret += $_ for @$args;
               $returns->send( \$ret );
            }
         },
         on_finish => sub {},
      );

      isa_ok( $routine, "IO::Async::Routine", "\$routine for $model model" );
      is_oneref( $routine, "\$routine has refcount 1 initially for $model model" );

      $loop->add( $routine );

      is_refcount( $routine, 2, "\$routine has refcount 2 after \$loop->add for $model model" );

      is( $routine->model, $model, "\$routine->model for $model model" );

      $calls->send( [ 1, 2, 3 ] );

      my $f = wait_for_future $returns->recv;

      my $result = $f->get;
      is( ${$result}, 6, "Result for $model model" );

      is_refcount( $routine, 2, '$routine has refcount 2 before $loop->remove' );

      $loop->remove( $routine );

      is_oneref( $routine, '$routine has refcount 1 before EOF' );
   }

   {
      my $returned;
      my $return_routine = IO::Async::Routine->new(
         model => $model,
         code => sub { return 23 },
         on_return => sub { $returned = $_[1]; },
      );

      $loop->add( $return_routine );

      wait_for { defined $returned };

      is( $returned, 23, "on_return for $model model" );

      my $died;
      my $die_routine = IO::Async::Routine->new(
         model => $model,
         code => sub { die "ARGH!\n" },
         on_die => sub { $died = $_[1]; },
      );

      $loop->add( $die_routine );

      wait_for { defined $died };

      is( $died, "ARGH!\n", "on_die for $model model" );
   }

   {
      my $channel = IO::Async::Channel->new;

      my $finished;
      my $routine = IO::Async::Routine->new(
         model => $model,
         channels_in => [ $channel ],
         code => sub { while( $channel->recv ) { 1 } },
         on_finish => sub { $finished++ },
      );

      $loop->add( $routine );

      $channel->close;

      wait_for { $finished };
      pass( "Recv on closed channel for $model model" );
   }

   {
      my $channel = IO::Async::Channel->new;

      my $routine = IO::Async::Routine->new(
         model => $model,
         channels_out => [ $channel ],
         code => sub {
            $SIG{INT} = sub { $channel->send( \"SIGINT" ); die "SIGINT" };
            $channel->send( \"READY" );

            # Busy-wait so thread kill still works
            my $until = time() + 5;
            1 while time() < $until;
         },
      );

      $loop->add( $routine );

      my $f;
      $f = wait_for_future $channel->recv;

      is( ${ $f->get }, "READY", 'Routine is ready for SIGINT' );

      $routine->kill( "INT" );

      $f = wait_for_future $channel->recv;

      is( ${ $f->get }, "SIGINT", 'Routine caught SIGINT' );
   }
}

foreach my $model (qw( fork thread )) {
   SKIP: {
      skip "This Perl does not support threads", 9
         if $model eq "thread" and not IO::Async::OS->HAVE_THREADS;
      skip "This Perl does not support fork()", 9
         if $model eq "fork" and not IO::Async::OS->HAVE_POSIX_FORK;

      test_with_model( $model );
   }
}

# multiple channels in and out
{
   my $in1 = IO::Async::Channel->new;
   my $in2 = IO::Async::Channel->new;
   my $out1 = IO::Async::Channel->new;
   my $out2 = IO::Async::Channel->new;

   my $routine = IO::Async::Routine->new(
      channels_in  => [ $in1, $in2 ],
      channels_out => [ $out1, $out2 ],
      code => sub {
         while( my $op = $in1->recv ) {
            $op = $$op; # deref
            $out1->send( \"Ready $op" );
            my @args = @{ $in2->recv };
            my $result = $op eq "+" ? $args[0] + $args[1]
                                    : "ERROR";
            $out2->send( \$result );
         }
      },
      on_finish => sub { },
   );

   isa_ok( $routine, "IO::Async::Routine", '$routine' );

   $loop->add( $routine );

   $in1->send( \"+" );

   my $status_f = wait_for_future $out1->recv;

   is( ${ $status_f->get }, "Ready +", '$status_f result midway through Routine' );

   $in2->send( [ 10, 20 ] );

   my $result_f = wait_for_future $out2->recv;

   is( ${ $result_f->get }, 30, '$result_f result at end of Routine' );

   $loop->remove( $routine );
}

# sharing a Channel between Routines
{
   my $channel = IO::Async::Channel->new;

   my $src_finished;
   my $src_routine = IO::Async::Routine->new(
      channels_out => [ $channel ],
      code => sub {
         $channel->send( [ some => "data" ] );
         return 0;
      },
      on_finish => sub { $src_finished++ },
      on_die => sub { die "source routine failed - $_[1]" },
   );

   $loop->add( $src_routine );

   my $sink_result;
   my $sink_routine = IO::Async::Routine->new(
      channels_in => [ $channel ],
      code => sub {
         my @data = @{ $channel->recv };
         return ( $data[0] eq "some" and $data[1] eq "data" ) ? 0 : 1;
      },
      on_return => sub { $sink_result = $_[1] },
      on_die => sub { die "sink routine failed - $_[1]" },
   );

   $loop->add( $sink_routine );

   wait_for { $src_finished and defined $sink_result };

   is( $sink_result, 0, 'synchronous src->sink can share a channel' );
}

# Test that 'setup' works
SKIP: {
   skip "This Perl does not support fork()", 1
      if not IO::Async::OS->HAVE_POSIX_FORK;

   my $channel = IO::Async::Channel->new;

   my $routine = IO::Async::Routine->new(
      model => "fork",
      setup => [
         env => { FOO => "Here is a random string" },
      ],

      channels_out => [ $channel ],
      code => sub {
         $channel->send( [ $ENV{FOO} ] );
         $channel->close;
         return 0;
      },
      on_finish => sub {},
   );

   $loop->add( $routine );

   my $f = wait_for_future $channel->recv;

   my $result = $f->get;
   is( $result->[0], "Here is a random string", '$result from Routine with modified ENV' );

   $loop->remove( $routine );
}

# Test that STDOUT/STDERR are unaffected
SKIP: {
   skip "This Perl does not support fork()", 1
      if not IO::Async::OS->HAVE_POSIX_FORK;

   my ( $pipe_rd, $pipe_wr ) = IO::Async::OS->pipepair;

   my $routine;
   {
      open my $stdoutsave, ">&", \*STDOUT;
      POSIX::dup2( $pipe_wr->fileno, STDOUT->fileno );

      open my $stderrsave, ">&", \*STDERR;
      POSIX::dup2( $pipe_wr->fileno, STDERR->fileno );

      $routine = IO::Async::Routine->new(
         model => "fork",
         code => sub {
            STDOUT->autoflush(1);
            print STDOUT "A line to STDOUT\n";
            print STDERR "A line to STDERR\n";
            return 0;
         }
      );

      $loop->add( $routine );

      POSIX::dup2( $stdoutsave->fileno, STDOUT->fileno );
      POSIX::dup2( $stderrsave->fileno, STDERR->fileno );
   }

   my $buffer = "";
   $loop->watch_io(
      handle => $pipe_rd,
      on_read_ready => sub { sysread $pipe_rd, $buffer, 8192, length $buffer or die "Cannot read - $!" },
   );

   wait_for { $buffer =~ m/\n.*\n/ };

   is( $buffer, "A line to STDOUT\nA line to STDERR\n", 'Write-to-STD{OUT+ERR} wrote to pipe' );

   $loop->unwatch_io( handle => $pipe_rd, on_read_ready => 1 );
   $loop->remove( $routine );
}

done_testing;

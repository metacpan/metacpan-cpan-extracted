#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Refcount;

use POSIX qw( SIGTERM );

use IO::Async::PID;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

{
   my $kid = fork;
   defined $kid or die "Cannot fork() - $!";

   if( $kid == 0 ) {
      # child
      exit( 3 );
      # this exists as a zombie for now, but we'll deal with this later
   }

   my $exitcode;
   my $pid = IO::Async::PID->new(
      pid     => $kid,
      on_exit => sub { ( undef, $exitcode ) = @_; }
   );

   ok( defined $pid, '$pid defined' );
   isa_ok( $pid, "IO::Async::PID", '$pid isa IO::Async::PID' );

   is_oneref( $pid, '$pid has refcount 1 initially' );

   is( $pid->pid, $kid, '$pid->pid' );

   is( $pid->notifier_name, "$kid", '$pid->notifier_name' );

   $loop->add( $pid );

   is_refcount( $pid, 2, '$pid has refcount 2 after adding to Loop' );

   # reap zombie
   wait_for { defined $exitcode };

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after process exit' );
   is( ($exitcode >> 8), 3,     'WEXITSTATUS($exitcode) after process exit' );
}

SKIP: {
   skip "This OS has no signals", 1 unless IO::Async::OS->HAVE_SIGNALS;

   # We require that SIGTERM perform its default action; i.e. terminate the
   # process. Ensure this definitely happens, in case the test harness has it
   # ignored or handled elsewhere.
   local $SIG{TERM} = "DEFAULT";

   my $kid = fork;
   defined $kid or die "Cannot fork() - $!";

   if( $kid == 0 ) {
      sleep( 10 );
      # Just in case the parent died already and didn't kill us
      exit( 0 );
   }

   my $exitcode;
   my $pid = IO::Async::PID->new(
      pid     => $kid,
      on_exit => sub { ( undef, $exitcode ) = @_; }
   );

   $loop->add( $pid );

   $pid->kill( SIGTERM );

   wait_for { defined $exitcode };

   is( ($exitcode & 0x7f), SIGTERM, 'WTERMSIG($exitcode) after SIGTERM' );
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;

use POSIX qw( SIGTERM SIGKILL );

use IO::Async::Process::GracefulShutdown;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# Normal shutdown
{
   my $process = IO::Async::Process::GracefulShutdown->new(
      code => sub { sleep 60 },
   );

   $loop->add( $process );

   $process->shutdown( "TERM" );

   my $exitcode = wait_for_future( $process->finish_future )->get;

   is( ($exitcode & 0x7f), SIGTERM, 'WTERMSIG($exitcode) after shutdown by SIGTERM' );
}

# Timeout and KILL
{
   my $process = IO::Async::Process::GracefulShutdown->new(
      code => sub { $SIG{TERM} = "IGNORE"; sleep 60 },
   );

   $loop->add( $process );

   my $killed;
   $process->shutdown( "TERM",
      timeout => 0.1,
      on_kill => sub { $killed++ },
   );

   my $exitcode = wait_for_future( $process->finish_future )->get;

   is( ($exitcode & 0x7f), SIGKILL, 'WTERMSIG($exitcode) after shutdown by SIGTERM+SIGKILL' );
   ok( $killed, 'on_kill was invoked' );
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;

use IO::Async::Process::GracefulShutdown;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# Normal exit
{
   my ( $invocant, $exitcode );

   my $process = IO::Async::Process::GracefulShutdown->new(
      code => sub { return 0 },
      on_finish => sub { ( $invocant, $exitcode ) = @_; },
   );

   $loop->add( $process );

   wait_for { defined $exitcode };

   is( $invocant, $process, '$_[0] in on_finish is $process' );

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after sub { 0 }' );
   is( ($exitcode >> 8), 0,     'WEXITSTATUS($exitcode) after sub { 0 }' );
}

# ->finish_future
{
   my $process = IO::Async::Process::GracefulShutdown->new(
      code => sub { return 12 },
   );

   $loop->add( $process );

   my $exitcode = wait_for_future( $process->finish_future )->get;

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after sub { 12 }' );
   is( ($exitcode >> 8), 12,    'WEXITSTATUS($exitcode) after sub { 12 }' );
}

done_testing;

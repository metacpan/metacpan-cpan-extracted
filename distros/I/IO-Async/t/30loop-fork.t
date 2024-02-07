#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;
use Test::Metrics::Any;

use POSIX qw( SIGINT );

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

{
   my $exitcode;
   $loop->fork(
      code    => sub { return 5; },
      on_exit => sub { ( undef, $exitcode ) = @_ },
   );

   wait_for { defined $exitcode };

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after child exit' );
   is( ($exitcode >> 8), 5,     'WEXITSTATUS($exitcode) after child exit' );
}

{
   my $exitcode;
   $loop->fork(
      code    => sub { die "error"; },
      on_exit => sub { ( undef, $exitcode ) = @_ },
   );

   wait_for { defined $exitcode };

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after child die' );
   is( ($exitcode >> 8), 255, 'WEXITSTATUS($exitcode) after child die' );
}

SKIP: {
   skip "This OS does not have signals", 1 unless IO::Async::OS->HAVE_SIGNALS;

   local $SIG{INT} = sub { exit( 22 ) };

   my $exitcode;
   $loop->fork(
      code    => sub { kill SIGINT, $$ },
      on_exit => sub { ( undef, $exitcode ) = @_ },
   );

   wait_for { defined $exitcode };

   is( ($exitcode & 0x7f), SIGINT, 'WTERMSIG($exitcode) after child SIGINT' );
}

SKIP: {
   skip "This OS does not have signals", 2 unless IO::Async::OS->HAVE_SIGNALS;

   local $SIG{INT} = sub { exit( 22 ) };

   my $exitcode;
   $loop->fork(
      code    => sub { kill SIGINT, $$ },
      on_exit => sub { ( undef, $exitcode ) = @_ },
      keep_signals => 1,
   );

   wait_for { defined $exitcode };

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after child SIGINT with keep_signals' );
   is( ($exitcode >> 8), 22,    'WEXITSTATUS($exitcode) after child SIGINT with keep_signals' );
}

{
   my $exitcode;

   $loop->fork(
      code => sub {
         my $innerloop = IO::Async::Loop->new;
         return 0 if $innerloop != $loop; # success
         return 1;
      },
      on_exit => sub { ( undef, $exitcode ) = @_ },
   );

   wait_for { defined $exitcode };

   ok( $exitcode == 0, 'IO::Async::Loop->new inside forked process code gets new loop instance' );
}

# Metrics
SKIP: {
   skip "Metrics are unavailable" unless $IO::Async::Metrics::METRICS;
   is_metrics_from(
      sub { $loop->fork( code => sub {}, on_exit => sub {} ) },
      { io_async_forks => 1 },
      '$loop->fork increments fork counter'
   );
}

done_testing;

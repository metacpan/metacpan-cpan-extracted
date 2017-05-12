#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;

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

done_testing;

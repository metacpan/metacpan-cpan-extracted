#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;
use Test2::IPC; # initialise Test2 before starting threads

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "Threads are not available" unless IO::Async::OS->HAVE_THREADS;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# thread in scalar context
{
   my @result;
   $loop->create_thread(
      code      => sub { return "A result" },
      on_joined => sub { @result = @_ },
   );

   wait_for { @result };

   is( \@result, [ return => "A result" ], 'result to on_joined for returning thread' );
}

# thread in list context
{
   my @result;
   $loop->create_thread(
      code      => sub { return "A result", "of many", "values" },
      context   => "list",
      on_joined => sub { @result = @_ },
   );

   wait_for { @result };

   is( \@result, [ return => "A result", "of many", "values" ], 'result to on_joined for returning thread in list context' );
}

# thread that dies
{
   my @result;
   $loop->create_thread(
      code      => sub { die "Ooops I fail\n" },
      on_joined => sub { @result = @_ },
   );

   wait_for { @result };

   is( \@result, [ died => "Ooops I fail\n" ], 'result to on_joined for a died thread' );
}

done_testing;

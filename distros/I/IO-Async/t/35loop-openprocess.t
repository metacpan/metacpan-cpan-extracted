#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my $exitcode;

my $proc = $loop->open_process(
   code => sub { 0 },
   on_finish => sub { ( undef, $exitcode ) = @_; },
);

isa_ok( $proc, [ "IO::Async::Process" ], '$proc from ->open_process isa IO::Async::Process' );

undef $exitcode;
wait_for { defined $exitcode };

ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after sub { 0 }' );
is( ($exitcode >> 8), 0,     'WEXITSTATUS($exitcode) after sub { 0 }' );

ok( dies { $loop->open_process(
         command => [ $^X, "-e", 1 ]
      ) },
   'Missing on_finish fails'
);

ok( dies { $loop->open_process(
         command => [ $^X, "-e", 1 ],
         on_finish => sub {},
         on_exit => sub {},
      ) },
   'on_exit parameter fails'
);

# open_child compatibility wrapper
{
   my $exitpid;
   my $pid = $loop->open_child(
      code => sub { 0 },
      on_finish => sub { ( $exitpid, undef ) = @_; },
   );

   like( $pid, qr/^\d+$/, '$loop->open_child returns a PID-like number' );

   wait_for { defined $exitpid };
   is( $exitpid, $pid, 'on_finish passed the same PID as returned from ->open_child' );

   ok( dies { $loop->open_child(
            command => [ $^X, "-e", 1 ],
            on_finish => "hello"
         ) },
      'on_finish not CODE ref fails'
   );
}

done_testing;

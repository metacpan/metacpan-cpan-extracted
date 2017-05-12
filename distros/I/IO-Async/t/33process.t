#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Refcount;

use POSIX qw( ENOENT SIGTERM SIGUSR1 );
use constant ENOENT_MESSAGE => do { local $! = ENOENT; "$!" };

use IO::Async::Process;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

{
   my ( $invocant, $exitcode );

   my $process = IO::Async::Process->new(
      code => sub { return 0 },
      on_finish => sub { ( $invocant, $exitcode ) = @_; },
   );

   is_oneref( $process, '$process has refcount 1 before $loop->add' );

   is( $process->notifier_name, "nopid", '$process->notifier_name before $loop->add' );

   ok( !$process->is_running, '$process is not yet running' );
   ok( !defined $process->pid, '$process has no PID yet' );

   $loop->add( $process );

   is_refcount( $process, 2, '$process has refcount 2 after $loop->add' );

   my $pid = $process->pid;

   ok( $process->is_running, '$process is running' );
   ok( defined $pid, '$process now has a PID' );

   is( $process->notifier_name, "$pid", '$process->notifier_name after $loop->add' );

   wait_for { defined $exitcode };

   is( $invocant, $process, '$_[0] in on_finish is $process' );
   undef $invocant; # refcount

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after sub { 0 }' );
   is( ($exitcode >> 8), 0,     'WEXITSTATUS($exitcode) after sub { 0 }' );

   ok( !$process->is_running, '$process no longer running' );
   ok( defined $process->pid, '$process still has PID after exit' );

   is( $process->notifier_name, "[$pid]", '$process->notifier_name after exit' );

   ok( $process->is_exited,     '$process->is_exited after sub { 0 }' );
   is( $process->exitstatus, 0, '$process->exitstatus after sub { 0 }' );

   ok( !defined $process->loop, '$process no longer in Loop' );

   is_oneref( $process, '$process has refcount 1 before EOS' );
}

{
   my $process = IO::Async::Process->new(
      code => sub { return 3 },
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after sub { 3 }' );
   is( $process->exitstatus, 3, '$process->exitstatus after sub { 3 }' );
}

{
   my ( $invocant, $exception, $exitcode );

   my $process = IO::Async::Process->new(
      code => sub { die "An exception\n" },
      on_finish => sub { die "Test failed early\n" },
      on_exception => sub { ( $invocant, $exception, undef, $exitcode ) = @_ },
   );

   is_oneref( $process, '$process has refcount 1 before $loop->add' );

   $loop->add( $process );

   is_refcount( $process, 2, '$process has refcount 2 after $loop->add' );

   wait_for { defined $exitcode };

   is( $invocant, $process, '$_[0] in on_exception is $process' );
   undef $invocant; # refcount

   ok( ($exitcode & 0x7f) == 0,      'WIFEXITED($exitcode) after sub { die }' );
   is( ($exitcode >> 8), 255,        'WEXITSTATUS($exitcode) after sub { die }' );
   is( $exception, "An exception\n", '$exception after sub { die }' );

   ok( $process->is_exited,           '$process->is_exited after sub { die }' );
   is( $process->exitstatus, 255,     '$process->exitstatus after sub { die }' );
   is( $process->exception, "An exception\n", '$process->exception after sub { die }' );

   is_oneref( $process, '$process has refcount 1 before EOS' );
}

{
   my $exitcode;

   my $process = IO::Async::Process->new(
      code => sub { die "An exception\n" },
      on_finish => sub { ( undef, $exitcode ) = @_ },
   );

   $loop->add( $process );

   wait_for { defined $exitcode };

   ok( ($exitcode & 0x7f) == 0, 'WIFEXITED($exitcode) after sub { die } on_finish' );
   is( ($exitcode >> 8), 255,   'WEXITSTATUS($exitcode) after sub { die } on_finish' );

   ok( $process->is_exited,           '$process->is_exited after sub { die } on_finish' );
   is( $process->exitstatus, 255,     '$process->exitstatus after sub { die } on_finish' );
   is( $process->exception, "An exception\n", '$process->exception after sub { die } on_finish' );
}

{
   my $process = IO::Async::Process->new(
      command => [ $^X, "-e", '1' ],
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl -e 1' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl -e 1' );
}

{
   my $process = IO::Async::Process->new(
      command => [ $^X, "-e", 'exit 5' ],
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl -e exit 5' );
   is( $process->exitstatus, 5, '$process->exitstatus after perl -e exit 5' );
}

{
   # Just be paranoid in case anyone actually has this
   my $donotexist = "/bin/donotexist";
   $donotexist .= "X" while -e $donotexist;

   my ( $exception, $errno );

   my $process = IO::Async::Process->new(
      command => $donotexist,
      on_finish => sub { die "Test failed early\n" },
      on_exception => sub { ( undef, $exception, $errno ) = @_ },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   is( $errno+0, ENOENT,         '$errno number after donotexist' ); 
   is( "$errno", ENOENT_MESSAGE, '$errno string after donotexist' );

   ok( $process->is_exited,           '$process->is_exited after donotexist' );
   is( $process->exitstatus, 255,     '$process->exitstatus after donotexist' );
   is( $process->errno,  ENOENT,         '$process->errno number after donotexist' );
   is( $process->errstr, ENOENT_MESSAGE, '$process->errno string after donotexist' );
   is( $process->exception, "", '$process->exception after donotexist' );
}

{
   $ENV{TEST_KEY} = "foo";

   my $process = IO::Async::Process->new(
      code => sub { $ENV{TEST_KEY} eq "bar" ? 0 : 1 },
      setup => [
         env => { TEST_KEY => "bar" },
      ],
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after %ENV test' );
   is( $process->exitstatus, 0, '$process->exitstatus after %ENV test' );
}

SKIP: {
   skip "This OS does not have signals", 2 unless IO::Async::OS->HAVE_SIGNALS;

   my $child_ready;
   $loop->watch_signal( USR1 => sub { $child_ready++ } );

   my $parentpid = $$;
   my $process = IO::Async::Process->new(
      code => sub {
         my $exitcode = 10;
         eval {
            local $SIG{TERM} = sub { $exitcode = 20; die };
            kill SIGUSR1 => $parentpid;
            sleep 60; # block on signal
         };
         return $exitcode;
      },
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { $child_ready };

   $process->kill( SIGTERM );

   wait_for { !$process->is_running };

   ok( $process->is_exited,      '$process->is_exited after ->kill' );
   is( $process->exitstatus, 20, '$process->exitstatus after ->kill' );

   $loop->unwatch_signal( USR1 => );
}

done_testing;

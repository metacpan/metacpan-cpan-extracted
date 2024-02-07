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

# run_process capture exitcode
{
   my $f;

   $f = $loop->run_process(
      code    => sub { 3 },
      capture => [qw( exitcode )],
   );
   is( [ $f->get ], [ 3 << 8 ],
      '$f->get from code gives exitcode' );

   $f = $loop->run_process(
      command => [ $^X, "-e", 'exit 5' ],
      capture => [qw( exitcode )],
   );
   is( [ $f->get ], [ 5 << 8 ],
      '$f->get from command gives exitcode' );
}

# run_process capture stdout
{
   my $f;

   $f = $loop->run_process(
      code    => sub { print "hello\n"; 0 },
      capture => [qw( stdout )],
   );
   is( [ $f->get ], [ "hello\n" ],
      '$f->get from code gives stdout' );

   $f = $loop->run_process(
      command => [ $^X, "-e", 'print "goodbye\n"' ],
      capture => [qw( stdout )],
   );
   is( [ $f->get ], [ "goodbye\n" ],
      '$f->get from command gives stdout' );
}

# run_process capture stdout and stderr
{
   my $f;

   $f = $loop->run_process(
      command => [ $^X, "-e", 'print STDOUT "output\n"; print STDERR "error\n";' ],
      capture => [qw( stdout stderr )],
   );
   is( [ $f->get ], [ "output\n", "error\n" ],
      '$f->get from command gives stdout and stderr' );
}

# run_process sending stdin
{
   my $f;

   # perl -pe 1 behaves like cat; copies STDIN to STDOUT
   $f = $loop->run_process(
      command => [ $^X, "-pe", '1' ],
      stdin   => "some data\n",
      capture => [qw( stdout )],
   );
   is( [ $f->get ], [ "some data\n" ],
      '$f->get from command given stdin gives stdout' );
}

# run_process default capture
{
   my $f = $loop->run_process(
      command => [ $^X, "-e", 'print STDOUT "output";' ],
   );
   is( [ $f->get ], [ 0, "output" ],
      '$f->get from command with default capture' );
}

# run_process captures in weird order
{
   my $f = $loop->run_process(
      command => [ $^X, "-e", 'print STDOUT "output"; print STDERR "error";' ],
      capture => [qw(stderr exitcode stdout)],
   );
   is( [ $f->get ], [ "error", 0, "output" ],
      '$f->get from command with all captures' );
}

# run_process cancel_signal
{
   my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";
   $wr->autoflush;

   my $f = $loop->run_process(
      setup => [
         $wr => "keep",
      ],
      code => sub {
         $SIG{TERM} = sub {
            $wr->syswrite( "B" );
         };
         $wr->syswrite( "A" );
         sleep 5;
      },
      cancel_signal => "TERM"
   );

   # Wait for startup notification "A"
   my $buf;
   wait_for_stream { length $buf } $rd => $buf;

   $f->cancel;

   # Wait for signal
   wait_for_stream { length $buf > 1 } $rd => $buf;

   is( $buf, "AB", 'Process received cancel signal' );
}

# run_process fail_on_nonzero
{
   my $f = $loop->run_process(
      code    => sub { return 3 },
      capture => [qw( exitcode )],
      fail_on_nonzero => 1,
   );

   wait_for_future $f;

   ok( $f->is_failed, '$f->failed with fail_on_nonzero' ) and do {
      # ignore message
      my ( undef, $category, @captures ) = $f->failure;
      is( $category, "process", '$f->failure category' );
      is( \@captures, [ 3<<8 ], '$f->failure details' );
   };
}

# Testing error handling
ok( dies { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         some_key_you_fail => 1
      ) },
   'unrecognised key fails'
);

ok( dies { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         capture => 'pid'
      ) },
   'Capture in capture format'
);

ok( dies { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         capture => ['invalid_capture']
      ) },
   'Invalid capture type'
);

ok( dies { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         on_finish => sub{ 0 }
      ) },
   'Failing when finish callback is passed'
);

done_testing;

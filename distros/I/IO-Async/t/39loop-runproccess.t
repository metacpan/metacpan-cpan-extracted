#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;

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
   is_deeply( [ $f->get ], [ 3 << 8 ],
      '$f->get from code gives exitcode' );

   $f = $loop->run_process(
      command => [ $^X, "-e", 'exit 5' ],
      capture => [qw( exitcode )],
   );
   is_deeply( [ $f->get ], [ 5 << 8 ],
      '$f->get from command gives exitcode' );
}

# run_process capture stdout
{
   my $f;

   $f = $loop->run_process(
      code    => sub { print "hello\n"; 0 },
      capture => [qw( stdout )],
   );
   is_deeply( [ $f->get ], [ "hello\n" ],
      '$f->get from code gives stdout' );

   $f = $loop->run_process(
      command => [ $^X, "-e", 'print "goodbye\n"' ],
      capture => [qw( stdout )],
   );
   is_deeply( [ $f->get ], [ "goodbye\n" ],
      '$f->get from command gives stdout' );
}

# run_process capture stdout and stderr
{
   my $f;

   $f = $loop->run_process(
      command => [ $^X, "-e", 'print STDOUT "output\n"; print STDERR "error\n";' ],
      capture => [qw( stdout stderr )],
   );
   is_deeply( [ $f->get ], [ "output\n", "error\n" ],
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
   is_deeply( [ $f->get ], [ "some data\n" ],
      '$f->get from command given stdin gives stdout' );
}

# run_process default capture
{
   my $f = $loop->run_process(
      command => [ $^X, "-e", 'print STDOUT "output";' ],
   );
   is_deeply( [ $f->get ], [ 0, "output" ],
      '$f->get from command with default capture' );
}

# run_process captures in weird order
{
   my $f = $loop->run_process(
      command => [ $^X, "-e", 'print STDOUT "output"; print STDERR "error";' ],
      capture => [qw(stderr exitcode stdout)],
   );
   is_deeply( [ $f->get ], [ "error", 0, "output" ],
      '$f->get from command with all captures' );
}

# Testing error handling
ok( exception { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         some_key_you_fail => 1
      ) },
   'unrecognised key fails'
);

ok( exception { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         capture => 'pid'
      ) },
   'Capture in capture format'
);

ok( exception { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         capture => ['invalid_capture']
      ) },
   'Invalid capture type'
);

ok( exception { $loop->run_process(
         command => [ $^X, "-e", 1 ],
         on_finish => sub{ 0 }
      ) },
   'Failing when finish callback is passed'
);

done_testing;

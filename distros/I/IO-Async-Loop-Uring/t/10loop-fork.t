#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use IO::Async::OS;
use IO::Async::Loop::Uring;

plan skip_all => 'Not yet implemented'; # 
plan skip_all => "Cannot fork" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop::Uring->new;

my @kids = map {
   defined( my $pid = fork ) or die "Cannot fork() - $!";
   if( $pid ) {
      $pid;
   }
   else {
      test_in_child();
      exit 0;
   }
} 1 .. 3;

sub test_in_child
{
   my ( $rd, $wr ) = IO::Async::OS->pipepair;

   my $readable;

   $loop->watch_io(
      handle => $rd,
      on_read_ready => sub { $readable++ },
   );

   sleep 1;

   $wr->autoflush;
   $wr->print( "HELLO\n" );

   my $count = 5;

   $loop->loop_once( 0.1 ) until $readable or !$count--;

   die "[$$] FAILED\n" if !$readable;
}

foreach my $kid ( @kids ) {
   waitpid $kid, 0;
   is( $?, 0, "Child $kid exited OK" );
}

done_testing;

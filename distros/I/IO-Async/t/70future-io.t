#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;
use Test::Future::IO::Impl 0.17;

use lib ".";
use t::TimeAbout;

use IO::Async::Loop;
use IO::Async::OS;

use Errno;

eval { require Future::IO; Future::IO->VERSION( '0.19' );
       require Future::IO::ImplBase } or
   plan skip_all => "Future::IO 0.19 is not available";
require Future::IO::Impl::IOAsync;

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

testing_loop( IO::Async::Loop->new_builtin );

# ->sleep
{
   my $f = Future::IO->sleep( 2 * AUT );

   time_about( sub { wait_for_future $f }, 2, 'Future::IO->sleep' );
}

# ->sysread
{
   my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";
   $rd->blocking( 0 );

   $wr->autoflush();
   $wr->print( "Some bytes\n" );

   my $f = Future::IO->sysread( $rd, 256 );

   is( ( wait_for_future $f )->get, "Some bytes\n", 'Future::IO->sysread' );
}

# ->syswrite
{
   my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";
   $wr->blocking( 0 );

   $wr->autoflush();
   1 while $wr->syswrite( "X" x 4096 ); # This will eventually return undef/EAGAIN
   $! == Errno::EAGAIN or $! == Errno::EWOULDBLOCK or
      die "Expected EAGAIN, got $!";

   my $f = Future::IO->syswrite( $wr, "ABCD" );

   $rd->sysread( my $buf, 4096 );

   is( ( wait_for_future $f )->get, 4, 'Future::IO->syswrite' );

   1 while $rd->sysread( $buf, 4096 ) == 4096;
   is( $buf, "ABCD", 'Future::IO->syswrite wrote data' );
}

run_tests qw(
   sleep
   poll_no_hup
   read sysread write syswrite
   connect accept
   send recv
   waitpid
);

done_testing;

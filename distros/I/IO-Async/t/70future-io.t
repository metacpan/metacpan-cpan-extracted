#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;

use lib ".";
use t::TimeAbout;

use IO::Async::Loop;
use IO::Async::OS;

use Future::IO;
use Future::IO::Impl::IOAsync;

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

   $wr->autoflush();
   $wr->print( "Some bytes\n" );

   my $f = Future::IO->sysread( $rd, 256 );

   is( ( wait_for_future $f )->get, "Some bytes\n", 'Future::IO->sysread' );
}

done_testing;

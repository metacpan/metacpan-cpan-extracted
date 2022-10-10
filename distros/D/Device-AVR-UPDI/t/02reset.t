#!/usr/bin/perl

use v5.20;
use warnings;

use Test::More;
use Test::Future::IO;

use lib 't/lib';
use MockFH;

use Device::AVR::UPDI;

my $mockfio = Test::Future::IO->controller;

my $updi = Device::AVR::UPDI->new( fh => MockFH->new, part => "ATtiny814" );
# can't easily ->init_link without upsetting $mockfio

# ->request_reset
{
   $mockfio->expect_syswrite_anyfh( "\x55\xC8\x59" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC8\x59" );
   $mockfio->expect_sleep( 0.1 );

   $updi->request_reset( 1 )->get;

   $mockfio->check_and_clear( "->request_reset on" );

   $mockfio->expect_syswrite_anyfh( "\x55\xC8\x00" ); # SYNC
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC8\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->request_reset( 0 )->get;

   $mockfio->check_and_clear( "->request_reset off" );
}

done_testing;

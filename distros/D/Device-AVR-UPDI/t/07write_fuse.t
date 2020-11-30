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

# write_fuse
{
   # NVMCTRL set ADDR
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x08\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x44\x08\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x85" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\x85" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x09\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x44\x09\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x12" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\x12" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL set DATA
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x06\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x44\x06\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\xC8" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\xC8" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL command - write fuse
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x07" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\x07" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->write_fuse( 5, 0xC8 )->get;

   $mockfio->check_and_clear( "->write_fuse" );
}

done_testing;

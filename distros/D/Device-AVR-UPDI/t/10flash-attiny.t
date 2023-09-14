#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Future::IO;

use lib 't/lib';
use MockFH;

use Device::AVR::UPDI;

my $mockfio = Test::Future::IO->controller;

my $updi = Device::AVR::UPDI->new( fh => MockFH->new, part => "ATtiny814" );
# can't easily ->init_link without upsetting $mockfio
$updi->_set_nvm_version( 0 );

# read_flash_page
{
   # ST ptr
   $mockfio->expect_syswrite_anyfh( "\x55\x69\x00\x80" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x69\x00\x80" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x07" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xA0\x07" );
   $mockfio->expect_sleep( 0.1 );
   # LD8
   $mockfio->expect_syswrite_anyfh( "\x55\x24" );
   $mockfio->expect_sysread_anyfh( 10 )
      ->will_done( "\x55\x24" . "abcdefgh" );
   $mockfio->expect_sleep( 0.1 );

   my $data = $updi->read_flash_page( 0x00, 8 )->get;
   is( $data, "abcdefgh", '->read_flash_page returns data' );

   $mockfio->check_and_clear( "->read_flash_page" );
}

# write_flash_page
{
   # NVMCTRL command - erase page
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x04" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x04" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );
   # Set RSD
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x08" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC2\x08" );
   $mockfio->expect_sleep( 0.1 );
   # Write actual data
   $mockfio->expect_syswrite_anyfh( "\x55\x69\x20\x80" );
   $mockfio->expect_sysread_anyfh( 4 )
      ->will_done( "\x55\x69\x20\x80" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x03" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\x65" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x55\x65" );
   $mockfio->expect_sleep( 0.1 );
   # Actual data
   $mockfio->expect_syswrite_anyfh( "ABCDEFGH" );
   $mockfio->expect_sysread_anyfh( 8 )
      ->will_done( "ABCDEFGH" );
   $mockfio->expect_sleep( 0.1 );
   # Write final byte
   $mockfio->expect_syswrite_anyfh( "\x55\x64" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x55\x64" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "I" );
   $mockfio->expect_sysread_anyfh( 1 )
      ->will_done( "I" );
   $mockfio->expect_sleep( 0.1 );
   # Clear RSD
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x00" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC2\x00" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL command - write page
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x01" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x01" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x04\x02\x10" . "\x01" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_sleep( 0.01 )
      ->will_done();
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->write_flash_page( 0x20, "ABCDEFGHI" )->get;

   $mockfio->check_and_clear( "->write_flash_page" );
}

done_testing;

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
$updi->_set_nvm_version( 2 );

# read_flash_page
{
   # STS8 to set FLMAP
   $mockfio->expect_syswrite_anyfh( "\x55\x48\x01\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x48\x01\x10\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x00" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # ST ptr
   $mockfio->expect_syswrite_anyfh( "\x55\x6A\x00\x80\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x6A\x00\x80\x00" . "\x40" );
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
   # STS8 to set FLMAP
   $mockfio->expect_syswrite_anyfh( "\x55\x48\x01\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x48\x01\x10\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x00" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL mode set write
   $mockfio->expect_syswrite_anyfh( "\x55\x48\x00\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x48\x00\x10\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x02" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x02" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # Set RSD
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x08" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC2\x08" );
   $mockfio->expect_sleep( 0.1 );
   # Write actual data
   $mockfio->expect_syswrite_anyfh( "\x55\x6A\x20\x80\x00" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x6A\x20\x80\x00" );
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
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x08\x02\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x08\x02\x10\x00" . "\x00" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL mode clear
   $mockfio->expect_syswrite_anyfh( "\x55\x48\x00\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x48\x00\x10\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x00" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x08\x02\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x08\x02\x10\x00" . "\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->write_flash_page( 0x20, "ABCDEFGHI" )->get;

   $mockfio->check_and_clear( "->write_flash_page" );
}

done_testing;

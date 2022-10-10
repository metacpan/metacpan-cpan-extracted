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
$updi->_set_nvm_version( 2 );

# read_eeprom_page
{
   # ST ptr
   $mockfio->expect_syswrite_anyfh( "\x55\x6A\x00\x14\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x6A\x00\x14\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x03" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   # LD8
   $mockfio->expect_syswrite_anyfh( "\x55\x24" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x24" . "abcd" );
   $mockfio->expect_sleep( 0.1 );

   my $data = $updi->read_eeprom_page( 0x00, 4 )->get;
   is( $data, "abcd", '->read_eeprom_page returns data' );

   $mockfio->check_and_clear( "->read_eeprom_page" );
}

# write_eeprom_page
{
   # NVMCTRL mode set write
   $mockfio->expect_syswrite_anyfh( "\x55\x48\x00\x10\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x48\x00\x10\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x13" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x13" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # Set RSD
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x08" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC2\x08" );
   $mockfio->expect_sleep( 0.1 );
   # Write actual data
   $mockfio->expect_syswrite_anyfh( "\x55\x6A\x10\x14\x00" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->will_done( "\x55\x6A\x10\x14\x00" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x03" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\x64" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x55\x64" );
   $mockfio->expect_sleep( 0.1 );
   # Actual data
   $mockfio->expect_syswrite_anyfh( "ABCD" );
   $mockfio->expect_sysread_anyfh( 4 )
      ->will_done( "ABCD" );
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

   $updi->write_eeprom_page( 0x10, "ABCD" )->get;

   $mockfio->check_and_clear( "->write_eeprom_page" );
}

done_testing;

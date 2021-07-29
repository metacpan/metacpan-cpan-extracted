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
$updi->_set_nvm_version( 0 );

# read_eeprom_page
{
   # ST ptr
   $mockfio->expect_syswrite_anyfh( "\x55\x69\x00\x14" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x69\x00\x14" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x03" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   # LD8
   $mockfio->expect_syswrite_anyfh( "\x55\x24" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->returns( "\x55\x24" . "abcd" );
   $mockfio->expect_sleep( 0.1 );

   my $data = $updi->read_eeprom_page( 0x00, 4 )->get;
   is( $data, "abcd", '->read_eeprom_page returns data' );

   $mockfio->check_and_clear( "->read_eeprom_page" );
}

# write_eeprom_page
{
   # NVMCTRL command - erase page
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x04" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\x04" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );
   # Set RSD
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x08" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xC2\x08" );
   $mockfio->expect_sleep( 0.1 );
   # Write actual data
   $mockfio->expect_syswrite_anyfh( "\x55\x69\x10\x14" );
   $mockfio->expect_sysread_anyfh( 4 )
      ->returns( "\x55\x69\x10\x14" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x03" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\x64" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\x55\x64" );
   $mockfio->expect_sleep( 0.1 );
   # Actual data
   $mockfio->expect_syswrite_anyfh( "ABCD" );
   $mockfio->expect_sysread_anyfh( 4 )
      ->returns( "ABCD" );
   $mockfio->expect_sleep( 0.1 );
   # Clear RSD
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x00" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xC2\x00" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL command - write page
   $mockfio->expect_syswrite_anyfh( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x03" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->returns( "\x03" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x01" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_sleep( 0.01 )
      ->returns();
   $mockfio->expect_syswrite_anyfh( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->write_eeprom_page( 0x10, "ABCD" )->get;

   $mockfio->check_and_clear( "->write_eeprom_page" );
}

done_testing;

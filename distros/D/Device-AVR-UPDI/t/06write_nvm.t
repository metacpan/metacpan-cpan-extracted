#!/usr/bin/perl

use v5.20;
use warnings;

use Test::More;
use Test::EasyMock qw( create_mock );
use Test::Deep qw( ignore );
use Test::Future::IO;

use Device::AVR::UPDI;

my $mockfio = Test::Future::IO->controller;

my $updi = Device::AVR::UPDI->new( fh => create_mock(), part => "ATtiny814" );
# can't easily ->init_link without upsetting $mockfio

# write_nvm_page 16bit
{
   # NVMCTRL command - erase page
   $mockfio->expect_syswrite( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x04" );
   $mockfio->expect_sysread( 2 )
      ->returns( "\x04" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );
   # Write actual data
   $mockfio->expect_syswrite( "\x55\x69\x20\x80" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x69\x20\x80" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite( "\x55\xA0\x03" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x55\x65" );
   $mockfio->expect_sysread( 2 )
      ->returns( "\x55\x65" );
   $mockfio->expect_sleep( 0.1 );
   # Actual data
   foreach ( qw( AB CD EF GH ) ) {
      $mockfio->expect_syswrite( $_ );
      $mockfio->expect_sysread( 3 )
         ->returns( $_ . "\x40" );
      $mockfio->expect_sleep( 0.1 );
   }
   # NVMCTRL command - write page
   $mockfio->expect_syswrite( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x01" );
   $mockfio->expect_sysread( 2 )
      ->returns( "\x01" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x01" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_sleep( 0.01 )
      ->returns();
   $mockfio->expect_syswrite( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->write_nvm_page( 0x8000 + 0x20, "ABCDEFGH", 16 )->get;

   $mockfio->check_and_clear( "->write_nvm_page 16bit" );
}

# write_nvm_page 8bit
{
   # NVMCTRL command - erase page
   $mockfio->expect_syswrite( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x04" );
   $mockfio->expect_sysread( 2 )
      ->returns( "\x04" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );
   # Write actual data
   $mockfio->expect_syswrite( "\x55\x69\x10\x14" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x69\x10\x14" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # REPEAT
   $mockfio->expect_syswrite( "\x55\xA0\x03" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\xA0\x03" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x55\x64" );
   $mockfio->expect_sysread( 2 )
      ->returns( "\x55\x64" );
   $mockfio->expect_sleep( 0.1 );
   # Actual data
   foreach ( qw( a b c d ) ) {
      $mockfio->expect_syswrite( $_ );
      $mockfio->expect_sysread( 2 )
         ->returns( $_ . "\x40" );
      $mockfio->expect_sleep( 0.1 );
   }
   # NVMCTRL command - write page
   $mockfio->expect_syswrite( "\x55\x44\x00\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x44\x00\x10" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x01" );
   $mockfio->expect_sysread( 2 )
      ->returns( "\x01" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   # NVMCTRL read status
   $mockfio->expect_syswrite( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x01" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_sleep( 0.01 )
      ->returns();
   $mockfio->expect_syswrite( "\x55\x04\x02\x10" );
   $mockfio->expect_sysread( 5 )
      ->returns( "\x55\x04\x02\x10" . "\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->write_nvm_page( 0x1400 + 0x10, "abcd", 8 )->get;

   $mockfio->check_and_clear( "->write_nvm_page 8bit" );
}

done_testing;

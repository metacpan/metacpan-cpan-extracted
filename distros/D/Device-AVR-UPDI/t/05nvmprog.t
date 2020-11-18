#!/usr/bin/perl

use v5.20;
use warnings;

use Test::More;
use Test::EasyMock qw( create_mock );
use Test::Future::IO;

use Device::AVR::UPDI;

my $mockfio = Test::Future::IO->controller;

my $updi = Device::AVR::UPDI->new( fh => create_mock(), part => "ATtiny814" );
# can't easily ->init_link without upsetting $mockfio

# enable_nvmprog
{
   # KEY
   $mockfio->expect_syswrite( "\x55\xE0" . " gorPMVN" );
   $mockfio->expect_sysread( 10 )
      ->returns( "\x55\xE0" . " gorPMVN" );
   $mockfio->expect_sleep( 0.1 );
   # read ASI_KEY_STATUS
   $mockfio->expect_syswrite( "\x55\x87" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\x87" . "\x10" );
   $mockfio->expect_sleep( 0.1 );
   # Reset
   $mockfio->expect_syswrite( "\x55\xC8\x59" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\xC8\x59" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite( "\x55\xC8\x00" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\xC8\x00" );
   $mockfio->expect_sleep( 0.1 );
   # read ASI_SYS_STATUS
   $mockfio->expect_syswrite( "\x55\x8B" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\x8B\x00" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_sleep( 0.05 )
      ->returns();
   $mockfio->expect_syswrite( "\x55\x8B" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\x8B\x08" );
   $mockfio->expect_sleep( 0.1 );

   $updi->enable_nvmprog->get;

   $mockfio->check_and_clear( "->enable_nvmprog" );
}

done_testing;

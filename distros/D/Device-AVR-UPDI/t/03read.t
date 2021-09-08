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

# read_updirev
{
   $mockfio->expect_syswrite_anyfh( "\x55\x80" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\x80" . "\x10" );
   $mockfio->expect_sleep( 0.1 );

   is( $updi->read_updirev->get, 1, '->read_updi_rev yields value' );

   $mockfio->check_and_clear( "->read_updirev" );
}

# read_sib
{
   $mockfio->expect_syswrite_anyfh( "\x55\xE5" );
   $mockfio->expect_sysread_anyfh( 18 )
      ->returns( "\x55\xE5" . "tinyAVR P:0D:0 3" );
   $mockfio->expect_sleep( 0.1 );

   is_deeply( $updi->read_sib->get,
      {
         family       => "tinyAVR",
         nvm_version  => "P:0",
         ocd_version  => "D:0",
         dbg_osc_freq => "3",
      },
      '->read_sib yields value' );

   $mockfio->check_and_clear( "->read_sib" );
}

# read_signature
{
   $mockfio->expect_syswrite_anyfh( "\x55\x69\x00\x11" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x69\x00\x11" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\xA0\x02" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xA0\x02" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\x24" );
   $mockfio->expect_sysread_anyfh( 5 )
      ->returns( "\x55\x24" . "\x1E\x93\x22" );
   $mockfio->expect_sleep( 0.1 );

   is( $updi->read_signature->get, "\x1E\x93\x22", '->read_signature yields value' );

   $mockfio->check_and_clear( "->read_signature" );
}

done_testing;

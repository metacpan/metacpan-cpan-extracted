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

# write_fuse
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
   # Write actual data
   $mockfio->expect_syswrite_anyfh( "\x55\x6A\x85\x12\x00" );
   $mockfio->expect_sysread_anyfh( 6 )
      ->will_done( "\x55\x6A\x85\x12\x00" . "\x40" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\x64" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\x55\x64" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\xC8" );
   $mockfio->expect_sysread_anyfh( 2 )
      ->will_done( "\xC8" . "\x40" );
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

   $updi->write_fuse( 5, 0xC8 )->get;

   $mockfio->check_and_clear( "->write_fuse" );
}

done_testing;

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

# erase_chip
{
   # KEY
   $mockfio->expect_syswrite_anyfh( "\x55\xE0" . "esarEMVN" );
   $mockfio->expect_sysread_anyfh( 10 )
      ->will_done( "\x55\xE0" . "esarEMVN" );
   $mockfio->expect_sleep( 0.1 );
   # read ASI_KEY_STATUS
   $mockfio->expect_syswrite_anyfh( "\x55\x87" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\x87" . "\x08" );
   $mockfio->expect_sleep( 0.1 );
   # Reset
   $mockfio->expect_syswrite_anyfh( "\x55\xC8\x59" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC8\x59" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_syswrite_anyfh( "\x55\xC8\x00" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\xC8\x00" );
   $mockfio->expect_sleep( 0.1 );
   # read ASI_SYS_STATUS
   $mockfio->expect_syswrite_anyfh( "\x55\x8B" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\x8B\x01" );
   $mockfio->expect_sleep( 0.1 );
   $mockfio->expect_sleep( 0.05 )
      ->will_done();
   $mockfio->expect_syswrite_anyfh( "\x55\x8B" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->will_done( "\x55\x8B\x00" );
   $mockfio->expect_sleep( 0.1 );

   $updi->erase_chip->get;

   $mockfio->check_and_clear( "->erase_chip" );
}

done_testing;

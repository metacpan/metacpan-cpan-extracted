#!/usr/bin/perl

use v5.20;
use warnings;

use Test::More;
use Test::ExpectAndCheck;
use Test::Future::IO;

use Device::AVR::UPDI;

my ( $mockfh, $fh ) = Test::ExpectAndCheck->create;
my $mockfio = Test::Future::IO->controller;

# init
{
   $mockfh->expect( cfmakeraw => );
   $mockfh->expect( set_mode => "115200,8,e,2" );
   $mockfh->expect( setflag_clocal => 1 );
   $mockfh->expect( autoflush => );

   my $updi = Device::AVR::UPDI->new( fh => $fh, part => "ATtiny814" );

   $mockfh->check_and_clear( "->new" );
   $mockfio->check_and_clear( "->new" );

   # BREAK
   $mockfio->expect_sleep( 0.1 )
      ->returns();
   $mockfh->expect( getobaud => )
      ->returns( 115200 );
   $mockfh->expect( setbaud => 300 );
   $mockfh->expect( print =>"\0" );
   $mockfio->expect_sysread_anyfh( 1 )
      ->returns( "\0" );
   $mockfio->expect_sleep( 0.05 )
      ->returns();
   $mockfh->expect( setbaud =>115200 );
   # Store CTRLB
   $mockfio->expect_syswrite_anyfh( "\x55\xC3\x08" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xC3\x08" );
   $mockfio->expect_sleep( 0.1 );
   # Store CTRLA
   $mockfio->expect_syswrite_anyfh( "\x55\xC2\x00" );
   $mockfio->expect_sysread_anyfh( 3 )
      ->returns( "\x55\xC2\x00" );
   $mockfio->expect_sleep( 0.1 );

   # Read SIB
   $mockfio->expect_syswrite_anyfh( "\x55\xE5" );
   $mockfio->expect_sysread_anyfh( 18 )
      ->returns( "\x55\xE5" . "tinyAVR\x00P:0D:0\x003" );
   $mockfio->expect_sleep( 0.1 );

   $updi->init_link->get;

   $mockfh->check_and_clear( "->init_link" );
   $mockfio->check_and_clear( "->init_link" );
}

done_testing;

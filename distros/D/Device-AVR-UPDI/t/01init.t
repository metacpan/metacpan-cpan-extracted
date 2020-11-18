#!/usr/bin/perl

use v5.20;
use warnings;

use Test::More;
use Test::EasyMock qw( create_mock expect reset replay verify );
use Test::Future::IO;

use Device::AVR::UPDI;

my $mockfh = create_mock();
my $mockfio = Test::Future::IO->controller;

# init
{
   reset ( $mockfh );
   expect( $mockfh->cfmakeraw );
   expect( $mockfh->set_mode( "115200,8,e,2" ) );
   expect( $mockfh->setflag_clocal( 1 ) );
   expect( $mockfh->autoflush );

   replay( $mockfh );

   my $updi = Device::AVR::UPDI->new( fh => $mockfh, part => "ATtiny814" );

   verify( $mockfh );
   $mockfio->check_and_clear( "->new" );

   reset( $mockfh );
   # BREAK
   $mockfio->expect_sleep( 0.1 )
      ->returns();
   expect( $mockfh->getobaud )->and_scalar_return( 115200 );
   expect( $mockfh->setbaud( 300 ) );
   expect( $mockfh->print( "\0" ) );
   $mockfio->expect_sysread( 1 )
      ->returns( "\0" );
   $mockfio->expect_sleep( 0.05 )
      ->returns();
   expect( $mockfh->setbaud( 115200 ) );
   # OP
   $mockfio->expect_syswrite( "\x55\xC3\x08" );
   $mockfio->expect_sysread( 3 )
      ->returns( "\x55\xC3\x08" );
   $mockfio->expect_sleep( 0.1 );

   replay( $mockfh );

   $updi->init_link->get;

   verify( $mockfh );
   $mockfio->check_and_clear( "->init_link" );
}

done_testing;

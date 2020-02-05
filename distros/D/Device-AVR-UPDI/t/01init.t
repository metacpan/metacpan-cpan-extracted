#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::EasyMock qw( create_mock expect reset replay verify );
use Test::Deep qw( ignore );

use Device::AVR::UPDI;

my $mockfh = create_mock();
my $mockfio = create_mock();
Future::IO->override_impl( "TestFutureIO" );

# init
{
   reset ( $mockfh, $mockfio );
   expect( $mockfh->cfmakeraw );
   expect( $mockfh->set_mode( "115200,8,e,2" ) );
   expect( $mockfh->setflag_clocal( 1 ) );
   expect( $mockfh->autoflush );

   replay( $mockfh, $mockfio );
   my $updi = Device::AVR::UPDI->new( fh => $mockfh, part => "ATtiny814" );
   verify( $mockfh, $mockfio );

   reset( $mockfh, $mockfio );
   # BREAK
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->done );
   expect( $mockfh->getobaud )->and_scalar_return( 115200 );
   expect( $mockfh->setbaud( 300 ) );
   expect( $mockfh->print( "\0" ) );
   expect( $mockfio->sysread( 1 ) )
      ->and_scalar_return( Future->done( "\0" ) );
   expect( $mockfio->sleep( 0.05 ) )
      ->and_scalar_return( Future->done );
   expect( $mockfh->setbaud( 115200 ) );
   # OP
   expect( $mockfh->print( "\x55\xC3\x08" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xC3\x08" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );

   replay( $mockfh, $mockfio );
   $updi->init_link->get;
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { $mockfio->sleep($_[1]) }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

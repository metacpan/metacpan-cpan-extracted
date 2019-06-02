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

my $updi = Device::AVR::UPDI->new( fh => $mockfh, part => "ATtiny814" );
# can't easily ->init_link without upsetting $mockfio

# enable_nvmprog
{
   reset ( $mockfh, $mockfio );
   # KEY
   expect( $mockfh->print( "\x55\xE0" . " gorPMVN" ) );
   expect( $mockfio->sysread( 10 ) )
      ->and_scalar_return( Future->done( "\x55\x80" . " gorPMVN" ) );
   # read ASI_KEY_STATUS
   expect( $mockfh->print( "\x55\x87" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\x87" . "\x10" ) );
   # Reset
   expect( $mockfh->print( "\x55\xC8\x59" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xC8\x59" ) );
   expect( $mockfh->print( "\x55\xC8\x00" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xC8\x00" ) );
   # read ASI_SYS_STATUS
   expect( $mockfh->print( "\x55\x8B" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\x8B\x00" ) );
   expect( $mockfio->sleep( 0.05 ) )
      ->and_scalar_return( Future->done );
   expect( $mockfh->print( "\x55\x8B" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\x8B\x08" ) );

   replay( $mockfh, $mockfio );
   $updi->enable_nvmprog->get;
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { $mockfio->sleep($_[1]) }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

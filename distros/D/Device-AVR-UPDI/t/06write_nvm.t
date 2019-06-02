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

# write_nvm_page
{
   reset ( $mockfh, $mockfio );
   # NVMCTRL command - erase page
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfh->print( "\x04" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x04" . "\x40" ) );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );
   # Write actual data
   expect( $mockfh->print( "\x55\x69\x20\x80" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x69\x20\x80" . "\x40" ) );
   # REPEAT
   expect( $mockfh->print( "\x55\xA0\x03" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xA0\x03" ) );
   expect( $mockfh->print( "\x55\x65" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x55\x65" ) );
   # Actual data
   foreach ( qw( AB CD EF GH ) ) {
      expect( $mockfh->print( $_ ) );
      expect( $mockfio->sysread( 3 ) )
         ->and_scalar_return( Future->done( $_ . "\x40" ) );
   }
   # NVMCTRL command - write page
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfh->print( "\x01" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x01" . "\x40" ) );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x01" ) );
   expect( $mockfio->sleep( 0.01 ) )
      ->and_scalar_return( Future->done );
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );

   replay( $mockfh, $mockfio );
   $updi->write_nvm_page( 0x20, "ABCDEFGH" )->get;
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { $mockfio->sleep($_[1]) }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

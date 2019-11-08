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

# write_nvm_page 16bit
{
   reset ( $mockfh, $mockfio );
   # NVMCTRL command - erase page
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x04" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x04" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # Write actual data
   expect( $mockfh->print( "\x55\x69\x20\x80" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x69\x20\x80" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # REPEAT
   expect( $mockfh->print( "\x55\xA0\x03" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xA0\x03" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x55\x65" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x55\x65" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # Actual data
   foreach ( qw( AB CD EF GH ) ) {
      expect( $mockfh->print( $_ ) );
      expect( $mockfio->sysread( 3 ) )
         ->and_scalar_return( Future->done( $_ . "\x40" ) );
      expect( $mockfio->sleep( 0.1 ) )
         ->and_scalar_return( Future->new );
   }
   # NVMCTRL command - write page
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x01" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x01" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x01" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfio->sleep( 0.01 ) )
      ->and_scalar_return( Future->done );
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );

   replay( $mockfh, $mockfio );
   $updi->write_nvm_page( 0x8000 + 0x20, "ABCDEFGH", 16 )->get;
   verify( $mockfh, $mockfio );
}

# write_nvm_page 8bit
{
   reset ( $mockfh, $mockfio );
   # NVMCTRL command - erase page
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x04" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x04" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # Write actual data
   expect( $mockfh->print( "\x55\x69\x10\x14" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x69\x10\x14" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # REPEAT
   expect( $mockfh->print( "\x55\xA0\x03" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xA0\x03" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x55\x64" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x55\x64" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # Actual data
   foreach ( qw( a b c d ) ) {
      expect( $mockfh->print( $_ ) );
      expect( $mockfio->sysread( 2 ) )
         ->and_scalar_return( Future->done( $_ . "\x40" ) );
      expect( $mockfio->sleep( 0.1 ) )
         ->and_scalar_return( Future->new );
   }
   # NVMCTRL command - write page
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x01" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x01" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x01" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfio->sleep( 0.01 ) )
      ->and_scalar_return( Future->done );
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );

   replay( $mockfh, $mockfio );
   $updi->write_nvm_page( 0x1400 + 0x10, "abcd", 8 )->get;
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { $mockfio->sleep($_[1]) }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

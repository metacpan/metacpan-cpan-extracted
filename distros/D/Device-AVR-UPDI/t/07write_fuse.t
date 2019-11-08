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

# write_fuse
{
   reset ( $mockfh, $mockfio );
   # NVMCTRL set ADDR
   expect( $mockfh->print( "\x55\x44\x08\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x08\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x85" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x85" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x55\x44\x09\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x09\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x12" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x12" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL set DATA
   expect( $mockfh->print( "\x55\x44\x06\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x06\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\xC8" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\xC8" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL command - write fuse
   expect( $mockfh->print( "\x55\x44\x00\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x44\x00\x10" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   expect( $mockfh->print( "\x07" ) );
   expect( $mockfio->sysread( 2 ) )
      ->and_scalar_return( Future->done( "\x07" . "\x40" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );
   # NVMCTRL read status
   expect( $mockfh->print( "\x55\x04\x02\x10" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x04\x02\x10" . "\x00" ) );
   expect( $mockfio->sleep( 0.1 ) )
      ->and_scalar_return( Future->new );

   replay( $mockfh, $mockfio );
   $updi->write_fuse( 5, 0xC8 )->get;
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { $mockfio->sleep($_[1]) }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

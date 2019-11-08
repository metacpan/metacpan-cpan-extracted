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

# read_updirev
{
   reset ( $mockfh, $mockfio );
   expect( $mockfh->print( "\x55\x80" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\x80" . "\x10" ) );

   replay( $mockfh, $mockfio );
   is( $updi->read_updirev->get, 1, '->read_updi_rev yields value' );
   verify( $mockfh, $mockfio );
}

# read_sib
{
   reset ( $mockfh, $mockfio );
   expect( $mockfh->print( "\x55\xE5" ) );
   expect( $mockfio->sysread( 18 ) )
      ->and_scalar_return( Future->done( "\x55\xE5" . "tinyAVR P:0D:0 3" ) );

   replay( $mockfh, $mockfio );
   is_deeply( $updi->read_sib->get,
      {
         family       => "tinyAVR",
         nvm_version  => "P:0",
         ocd_version  => "D:0",
         dbg_osc_freq => "3",
      },
      '->read_sib yields value' );
   verify( $mockfh, $mockfio );
}

# read_signature
{
   reset ( $mockfh, $mockfio );
   expect( $mockfh->print( "\x55\x69\x00\x11" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x69\x00\x11" . "\x40" ) );
   expect( $mockfh->print( "\x55\xA0\x02" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xA0\x02" ) );
   expect( $mockfh->print( "\x55\x24" ) );
   expect( $mockfio->sysread( 5 ) )
      ->and_scalar_return( Future->done( "\x55\x24" . "\x1E\x93\x22" ) );

   replay( $mockfh, $mockfio );
   is( $updi->read_signature->get, "\x1E\x93\x22", '->read_signature yields value' );
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { Future->new }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

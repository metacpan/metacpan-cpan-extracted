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

# init
{
   reset ( $mockfh, $mockfio );
   expect( $mockfh->print( "\x55\xC8\x59" ) );
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xC8\x59" ) );

   replay( $mockfh, $mockfio );
   $updi->request_reset( 1 )->get;
   verify( $mockfh, $mockfio );

   reset ( $mockfh, $mockfio );
   expect( $mockfh->print( "\x55\xC8\x00" ) ); # SYNC
   expect( $mockfio->sysread( 3 ) )
      ->and_scalar_return( Future->done( "\x55\xC8\x00" ) );

   replay( $mockfh, $mockfio );
   $updi->request_reset( 0 )->get;
   verify( $mockfh, $mockfio );
}

done_testing;

package TestFutureIO;
sub sleep           { Future->new }
sub sysread         { $mockfio->sysread(@_[2..$#_]) }
sub sysread_exactly { $mockfio->sysread(@_[2..$#_]) }

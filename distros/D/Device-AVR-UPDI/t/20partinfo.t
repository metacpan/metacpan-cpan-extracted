#!/usr/bin/perl

use v5.20;
use warnings;

use Test::More;
use Test::EasyMock qw( create_mock );

use Device::AVR::UPDI;

my $mockfh = create_mock();
my $updi = Device::AVR::UPDI->new( fh => $mockfh, part => "ATtiny814" );

ok( my $partinfo = $updi->partinfo, 'have partinfo' );

is( $partinfo->name, "ATtiny814", '$partinfo->name' );
is( $partinfo->signature, "\x1e\x93\x22", '$partinfo->signature' );

is( $partinfo->size_flash, 8192, '$partinfo->size_flash' );

is_deeply( $partinfo->fusenames,
   [qw( WDTCFG BODCFG OSCCFG ), undef, qw( TCD0CFG SYSCFG0 SYSCFG1 APPEND BOOTEND )],
   '$partinfo->fusenames' );

done_testing;

#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Future::IO;

use lib 't/lib';
use MockFH;

use Device::AVR::UPDI;

my $updi = Device::AVR::UPDI->new( fh => MockFH->new, part => "ATtiny814" );

ok( my $partinfo = $updi->partinfo, 'have partinfo' );

is( $partinfo->name, "ATtiny814", '$partinfo->name' );
is( $partinfo->signature, "\x1e\x93\x22", '$partinfo->signature' );

is( $partinfo->size_flash, 8192, '$partinfo->size_flash' );

is( $partinfo->fusenames,
   [qw( WDTCFG BODCFG OSCCFG ), undef, qw( TCD0CFG SYSCFG0 SYSCFG1 APPEND BOOTEND )],
   '$partinfo->fusenames' );

done_testing;

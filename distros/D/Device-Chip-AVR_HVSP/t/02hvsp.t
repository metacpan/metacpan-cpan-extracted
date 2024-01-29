#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;
use Test::Future::Deferred;

use Future::AsyncAwait;

use Device::Chip::AVR_HVSP;

my $chip = Device::Chip::AVR_HVSP->new;
my $adapter = Test::Device::Chip::Adapter->new;

# ->mount already resets GPIO lines

$adapter->expect_write_gpios( { sdi => 0, sii => 0, sci => 0 } );
$adapter->expect_tris_gpios( [ 'sdo' ] );

await $chip->mount( $adapter );

$adapter->check_and_clear( 'mount' );

# A quick mocking setup for the ->_transfer method, now that t/01transfer.t
# has asserted it correct
{
   use experimental 'signatures';

   my @expectations;

   no warnings 'redefine';
   *Device::Chip::AVR_HVSP::_transfer = sub ( $self, $sdi, $sii ){
      my $next = shift @expectations or
         return Future->fail( "Expected no more transfers, got {sdi=$sdi sii=$sii}" );

      $sii == $next->[1] or
         return Future->fail( sprintf "Expected sii=%d/%02X, got sii=%d/%02X",
            $next->[1], $next->[1], $sii, $sii );
      $sdi == $next->[0] or
         return Future->fail( sprintf "Expected sdi=%d/%02X, got sdi=%d/%02X",
            $next->[0], $next->[0], $sdi, $sdi );

      pass "Expectation";
      return Test::Future::Deferred->done_later( $next->[2] );
   };

   sub expect_transfer ( $sdi, $sii, $sdo = undef )
   {
      push @expectations, [ $sdi, $sii, $sdo ];
   }

   sub expect_cmd { expect_transfer( $_[0], 0x4C, 0 ) }

   sub expect_lla { expect_transfer( $_[0], 0x0C ) }
   sub expect_lha { expect_transfer( $_[0], 0x1C ) }

   sub expect_lld { expect_transfer( $_[0], 0x2C ) }
   sub expect_lhd { expect_transfer( $_[0], 0x3C ) }

   sub expect_pulse { expect_transfer( 0, $_[0], 0 );
                      expect_transfer( 0, $_[0] | 0x0C, 0 ); }

   sub expect_wlb { expect_pulse( 0x64 ) }

   sub expect_pulse_read { expect_transfer( 0, $_[0], 0 );
                           expect_transfer( 0, $_[0] | 0x0C, $_[1] ); }

   sub expect_rlb { expect_pulse_read( 0x68, $_[0] ) }
   sub expect_rhb { expect_pulse_read( 0x78, $_[0] ) }

   sub expect_sdo_high
   {
      $adapter->expect_read_gpios( [ 'sdo' ] )->will_done( { sdo => 1 } );
   }

   sub expect_done ( $title )
   {
      @expectations and
         return fail "Expected another transfer but no more happened";
      pass "End of expectations";
      $adapter->check_and_clear( $title );
   }
}

# chip_erase
{
   expect_cmd 0x80;
   expect_wlb;
   expect_sdo_high;

   await $chip->chip_erase;

   expect_done '->chip_erase';
}

# read_signature
{
   expect_cmd 0x08;
   expect_lla 0;
   expect_rlb ord 'A';
   expect_lla 1;
   expect_rlb ord 'B';
   expect_lla 2;
   expect_rlb ord 'C';

   is( await $chip->read_signature, "ABC",
      '$chip->read_signature yields signature' );

   expect_done '->read_signature';
}

# read_calibration
{
   expect_cmd 0x08;
   expect_lla 0;
   expect_pulse_read 0x78, ord 'x';

   is( await $chip->read_calibration, "x",
      '$chip->read_calibration yields byte' );

   expect_done '->read_calibration';
}

# lock
{
   # read
   expect_cmd 0x04;
   expect_pulse_read 0x78, 3;

   is( await $chip->read_lock, "\x03",
      '$chip->read_lock yields lock' );

   expect_done '->read_lock';

   # write
   expect_cmd 0x20;
   expect_lld 0x01;
   expect_wlb;
   expect_sdo_high;

   await $chip->write_lock( 0x01 );

   expect_done '->write_lock';
}

# fuses
{
   # read
   expect_cmd 0x04;
   expect_rlb 0xFD;

   is( await $chip->read_fuse_byte( 'lfuse' ), 0xFD,
      '$chip->read_fuse yields fuse' );

   expect_done '->read_fuse_byte';

   # write
   expect_cmd 0x40;
   expect_lld 0xFB;
   expect_wlb;
   expect_sdo_high;

   await $chip->write_fuse_byte( lfuse => 0xFB );

   expect_done '->write_fuse_byte';
}

# start
{
   no warnings 'once';
   local *Test::Device::Chip::Adapter::power = sub { Future->done };

   $adapter->expect_write_gpios( { hv => 1 } );

   expect_cmd 0x08;
   expect_lla 0;
   expect_pulse_read 0x68, 0x1E;
   expect_lla 1;
   expect_pulse_read 0x68, 0x91;
   expect_lla 2;
   expect_pulse_read 0x68, 0x0B;

   await $chip->start;

   is( $chip->partname, "ATtiny24", '$chip->partname after $chip->start' );
}

# flash
{
   # read
   expect_cmd 0x02;
   expect_lla 20;
   expect_lha 0;
   expect_rlb 0x12;
   expect_rhb 0x34;

   is( await $chip->read_flash( start => 20, bytes => 2 ), "\x12\x34",
      '$chip->read_flash yields bytes' );

   expect_done '->read_flash';

   # write
   # TODO: There isn't yet API to write a small fragment, so we'll have to test
   # the whole 2KiB
   expect_cmd 0x10;
   foreach my $baseaddr ( map { $_ * 16 } 0 .. (1024/16) - 1 ) {
      # fill the page buffer
      foreach my $addr ( $baseaddr .. $baseaddr + 16 - 1 ) {
         expect_lla $addr & 0xFF;
         expect_lld 0x55;
         expect_pulse 0x6D;
         expect_lhd 0xAA;
         expect_pulse 0x7D;
      }
      expect_lha $baseaddr >> 8;
      expect_pulse 0x64;
      expect_sdo_high;
   }
   expect_cmd 0;

   await $chip->write_flash( "\x55\xAA" x 1024 );

   expect_done '->write_flash';
}

# eeprom
{
   # read
   expect_cmd 0x03;
   expect_lla 10;
   expect_lha 0;
   expect_rlb 0x56;

   is( await $chip->read_eeprom( start => 10, bytes => 1 ), "\x56",
      '$chip->read_eeprom yields bytes' );

   expect_done '->read_eeprom';

   # write
   # TODO: There isn't yet API to write a small fragment, so we'll have to test
   # the whole 128 bytes
   expect_cmd 0x11;
   foreach my $baseaddr ( map { $_ * 4 } 0 .. (128/4) - 1 ) {
      # fill the page buffer
      foreach my $addr ( $baseaddr .. $baseaddr + 4 - 1 ) {
         expect_lla $addr & 0xFF;
         expect_lha 0;
         expect_lld ord 'X';
         expect_pulse 0x6D;
      }
      expect_pulse 0x64;
      expect_sdo_high;
   }
   expect_cmd 0;

   await $chip->write_eeprom( "X" x 128 );

   expect_done '->write_eeprom';
}

done_testing;

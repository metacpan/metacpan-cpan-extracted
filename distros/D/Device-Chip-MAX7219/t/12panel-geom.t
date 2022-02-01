#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MAX7219Panel;

my $adapter = Test::Device::Chip::Adapter->new;

# From here onwards, just capture the bytes written to the digits registers;
# makes the rest of the testing simpler
no warnings 'redefine';

my @DISPLAY;
local *Device::Chip::MAX7219Panel::_write_raw = sub {
   shift;
   my ( $digit, $data ) = @_;
   # Convert this to a human-readable hex string, because otherwise is_deeply
   # prints raw binary strings to the terminal on test failure
   # Undo the "flip" options
   $DISPLAY[7-$digit] = reverse sprintf "%v.08B", $data;
   Future->done;
};

# wider than default at 8 chips
{
   my $panel = Device::Chip::MAX7219Panel->new( geom => "64x8" );
   is( $panel->rows,     8, 'rows for geom 64x8' );
   is( $panel->columns, 64, 'columns for geom 64x8' );

   $adapter->expect_write( "\x0B\x07" x 8 ); # REG_LIMIT
   $adapter->expect_write( "\x09\x00" x 8 ); # REG_DECODE

   await $panel->mount( $adapter );
   await $panel->init;

   $adapter->check_and_clear( '->init for geom 64x8' );

   $adapter->expect_write( "\x0C\x00" x 8 ); # REG_SHUTDOWN
   $adapter->expect_write( "\x0C\x01" x 8 ); # REG_SHUTDOWN

   $panel->clear;
   $panel->draw_hline( 0, $panel->columns-1, 4 );
   $panel->draw_vline( 12, 0, $panel->rows-1 );
   await $panel->refresh;

   is_deeply( \@DISPLAY,
      [ "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000",
        "11111111.11111111.11111111.11111111.11111111.11111111.11111111.11111111",
        "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00000000.00000000.00000000" ],
      'Display after ->draw_hline for geom 64x8' );

   $adapter->check_and_clear( '->refresh for geom 64x8' );
}

# taller than default at two modules height
{
   my $panel = Device::Chip::MAX7219Panel->new( geom => "32x16" );
   is( $panel->rows,    16, 'rows for geom 32x16' );
   is( $panel->columns, 32, 'columns for geom 32x16' );

   $adapter->expect_write( "\x0B\x07" x 8 ); # REG_LIMIT
   $adapter->expect_write( "\x09\x00" x 8 ); # REG_DECODE

   await $panel->mount( $adapter );
   await $panel->init;

   $adapter->check_and_clear( '->init for geom 32x16' );

   $adapter->expect_write( "\x0C\x00" x 8 ); # REG_SHUTDOWN
   $adapter->expect_write( "\x0C\x01" x 8 ); # REG_SHUTDOWN

   $panel->clear;
   $panel->draw_hline( 0, $panel->columns-1, 4 );
   $panel->draw_vline( 12, 0, $panel->rows-1 );
   await $panel->refresh;

   is_deeply( \@DISPLAY,
      [ "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000",
        "11111111.11111111.11111111.11111111.00000000.00001000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000",
        "00000000.00001000.00000000.00000000.00000000.00001000.00000000.00000000" ],
      'Display after ->draw_hline for geom 32x16' );

   $adapter->check_and_clear( '->refresh for geom 32x16' );
}

done_testing;

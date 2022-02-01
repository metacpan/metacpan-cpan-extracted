#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MAX7219Panel;

my $chip = Device::Chip::MAX7219Panel->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->draw_pixel
{
   $adapter->expect_write( "\x0C\x00\x0C\x00\x0C\x00\x0C\x00" ); # REG_SHUTDOWN = blank
   $adapter->expect_write( "\x08\x00\x08\x00\x08\x00\x08\x00" ); # REG_DIGIT 7
   $adapter->expect_write( "\x07\x00\x07\x00\x07\x00\x07\x00" ); # REG_DIGIT 6
   $adapter->expect_write( "\x06\x00\x06\x00\x06\x00\x06\x00" ); # REG_DIGIT 5
   $adapter->expect_write( "\x05\x00\x05\x00\x05\x00\x05\x00" ); # REG_DIGIT 4
   $adapter->expect_write( "\x04\x00\x04\x00\x04\x00\x04\x00" ); # REG_DIGIT 3
   $adapter->expect_write( "\x03\x00\x03\x00\x03\x00\x03\x00" ); # REG_DIGIT 2
   $adapter->expect_write( "\x02\x00\x02\x00\x02\x00\x02\x00" ); # REG_DIGIT 1
   $adapter->expect_write( "\x01\x00\x01\x00\x01\x00\x01\x00" ); # REG_DIGIT 0
   $adapter->expect_write( "\x0C\x01\x0C\x01\x0C\x01\x0C\x01" ); # REG_SHUTDOWN = display

   $chip->clear;
   await $chip->refresh;

   $adapter->expect_write( "\x0C\x00\x0C\x00\x0C\x00\x0C\x00" );
   $adapter->expect_write( "\x08\x00\x08\x00\x08\x00\x08\x00" );
   $adapter->expect_write( "\x07\x00\x07\x00\x07\x00\x07\x00" );
   $adapter->expect_write( "\x06\x00\x06\x00\x06\x00\x06\x04" );
   $adapter->expect_write( "\x05\x00\x05\x00\x05\x00\x05\x00" );
   $adapter->expect_write( "\x04\x00\x04\x00\x04\x00\x04\x00" );
   $adapter->expect_write( "\x03\x00\x03\x00\x03\x00\x03\x00" );
   $adapter->expect_write( "\x02\x00\x02\x00\x02\x00\x02\x00" );
   $adapter->expect_write( "\x01\x00\x01\x00\x01\x00\x01\x00" );
   $adapter->expect_write( "\x0C\x01\x0C\x01\x0C\x01\x0C\x01" );

   $chip->draw_pixel( 2, 2 );
   await $chip->refresh;

   $adapter->check_and_clear( '->draw_pixel' );
}

# From here onwards, just capture the bytes written to the digits registers;
# makes the rest of the testing simpler
no warnings 'redefine';

local *Device::Chip::MAX7219Panel::_all_writereg = sub { Future->done; };

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

# ->draw_hline, ->draw_vline
{
   $chip->draw_hline( 5, 25, 4 );
   await $chip->refresh;

   is_deeply( \@DISPLAY,
      [ "00000000.00000000.00000000.00000000",
        "00000000.00000000.00000000.00000000",
        "00100000.00000000.00000000.00000000",
        "00000000.00000000.00000000.00000000",
        "00000111.11111111.11111111.11000000",
        "00000000.00000000.00000000.00000000",
        "00000000.00000000.00000000.00000000",
        "00000000.00000000.00000000.00000000" ],
      'Written registers after ->draw_hline' );

   $chip->draw_vline( 27, 1, 6 );
   await $chip->refresh;

   is_deeply( \@DISPLAY,
      [ "00000000.00000000.00000000.00000000",
        "00000000.00000000.00000000.00010000",
        "00100000.00000000.00000000.00010000",
        "00000000.00000000.00000000.00010000",
        "00000111.11111111.11111111.11010000",
        "00000000.00000000.00000000.00010000",
        "00000000.00000000.00000000.00010000",
        "00000000.00000000.00000000.00000000" ],
      'Written registers after ->draw_vline' );
}

# ->draw_blit
{
   $chip->draw_blit( 15, 1,
      "X    X",
      "XX  XX",
      "X XX X",
      "X XX X",
      "XX  XX",
      "X    X" );
   await $chip->refresh;

   is_deeply( \@DISPLAY,
      [ "00000000.00000000.00000000.00000000",
        "00000000.00000001.00001000.00010000",
        "00100000.00000001.10011000.00010000",
        "00000000.00000001.01101000.00010000",
        "00000111.11111111.11111111.11010000",
        "00000000.00000001.10011000.00010000",
        "00000000.00000001.00001000.00010000",
        "00000000.00000000.00000000.00000000" ],
      'Written registers after ->draw_blit' );
}

# xflip
$chip->set_xflip( 1 );
$chip->clear;
$chip->draw_pixel( 1, 1 );
await $chip->refresh;

is_deeply( \@DISPLAY, 
   [ "00000000.00000000.00000000.00000000",
     "00000000.00000000.00000000.00000010",
    ("00000000.00000000.00000000.00000000") x 6 ],
   'Written registers with ->xflip = 1' );

# yflip
$chip->set_yflip( 1 );
$chip->clear;
$chip->draw_pixel( 1, 1 );
await $chip->refresh;

is_deeply( \@DISPLAY, 
   [("00000000.00000000.00000000.00000000") x 6,
     "00000000.00000000.00000000.00000010",
     "00000000.00000000.00000000.00000000" ],
   'Written registers with ->yflip = 1' );

done_testing;

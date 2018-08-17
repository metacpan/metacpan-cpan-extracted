#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Device::Chip::SSD1306;

use Future;

my @output;
no warnings 'once';
local *Device::Chip::SSD1306::send_cmd = sub {
   shift;
   push @output, [ cmd => @_ ];
   return Future->done;
};
local *Device::Chip::SSD1306::send_data = sub {
   shift;
   push @output, [ data => unpack "H*", $_[0] ];
   return Future->done;
};

my $chip = Device::Chip::SSD1306->new;

# whole output draw
{
   $chip->clear;

   undef @output;
   $chip->refresh->get;

   my @expect = (
      # all blank
      ( '00'x(128) ) x 8,
   );
   is_deeply( \@output,
      [
         map {
            my $page = $_;

            [ cmd => 0xB0 + $page ], # CMD_SET_PAGE_START
            [ cmd => 0x00 ], # CMD_SET_LOW_COLUMN
            [ cmd => 0x10 ], # CMD_SET_HIGH_COLUMN
            [ data => $expect[$page] ],
         } 0 .. 7
      ],
      'output for ->refresh after ->clear'
   );
}

# dirty pages
{
   $chip->draw_hline( 0, 31, 2 );
   $chip->draw_vline( 2, 0, 31 );
   $chip->draw_pixel( 8, 8 );
   $chip->draw_blit( 12, 16, ( " # #", "# # " ) x 4 );

   undef @output;
   $chip->refresh->get;

   my @expect = (
      # page 0 - row 2 is set for first 32 columns, also all of column 2
      '0404ff' . '04'x(32-3),
      # page 1 - all of column 2, plus row 0, column 8
      '0000ff0000000000' . '01' . '00'x23,
      # page 2 - all of column 2 then checkerboard at 12..15
      '0000ff' . '00'x9 . 'aa55aa55' . '00'x16,
      # page 3 - all of column 2
      '0000ff' . '00'x29,
      # pages 4 to 7 - no output
   );
   is_deeply( \@output,
      [
         map {
            my $page = $_;

            [ cmd => 0xB0 + $page ], # CMD_SET_PAGE_START
            [ cmd => 0x00 ], # CMD_SET_LOW_COLUMN
            [ cmd => 0x10 ], # CMD_SET_HIGH_COLUMN
            [ data => $expect[$page] ],
         } 0 .. $#expect
      ],
      'output for ->refresh after drawing'
   );
}

done_testing;

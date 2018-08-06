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
   push @output, [ data => @_ ];
   return Future->done;
};

# SSD1306-128x64
{
   my $chip = Device::Chip::SSD1306->new();

   is( $chip->columns, 128, '$chip->columns for default (SSD1306-128x64)' );
   is( $chip->rows,    64,  '$chip->rows for default (SSD1306-128x64)' );

   undef @output;
   $chip->send_display( "\x55" x (128*64/8) )->get;
   is_deeply( \@output,
      [
         map {
            my $page = $_;

            [ cmd => 0xB0 + $page ], # CMD_SET_PAGE_START
            [ cmd => 0x00 ], # CMD_SET_LOW_COLUMN
            [ cmd => 0x10 ], # CMD_SET_HIGH_COLUMN
            [ data => "\x55" x (128) ],
         } 0 .. 7
      ],
      'output for ->send_display for SSD1306-128x64'
   );

   $chip = Device::Chip::SSD1306->new( model => "SSD1306-128x64" );

   is( $chip->rows,    64,  '$chip->rows for SSD1306-128x64' );
}

# SSD1306-128x32
{
   my $chip = Device::Chip::SSD1306->new( model => "SSD1306-128x32" );

   is( $chip->columns, 128, '$chip->columns for SSD1306-128x32' );
   is( $chip->rows,    32,  '$chip->rows for SSD1306-128x32' );

   undef @output;
   $chip->send_display( "\x55" x (128*32/8) )->get;
   is_deeply( \@output,
      [
         map {
            my $page = $_;

            [ cmd => 0xB0 + $page ], # CMD_SET_PAGE_START
            [ cmd => 0x00 ], # CMD_SET_LOW_COLUMN
            [ cmd => 0x10 ], # CMD_SET_HIGH_COLUMN
            [ data => "\x55" x (128) ],
         } 0 .. 3
      ],
      'output for ->send_display for SSD1306-128x32'
   );
}

# SSD1306-64x32
{
   my $chip = Device::Chip::SSD1306->new( model => "SSD1306-64x32" );

   is( $chip->columns, 64, '$chip->columns for SSD1306-64x32' );
   is( $chip->rows,    32, '$chip->rows for SSD1306-64x32' );

   undef @output;
   $chip->send_display( "\x55" x (64*32/8) )->get;
   is_deeply( \@output,
      [
         map {
            my $page = $_;

            [ cmd => 0xB0 + $page ], # CMD_SET_PAGE_START
            [ cmd => 0x00 ], # CMD_SET_LOW_COLUMN
            [ cmd => 0x12 ], # CMD_SET_HIGH_COLUMN
            [ data => "\x55" x (64) ],
         } 0 .. 3
      ],
      'output for ->send_display for SSD1306-64x32'
   );
}

# SH1106
{
   my $chip = Device::Chip::SSD1306->new( model => "SH1106-128x64" );

   is( $chip->columns, 128, '$chip->columns for SH1106-128x64' );
   is( $chip->rows,    64,  '$chip->rows for SH1106-128x64' );

   undef @output;
   $chip->send_display( "\x55" x (128*64/8) )->get;
   is_deeply( \@output,
      [
         map {
            my $page = $_;

            [ cmd => 0xB0 + $page ], # CMD_SET_PAGE_START
            [ cmd => 0x02 ], # CMD_SET_LOW_COLUMN
            [ cmd => 0x10 ], # CMD_SET_HIGH_COLUMN
            [ data => "\x55" x (128) ],
         } 0 .. 7
      ],
      'output for ->send_display for SH1106-128x64'
   );
}

done_testing;

#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Font::PCF;

use constant FONT => "/usr/share/fonts/X11/misc/8x13.pcf.gz";
BEGIN {
   -f FONT or plan skip_all => "No font " . FONT;
}

my $font = Font::PCF->open( FONT );

ok( my $glyph = $font->get_glyph_for_char( "X" ),
   '$font has "X" glyph' );

# This test is sensitive to the exact glyph bitmap in the file but it should
# hopefully be portable enough.
is( $glyph->bitmap,
   [ 0, 0,
     0b10000010000000000000000000000000,
     0b10000010000000000000000000000000,
     0b01000100000000000000000000000000,
     0b00101000000000000000000000000000,
     0b00010000000000000000000000000000,
     0b00101000000000000000000000000000,
     0b01000100000000000000000000000000,
     0b10000010000000000000000000000000,
     0b10000010000000000000000000000000,
     0, 0,
   ],
   '$glyph bitmap' );

is( $glyph->name, "X",
   '$glyph name' );

done_testing;

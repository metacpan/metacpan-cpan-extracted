#!/usr/bin/perl -T
use strict;
use warnings;

use Test::More tests => 4;
use Test::BinaryData;
use Image::PNG::Write::BW qw( :all );

my $png_1x1_black =
  "\x89PNG\x0d\x0a\x1a\x0a\0\0\0\x0d".
  "IHDR\0\0\0\x01\0\0\0\x01".
  "\x01\0\0\0\0\x37\x6e\xf9\x24\0\0\0".
  "\x0aIDAT\x78\x9c\x63\x60\0\0\0".
  "\x02\0\x01\x48\xaf\xa4\x71\0\0\0\0\x49".
  "END\xae\x42\x60\x82";

is_binary( make_png_bitstream_raw(    "\0\0" ,1,1), $png_1x1_black, "raw" );
is_binary( make_png_bitstream_packed( "\0"   ,1,1), $png_1x1_black, "packed" );
is_binary( make_png_bitstream_array(  ["\0"] ,1),   $png_1x1_black, "array" );
is_binary( make_png_string(           ["#"]  ),     $png_1x1_black, "string" );

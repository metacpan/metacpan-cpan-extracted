#!/usr/bin/perl -w
use strict;

use Font::FreeType;
use POSIX qw( ceil );

die "Usage: $0 font-filename character/Unicode-number > glyph.svg\n"
  unless @ARGV == 2;
my ($filename, $char) = @ARGV;

my $face = Font::FreeType->new->face($filename,
                                     load_flags => FT_LOAD_NO_HINTING);
$face->set_char_size(24, 0, 600, 600);

# Accept character codes in hex or decimal, otherwise assume it's the
# actual character itself.
if ($char =~ /^0x[\dA-F]+$/i) { $char = hex $char }
elsif ($char !~ /^\d+$/)      { $char = ord $char }
my $glyph = $face->glyph_from_char_code($char);
die "No glyph for character '$char'.\n" unless $glyph;
die "Glyph has no outline.\n" unless $glyph->has_outline;

my ($xmin, $ymin, $xmax, $ymax) = $glyph->outline_bbox;
$xmax = ceil $xmax;  $ymax = ceil $ymax;

my $path = $glyph->svg_path;

print "<?xml version='1.0' encoding='UTF-8'?>\n",
      "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\"\n",
      "    \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n\n",
      "<svg xmlns='http://www.w3.org/2000/svg' version='1.0'\n",
      "     width='$xmax' height='$ymax'>\n\n",
      # Transformation to flip it upside down and move it back down into
      # the viewport.
      " <g transform='scale(1 -1) translate(0 -$ymax)'>\n",
      "  <path d='$path'\n",
      "        style='fill: #77FFCC; stroke: #000000'/>\n\n",
      " </g>\n",
      "</svg>\n";

# vi:ts=4 sw=4 expandtab

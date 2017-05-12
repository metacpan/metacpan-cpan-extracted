#!/usr/bin/perl -w
use strict;

use Font::FreeType;
use POSIX qw( floor ceil );

die "Usage: $0 font-filename character/Unicode-number > glyph.eps\n"
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
$xmin = floor $xmin;  $ymin = floor $ymin;
$xmax = ceil $xmax;  $ymax = ceil $ymax;

print "%%!PS-Adobe-3.0 EPSF-3.0\n",
      "%%Creator: $0\n",
      "%%BoundingBox: $xmin $ymin $xmax $ymax\n",
      "%%Pages: 1\n",
      "%\%EndComments\n\n",
      "%%Page: 1 1\n",
      "gsave newpath\n",
      $glyph->postscript,
      "closepath fill grestore\n",
      "%\%EOF\n";

# vi:ts=4 sw=4 expandtab

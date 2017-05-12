#!/usr/bin/perl -w
use strict;
use Font::FreeType;

die "Usage: $0 font-filename character/Unicode-number [point-size] > foo.pgm\n"
  unless @ARGV >= 2 && @ARGV <= 3;
my ($filename, $char, $size) = @ARGV;

my $dpi = 100;

my $face = Font::FreeType->new->face($filename);

# If the size wasn't specified, and it's a bitmap font, then leave the size
# to the default, which will be right.
if ($face->is_scalable || $size) {
    $size ||= 72;
    $face->set_char_size($size, $size, $dpi, $dpi);
}

# Accept character codes in hex or decimal, otherwise assume it's the
# actual character itself.
if ($char =~ /^0x[\dA-F]+$/i) { $char = hex $char }
elsif ($char !~ /^\d+$/)      { $char = ord $char }
my $glyph = $face->glyph_from_char_code($char);
die "No glyph for character '$char'.\n" unless $glyph;

my ($pgm, $left, $top) = $glyph->bitmap_pgm;
print $pgm;

# vi:ts=4 sw=4 expandtab

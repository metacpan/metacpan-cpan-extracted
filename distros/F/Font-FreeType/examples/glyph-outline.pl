#!/usr/bin/perl -w
use strict;
use Font::FreeType;

die "Usage: $0 font-filename character/Unicode-number [point-size]\n"
  unless @ARGV >= 2 && @ARGV <= 3;
my ($filename, $char, $size) = @ARGV;

my $dpi = 72;   # PostScript points.

my $face = Font::FreeType->new->face($filename);

$size ||= 72;
$face->set_char_size($size, $size, $dpi, $dpi);

# Accept character codes in hex or decimal, otherwise assume it's the
# actual character itself.
if ($char =~ /^0x[\dA-F]+$/i) { $char = hex $char }
elsif ($char !~ /^\d+$/)      { $char = ord $char }
my $glyph = $face->glyph_from_char_code($char);
die "No glyph for character '$char'.\n" unless $glyph;

# Now extract the outline.
$glyph->outline_decompose(
    move_to => sub {
        my ($x, $y) = @_;
        print "move_to $x, $y\n";
    },
    line_to => sub {
        my ($x, $y) = @_;
        print "line_to $x, $y\n";
    },
    conic_to => sub {
        my ($x, $y, $cx, $cy) = @_;
        print "conic_to $x, $y, $cx, $cy\n";
    },
    cubic_to => sub {
        my ($x, $y, $cx1, $cy1, $cx2, $cy2) = @_;
        print "cubic_to $x, $y, $cx1, $cy1, $cx2, $cy2\n";
    },
);

# vi:ts=4 sw=4 expandtab

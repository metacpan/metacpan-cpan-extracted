#!/usr/bin/perl -w
use strict;

# This program demonstrates using Font::FreeType with Image::Magick.
# It uses the font metrics to position glyphs next to each other as
# a typesetting engine would, and renders them both by compositing a
# bitmap of each glyph onto the output image (using the bitmap_magick()
# convenience method) and by drawing the outline using ImageMagick
# drawing functions.

# TODO - use kerning.

use Font::FreeType;
use Image::Magick;
use List::Util qw( sum );

my $text = "\xC2g.";     # 'Ag.', with a circumflex over the 'A'
my $size = 72;
my $dpi = 600;
my $border = 23;

die "Usage: $0 font-filename output-filename.png\n"
  unless @ARGV == 2;

my ($font_filename, $output_filename) = @ARGV;
my $face = Font::FreeType->new->face($font_filename);
$face->set_char_size($size, $size, $dpi, $dpi);

# Find the glyphs of the string.
my @glyphs = map { $face->glyph_from_char_code(ord $_) } split //, $text;

# Work out how big the text will be.
my $width = sum map { $_->horizontal_advance } @glyphs;
$width -= $glyphs[0]->left_bearing;
$width -= $glyphs[-1]->right_bearing;
my $height = $face->height;
$width += $border * 2;
$height += $border * 2;

my $img = Image::Magick->new(size => "${width}x$height");
$img->Read('xc:white');
$img->Set(stroke => '#0000AA');

my $origin_y = -$face->descender + $border;
my ($text_x, $text_y) = (-$glyphs[0]->left_bearing + $border, $origin_y);

my (undef, $adj_base_y) = adjust_position(0, 0);
my (undef, $adj_top_y) = adjust_position(0, $face->ascender);
my (undef, $adj_btm_y) = adjust_position(0, $face->descender);
$img->Draw(primitive => 'line', points => "0,$adj_base_y $width,$adj_base_y",
           stroke => '#FF0000');
$img->Draw(primitive => 'line', points => "0,$adj_top_y $width,$adj_top_y",
           stroke => '#00FF00');
$img->Draw(primitive => 'line', points => "0,$adj_btm_y $width,$adj_btm_y",
           stroke => '#00FF00');

foreach (@glyphs) {
    my ($adj_x, $adj_y) = adjust_position(0, 0);

    my ($bmp_img, $bmp_left, $bmp_top) = $_->bitmap_magick;
    $bmp_img->Modulate(brightness => 23);   # Light grey, not black.
    $img->Composite(image => $bmp_img, compose => 'Difference',
                    x => $adj_x + $bmp_left, y => $adj_y - $bmp_top);

    my $curr_pos;
    $_->outline_decompose(
        move_to => sub {
            my ($x, $y) = @_;
            ($x, $y) = adjust_position($x, $y);
            $curr_pos = "$x,$y";
        },
        line_to => sub {
            my ($x, $y) = @_;
            ($x, $y) = adjust_position($x, $y);
            $img->Draw(primitive => 'line', points => "$curr_pos $x,$y");
            $curr_pos = "$x,$y";
        },
        cubic_to => sub {
            my ($x, $y, $cx1, $cy1, $cx2, $cy2) = @_;
            ($x, $y) = adjust_position($x, $y);
            ($cx1, $cy1) = adjust_position($cx1, $cy1);
            ($cx2, $cy2) = adjust_position($cx2, $cy2);
            $img->Draw(primitive => 'bezier',
                       points => "$curr_pos $cx1,$cy1 $cx2,$cy2 $x,$y");
            $curr_pos = "$x,$y";
        },
    );

    $img->Draw(primitive => 'line', points => "$adj_x,0 $adj_x,$height",
               stroke => '#CCCC00');

    $text_x += $_->horizontal_advance;
}

my ($adj_x, undef) = adjust_position(0, 0);
$img->Draw(primitive => 'line', points => "$adj_x,0 $adj_x,$height",
           stroke => '#CCCC00');

$img->Write($output_filename);


# Y coordinates need to be flipped over, and both x and y adjusted to the
# position of the character.
sub adjust_position
{
    my ($x, $y) = @_;
    $x += $text_x;
    $y = $height - $y - $text_y;
    return ($x, $y);
}

# vi:ts=4 sw=4 expandtab

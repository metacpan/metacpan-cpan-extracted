# Render bitmaps from an outline font.

use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use Font::FreeType;

my @test = (
    { char => 'A', x_sz => 72, y_sz => 72, x_res => 72, y_res => 72, aa => 0 },
    { char => 'A', x_sz => 72, y_sz => 72, x_res => 72, y_res => 72, aa => 1 },
    { char => 'A', x_sz => 8, y_sz => 8, x_res => 100, y_res => 100, aa => 1 },
    { char => 'A', x_sz => 8, y_sz => 8, x_res => 100, y_res => 100, aa => 0 },
    { char => 'A', x_sz => 8, y_sz => 8, x_res => 600, y_res => 600, aa => 0 },
    { char => '.', x_sz => 300, y_sz => 300, x_res => 72, y_res => 72, aa => 1 },
);
plan tests => scalar(@test) * 3 + 2;

my $data_dir = catdir(qw( t data ));

# Load the TTF file.
# Hinting is turned off, because otherwise the compile-time option to turn
# it on (if you've licensed the patent) might otherwise make the tests fail
# for some people.  This should make it always the same, unless the library
# changes the rendering algorithm.
my $vera = Font::FreeType->new->face(catfile($data_dir, 'Vera.ttf'),
                                     load_flags => FT_LOAD_NO_HINTING);

foreach (@test) {
    my $test_filename = join('.', sprintf('%04X', ord $_->{char}),
                             @{$_}{qw( x_sz y_sz x_res y_res aa )}) . '.pgm';
    $test_filename = catfile($data_dir, $test_filename);
    open my $bmp_file, '<', $test_filename
      or die "error opening test bitmap data file '$test_filename': $!";
    $vera->set_char_size($_->{x_sz}, $_->{y_sz}, $_->{x_res}, $_->{y_res});
    my $glyph = $vera->glyph_from_char($_->{char});
    my $mode = $_->{aa} ? FT_RENDER_MODE_NORMAL : FT_RENDER_MODE_MONO;
    my ($pgm, $left, $top) = $glyph->bitmap_pgm($mode);
    ok defined $pgm;
    ok defined $left;
    ok defined $top;
}

# Check that after getting an outline we can still render the bitmap.
my $glyph = $vera->glyph_from_char_code(ord 'B');
my $ps = $glyph->postscript;
my ($bmp, $left, $top) = $glyph->bitmap;
ok($ps && $bmp, 'can get both outline and then bitmap from glyph');

# And the other way around.
$glyph = $vera->glyph_from_char_code(ord 'C');
($bmp, $left, $top) = $glyph->bitmap;
$ps = $glyph->postscript;
ok($ps && $bmp, 'can get both bitmap and then outline from glyph');

# vim:ft=perl ts=4 sw=4 expandtab:

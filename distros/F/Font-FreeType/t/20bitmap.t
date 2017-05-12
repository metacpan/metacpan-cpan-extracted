# Extract bitmaps from a some bitmap fonts and check that they match the
# images in the 'bdf_bitmaps.txt' file, which were extracted by hand.

use strict;
use warnings;
use File::Spec::Functions;
use Font::FreeType;

my $TESTS_PER_BITMAP_FONT;
BEGIN { $TESTS_PER_BITMAP_FONT = 4 * 3 };
# Two font formats tested, but we have to skip one set of tests for the FNT
# format, because it doesn't have the images above char code 255.
use Test::More tests => 2 * $TESTS_PER_BITMAP_FONT - 3;

my ($WD, $HT) = (5, 7);

my $data_dir = catdir(qw( t data ));
my $bmp_filename = catfile($data_dir, 'bdf_bitmaps.txt');

my $ft = Font::FreeType->new;

foreach my $fmt ('bdf', 'fnt') {
    # Skip BDF tests in versions of Freetype that don't have a BDF driver.
    if ($fmt eq 'bdf' && $ft->version lt '2.1.1') {
        SKIP: {
            skip 'BDF not supported until FreeType 2.1.1',
                 $TESTS_PER_BITMAP_FONT;
        }
        next;
    }

    # Load the bitmap font file file.
    my $face = $ft->face(catfile($data_dir, "5x7.$fmt"));

    # Load bitmaps from a file and compare them against ones from the font.
    open my $bmp_file, '<', $bmp_filename
      or die "error opening test bitmap data file '$bmp_filename': $!";
    while (<$bmp_file>) {
        /^([\dA-F]+)$/i or die "badly formated bitmap test file";
        my $unicode = $1;
        my $charcode = hex $unicode;
        my $desc = "$fmt format font, glyph $unicode";

        # Read test bitmap.
        my @expected;
        while (<$bmp_file>) {
            chomp;
            length == $WD or die "short line in bitmap test file";
            # It's easier to type spaces and hashes than these characters.
            s/ /\x00/g;
            s/#/\xFF/g;
            push @expected, $_;
            last if @expected == $HT;
        }

        # FNT doesn't do Unicode, it seems, and in older versions of FreeType
        # char 255 is inaccessible for some reason.
        next if $fmt eq 'fnt' && $charcode > 254;

        my $glyph = $face->glyph_from_char_code($charcode);
        my ($bmp, $left, $top) = $glyph->bitmap;
        is_deeply($bmp, \@expected, "$desc: bitmap image matches");
        is($left, 0, "$desc: bitmap starts 0 pixels to left of origin");
        is($top, 6, "$desc: bitmap starts 6 pixels above origin");
    }
}

# vim:ft=perl ts=4 sw=4 expandtab:

# Information obtained from looking at the BDF file.

use strict;
use warnings;
use File::Spec::Functions;
use Font::FreeType;

my $ft;
my $skip_all;
BEGIN {
    $ft = Font::FreeType->new;
    $skip_all = $ft->version lt '2.1.1';
}
use Test::More ($skip_all ?
    (skip_all => 'BDF not supported until FreeType 2.1.1') :
    (tests => 76 + 4 * 2 + 1836 * 1));
exit 0 if $skip_all;

my $data_dir = catdir(qw( t data ));

# Load the BDF file.
my $bdf = $ft->face(catfile($data_dir, '5x7.bdf'));
ok($bdf, 'FreeType->face() should return an object');
is(ref $bdf, 'Font::FreeType::Face',
    'FreeType->face() should return blessed ref');

# Test general properties of the face.
is($bdf->number_of_faces, 1, '$face->number_of_faces() is right');
is($bdf->current_face_index, 0, '$face->current_face_index() is right');

is($bdf->postscript_name, undef, 'there is no postscript name');
is($bdf->family_name, 'Fixed', '$face->family_name() is right');
is($bdf->style_name, 'Regular', 'no style name, defaults to "Regular"');

# Test face flags.
my %expected_flags = (
    # Note: glyph names are currently unsupported in FreeType for BDF fonts,
    # which is why it says there are none, when in fact there are.
    has_glyph_names => 0,
    has_horizontal_metrics => 1,
    has_kerning => 0,
    has_reliable_glyph_names => 0,
    has_vertical_metrics => 0,
    is_bold => 0,
    is_fixed_width => 1,
    is_italic => 0,
    is_scalable => 0,
    is_sfnt => 0,
);

foreach my $method (sort keys %expected_flags) {
    my $expected = $expected_flags{$method};
    my $got = $bdf->$method();
    if ($expected) {
        ok($bdf->$method(), "\$face->$method() method should return true");
    }
    else {
        ok(!$bdf->$method(), "\$face->$method() method should return false");
    }
}

# Some other general properties.
is($bdf->number_of_glyphs, 1837, '$face->number_of_glyphs() is right');
is($bdf->units_per_em, undef, 'units_per_em() meaningless');
is($bdf->underline_position, undef, 'underline position meaningless');
is($bdf->underline_thickness, undef, 'underline thickness meaningless');
is($bdf->ascender, undef, 'ascender meaningless');
is($bdf->descender, undef, 'descender meaningless');

# Test getting the set of fixed sizes available.
is(scalar $bdf->fixed_sizes, 1, 'BDF files have a single fixed size');
my ($fixed_size) = $bdf->fixed_sizes;
is($fixed_size->{width}, 5, 'fixed size width');
is($fixed_size->{height}, 7, 'fixed size width');
ok(abs($fixed_size->{size} - (70 / 722.7 * 72)) < 0.1,
   "fixed size is 70 printer's decipoints");
ok(abs($fixed_size->{x_res_dpi} - 72) < 1, 'fixed size x resolution 72dpi');
ok(abs($fixed_size->{y_res_dpi} - 72) < 1, 'fixed size y resolution 72dpi');
ok(abs($fixed_size->{size} * $fixed_size->{x_res_dpi} / 72
       - $fixed_size->{x_res_ppem}) < 0.1, 'fixed size x resolution in ppem');
ok(abs($fixed_size->{size} * $fixed_size->{y_res_dpi} / 72
       - $fixed_size->{y_res_ppem}) < 0.1, 'fixed size y resolution in ppem');

is $bdf->namedinfos, undef, "no named infos for fixed size font";
is $bdf->bounding_box, undef, "no bounding box for fixed size font";

# Test iterating over all the characters.  1836*1 tests.
my $glyph_list_filename = catfile($data_dir, 'bdf_glyphs.txt');
open my $glyph_list, '<', $glyph_list_filename
  or die "error opening file for list of glyphs: $!";
$bdf->foreach_char(sub {
    die "shouldn't be any argumetns passed in" unless @_ == 0;
    my $line = <$glyph_list>;
    die "not enough characters in listing file '$glyph_list_filename'"
      unless defined $line;
    chomp $line;
    my ($unicode, $name) = split ' ', $line;
    $unicode = hex $unicode;
    is($_->char_code, $unicode,
       "glyph $unicode char code in foreach_char()");
    # Can't test the name yet because it isn't implemented in FreeType.
    #is($_->name, $name, "glyph $unicode name in foreach_char()");
});
is(scalar <$glyph_list>, undef, "we aren't missing any glyphs");

subtest "charmaps" => sub {
    subtest "default charmap" => sub {
        my $default_cm = $bdf->charmap;
        ok $default_cm;
        is $default_cm->platform_id, 3;
        is $default_cm->encoding_id, 1;
        is $default_cm->encoding, FT_ENCODING_UNICODE;
    };

    subtest "available charmaps" => sub {
        my $charmaps = $bdf->charmaps;
        ok $charmaps;
        is ref($charmaps), 'ARRAY';
        is scalar(@$charmaps), 1;
    }
};

# Test metrics on some particlar glyphs.
my %glyph_metrics = (
    'A' => { name => 'A', advance => 5,
             LBearing => 0, RBearing => 0 },
    '_' => { name => 'underscore', advance => 5,
             LBearing => 0, RBearing => 0 },
    '`' => { name => 'grave', advance => 5,
             LBearing => 0, RBearing => 0 },
    'g' => { name => 'g', advance => 5,
             LBearing => 0, RBearing => 0 },
    '|' => { name => 'bar', advance => 5,
             LBearing => 0, RBearing => 0 },
);

# 4*2 tests.
foreach my $get_by_code (0 .. 1) {
    foreach my $char (sort keys %glyph_metrics) {
        my $glyph = $get_by_code ? $bdf->glyph_from_char_code(ord $char)
                                 : $bdf->glyph_from_char($char);
        die "no glyph for character '$char'" unless $glyph;
        local $_ = $glyph_metrics{$char};
        # Can't do names until it's implemented in FreeType.
        #is($glyph->name, $_->{name},
        #   "name of glyph '$char'");
        is($glyph->horizontal_advance, $_->{advance},
           "advance width of glyph '$char'");
        is($glyph->left_bearing, $_->{LBearing},
           "left bearing of glyph '$char'");
        is($glyph->right_bearing, $_->{RBearing},
           "right bearing of glyph '$char'");
        is($glyph->width, $_->{advance} - $_->{LBearing} - $_->{RBearing},
           "width of glyph '$char'");
    }
}

# Test kerning.
my %kerning = (
    __ => 0,
    AA => 0,
    AV => 0,
    'T.' => 0,
);

foreach my $pair (sort keys %kerning) {
    my ($kern_x, $kern_y) = $bdf->kerning(
        map { $bdf->glyph_from_char($_)->index } split //, $pair);
    is($kern_x, $kerning{$pair}, "horizontal kerning of '$pair'");
    is($kern_y, 0, "vertical kerning of '$pair'");
}

# Get just the horizontal kerning more conveniently.
my $kern_x = $bdf->kerning(
    map { $bdf->glyph_from_char($_)->index } 'A', 'V');
is($kern_x, 0, "horizontal kerning of 'AV' in scalar context");

# vim:ft=perl ts=4 sw=4 expandtab:

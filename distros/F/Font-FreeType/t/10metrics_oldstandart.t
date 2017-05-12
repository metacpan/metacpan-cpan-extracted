# Metrics obtained from OldStandard-Bold.otf via by hand using ftdump
# from freetype v2.5.3

use strict;
use warnings;
use Test::More tests => 27;
use File::Spec::Functions;
use Font::FreeType;

my $data_dir = catdir(qw( t data ));

my $ft = Font::FreeType->new;
my $font = $ft->face(catfile($data_dir, 'OldStandard-Bold.otf'));
ok($font, 'FreeType->face() should return an object');
is(ref $font, 'Font::FreeType::Face',
    'FreeType->face() should return blessed ref');

# Test general properties of the face.
is($font->number_of_faces, 1, '$face->number_of_faces() is right');
is($font->current_face_index, 0, '$face->current_face_index() is right');

is($font->postscript_name, 'OldStandard-Bold',
    '$face->postscript_name() is right');
is($font->family_name, 'Old Standard',
    '$face->family_name() is right');
is($font->style_name, 'Bold',
    '$face->style_name() is right');

# Test face flags.
my %expected_flags = (
    has_glyph_names => 1,
    has_horizontal_metrics => 1,
    has_kerning => 0,
    has_reliable_glyph_names => 1,
    has_vertical_metrics => 0,
    is_bold => 1,
    is_fixed_width => 0,
    is_italic => 0,
    is_scalable => 1,
    is_sfnt => 1,
);

foreach my $method (sort keys %expected_flags) {
    my $expected = $expected_flags{$method};
    my $got = $font->$method();
    if ($expected) {
        ok($font->$method(), "\$face->$method() method should return true");
    }
    else {
        ok(!$font->$method(), "\$face->$method() method should return false");
    }
}

# Some other general properties.
is($font->number_of_glyphs, 1658, '$face->number_of_glyphs() is right');
is($font->units_per_em, 1000, '$face->units_per_em() is right');
my $underline_position = $font->underline_position;
ok $underline_position <= -178 || $underline_position >= -198, 'underline position';
is($font->underline_thickness, 40, 'underline thickness');
is($font->height, 1482, 'text height');
is($font->ascender, 952, 'ascender');
is($font->descender, -294, 'descender');

subtest "charmaps" => sub {
    subtest "default charmap" => sub {
        my $default_cm = $font->charmap;
        ok $default_cm;
        is $default_cm->platform_id, 3;
        is $default_cm->encoding_id, 10;
        is $default_cm->encoding, FT_ENCODING_UNICODE;
    };

    subtest "available charmaps" => sub {
        my $charmaps = $font->charmaps;
        ok $charmaps;
        is ref($charmaps), 'ARRAY';
        is scalar(@$charmaps), 6;
    }
};

subtest "named infos" => sub {
    my $infos = $font->namedinfos;
    ok $infos;
    is scalar(@$infos), 64;
    my $copy_info = $infos->[0];
    like $copy_info->string, qr/Copyright.*Alexey Kryukov/;
    is $copy_info->language_id, 0;
    is $copy_info->platform_id, 1;
    is $copy_info->name_id, 0;
    is $copy_info->encoding_id, 0;
};

subtest "bounding box" => sub {
    my $bb = $font->bounding_box;
    ok $bb;
    is $bb->x_min, -868, "x_min is correct";
    is $bb->y_min, -294, "y_min is correct";
    is $bb->x_max, 1930, "x_max is correct";
    is $bb->y_max, 952,  "y_max is correct";
};

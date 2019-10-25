package Font::FreeType::CharMap;
use warnings;
use strict;

1;

__END__

=head1 NAME

Font::FreeType::CharMap - character map from font typefaces loaded from Font::FreeType

=head1 SYNOPSIS

    use Font::FreeType;

    my $freetype = Font::FreeType->new;
    my $face = $freetype->face('Vera.ttf');
    my $charmap = $face->charmap;
    say $charmap->platform_id;
    say $charmap->encoding_id;
    say $charmap->encoding;


=head1 DESCRIPTION

A charmap is used to translate character codes in a given encoding into glyph
indexes for its parent's face. Some font formats may provide several charmaps
per font.

=head1 CONSTANTS

The following encoding constants are exported by default by L<Font::FreeType>.
See L<freetype documentation|http://www.freetype.org/freetype2/docs/reference/ft2-base_interface.html#FT_Encoding>

=head2 FT_ENCODING_NONE

=head2 FT_ENCODING_UNICODE

=head2 FT_ENCODING_MS_SYMBOL

=head2 FT_ENCODING_SJIS

=head2 FT_ENCODING_GB2312

=head2 FT_ENCODING_BIG5

=head2 FT_ENCODING_WANSUNG

=head2 FT_ENCODING_JOHAB

=head2 FT_ENCODING_ADOBE_LATIN_1

=head2 FT_ENCODING_ADOBE_STANDARD

=head2 FT_ENCODING_ADOBE_EXPERT

=head2 FT_ENCODING_ADOBE_CUSTOM

=head2 FT_ENCODING_APPLE_ROMAN

=head2 FT_ENCODING_OLD_LATIN_2

=head2 FT_ENCODING_MS_SJIS

Same as FT_ENCODING_SJIS. Deprecated.

=head2 FT_ENCODING_MS_GB2312

Same as FT_ENCODING_GB2312. Deprecated.

=head2 FT_ENCODING_MS_BIG5

Same as FT_ENCODING_BIG5. Deprecated.

=head2 FT_ENCODING_MS_WANSUNG

Same as FT_ENCODING_WANSUNG. Deprecated.

=head2 FT_ENCODING_MS_JOHAB

Same as FT_ENCODING_JOHAB. Deprecated.

=head1 METHODS

=over 4

=item platform_id


An ID number describing the platform for the following encoding ID. This comes directly from the TrueType specification and should be emulated for other formats.

For details please refer to the TrueType or OpenType specification.

=item encoding_id

A platform specific encoding number. This also comes from the TrueType specification and should be emulated similarly.

For details please refer to the TrueType or OpenType specification.

=item encoding

An FreeType Encoding tag (constant) identifying the charmap.

=back


=cut

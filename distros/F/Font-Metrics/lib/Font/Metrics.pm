package Font::Metrics;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.02';

# Export our C symbols (fm_*) into the global namespace so downstream XS
# modules (e.g. Layout::Flex) can link against them at load time rather than
# recompiling the C sources. Consumers must load Font::Metrics first.
sub dl_load_flags { 0x01 }   # RTLD_GLOBAL

require XSLoader;
XSLoader::load('Font::Metrics', $VERSION);

1;

__END__

=encoding utf-8

=head1 NAME

Font::Metrics - advance widths, kerning and metrics for Standard 14 and TrueType fonts

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Font::Metrics;

    # Standard 14 font
    my $fm = Font::Metrics->new(name => 'Helvetica');
    printf "string width: %.2f pt\n", $fm->string_width('Hello World', 12);
    printf "line height:  %.2f pt\n", $fm->line_height(12);
    printf "kern A+V:     %.2f pt\n", $fm->kern_pair('A', 'V', 12);

    # TrueType font
    my $fm = Font::Metrics->new(file => '/path/to/font.ttf');
    printf "%.2f\n", $fm->string_width('Hello', 14);

=head1 DESCRIPTION

Font::Metrics provides accurate per-glyph advance widths, kerning pair
adjustments, and typographic metrics for the PDF Standard 14 fonts and for
TrueType/OpenType fonts loaded from disk.

All values are returned in points at the requested C<size>. The underlying
data for Standard 14 fonts is sourced from the Adobe AFM files; TrueType
metrics are read from the font's C<hhea>, C<hmtx>, C<cmap>, and C<kern>
tables.

=head1 METHODS

=head2 new(%args)

    my $fm = Font::Metrics->new(name => 'Helvetica');
    my $fm = Font::Metrics->new(file => '/path/to/font.ttf');

Create a metrics object. Pass C<name> for one of the Standard 14 PDF fonts
or C<file> for a TrueType/OpenType font path. Croaks on unrecognised names
or unreadable files.

Standard 14 font names: C<Courier>, C<Courier-Bold>, C<Courier-Oblique>,
C<Courier-BoldOblique>, C<Helvetica>, C<Helvetica-Bold>,
C<Helvetica-Oblique>, C<Helvetica-BoldOblique>, C<Times-Roman>,
C<Times-Bold>, C<Times-Italic>, C<Times-BoldItalic>, C<Symbol>,
C<ZapfDingbats>.

=head2 char_width($char, $size)

Advance width of the first character in C<$char> at C<$size> points.

=head2 string_width($text, $size)

Sum of advance widths of all characters in C<$text> at C<$size> points.
Does not apply kerning; add C<kern_pair> calls between character pairs for
precise measurement.

=head2 ascender($size)

Distance from baseline to top of capital letters at C<$size> points
(positive value).

=head2 descender($size)

Distance from baseline to bottom of descenders at C<$size> points
(negative value).

=head2 cap_height($size)

Height of capital letters at C<$size> points.

=head2 x_height($size)

Height of lower-case letters (e.g. C<x>) at C<$size> points.

=head2 line_height($size)

C<ascender - descender> at C<$size> points — the natural leading for
single-spaced text.

=head2 kern_pair($char1, $char2, $size)

Kerning adjustment between the first characters of C<$char1> and C<$char2>
at C<$size> points. Returns C<0> if no kern pair is defined. Add this value
to the advance width of C<$char1> when laying out the pair.

=head1 NOTES

=head2 TrueType / OpenType support

The loader reads C<head>, C<hhea>, C<OS/2>, C<cmap> (formats 4 and 12), C<hmtx>,
C<kern> (format 0), and C<GPOS> (PairPos formats 1 and 2) tables. Kerning from
both tables is merged; C<GPOS> takes precedence on conflicts. This covers
OpenType CFF fonts that store kerning exclusively in C<GPOS> with no C<kern>
table.

C<cap_height> and C<x_height> are taken from the OS/2 table version 2+
fields C<sCapHeight> / C<sxHeight>. For older fonts (OS/2 version 0 or 1),
C<cap_height> falls back to the C<sTypoAscender> value and C<x_height>
returns C<0>.

=head2 Standard 14 kerning

Kerning data for the Standard 14 fonts covers the most visually significant
Latin pairs (approximately 74 pairs for Helvetica variants and 83 pairs for
Times variants) sourced from the Adobe AFM files. Courier, Symbol, and
ZapfDingbats have no kern pairs.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut

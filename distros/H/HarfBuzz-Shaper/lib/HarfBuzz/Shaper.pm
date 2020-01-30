#! perl

package HarfBuzz::Shaper;

use 5.010001;
use strict;
use warnings;
use Carp;
use Encode;

our $VERSION = '0.018';

require XSLoader;
XSLoader::load('HarfBuzz::Shaper', $VERSION);

=head1 NAME

HarfBuzz::Shaper - Use HarfBuzz for text shaping

=head1 SYNOPSIS

    use HarfBuzz::Shaper;
    my $hb = HarfBuzz::Shaper->new;
    $hb->set_font('LiberationSans.ttf');
    $hb->set_size(36);
    $hb->set_text("Hello!");
    my $info = $hb->shaper;

The result is an array of hashes, one element for each glyph to be typeset.

=head1 DESCRIPTION

HarfBuzz::Shaper is a perl module that provides access to a small
subset of the native HarfBuzz library.

The subset is suitable for typesetting programs that need to deal with
complex languages like Devanagari.

This module is intended to be used with module L<Text::Layout>. Feel
free to (ab)use it for other purposes.

Following the above example, the returned info is an array of hashes,
one element for each glyph to be typeset. The hash contains the
following items:

    ax:   horizontal advance
    ay:   vertical advance
    dx:   horizontal offset
    dy:   vertical offset
    g:    glyph index in font (CId)
    name: glyph name

Note that the number of glyphs does not necessarily match the number
of input characters!

=head1 METHODS

=head2 $hb = HarfBuzz::Shaper->new( [ options ] )

Creates a new shaper object.

Options:

=over 4

=item *

B<font => > I<font filename>

=item *

B<size => > I<text size>

=back

=cut

sub new {
    my ( $pkg, $opts ) = @_;

    $opts //= {};

    my $self = bless {} => $pkg;
    $self->{harfbuzz} = hb_version_string();
    $self->{buf} = hb_buffer_create();

    if ( $opts->{font} ) {
	$self->set_font( delete $opts->{font} );
    }
    if ( $opts->{size} ) {
	$self->set_size( delete $opts->{size} );
    }

    return $self;
}

=head2 $hb->set_font( I<font filename> [ , I<size> ] )

Explicit way to set the font (and, optionally, the size) used for
shaping.

The font must be a TrueType or OpenType font. Font information is
cached internally, after the first call subsequent calls with the same
font filename are very fast.

=cut

sub set_font {
    my ( $self, $fontfile, $size ) = @_;

    my $blob = hb_blob_create_from_file($fontfile);
    my $face = $self->{"face_$fontfile"} //= hb_face_create( $blob, 0 );
    $self->{font} = $self->{"font_$fontfile"} //= do {
	# hb_font_create should default to OT.
	my $font = hb_font_create( $face );
	hb_ot_font_set_funcs($font);
	$font;
    };
    $self->set_size($size) if $size;

    $self;
}

=head2 $hb->set_size( I<size> )

Explicit way to set the font size used for shaping.

Note that the font size will in general affect details of the
appearance, A 5 point fontsize magnified 10 times is not identical to
50 point font size.

=cut

sub set_size {
    my ( $self, $size ) = @_;

    $self->{size} = $size;

    $self;
}

=head2 $hb->set_text( I<text> [ , ... ] )

Set the text to shape. Multiple arguments are concatenated.

Note that the text must be Perl strings.

=cut

sub set_text {
    my ( $self, @text ) = @_;

    $self->{text} = join( "", @text );

    $self;
}

=head2 $info = $hb->shaper()

Performs the shaping. Upon completion an array of hashes is returned
with one element for each glyph to be rendered.

The hash contains the following items:

    ax:   horizontal advance
    ay:   vertical advance
    dx:   horizontal offset
    dy:   vertical offset
    g:    glyph index in font (CId)
    name: glyph name

Note that the number of glyphs does not necessarily match the number
of input characters!

=cut

sub shaper {
    my ( $self ) = @_;

    croak("HarfBuzz shape() without font")     unless $self->{font};
    croak("HarfBuzz shape() without fontsize") unless $self->{size};
    croak("HarfBuzz shape() without text")     unless defined $self->{text};

    hb_buffer_clear_contents( $self->{buf} );
    hb_buffer_add_utf8( $self->{buf}, $self->{text} );

    hb_buffer_guess_segment_properties( $self->{buf} );

    # Set the font point size for correct hinting.
    hb_font_set_ptem( $self->{font}, $self->{size} );
    # Set a scaling for precision (all info are ints!).
    my $scale = 1000;
    hb_font_set_scale( $self->{font}, $scale, $scale );

    my $info = _hb_shaper( $self->{font}, $self->{buf} );

    foreach my $i ( @$info ) {
	$i->{$_} *= $self->{size} / $scale for qw( ax ay dx dy );
    }

    return $info;
}

1;

__END__

=head1 SEE ALSO

L<Text::Layout>

HarfBuzz website and documentation: L<https://harfbuzz.github.io/index.html>.

=head1 BUGS AND DEFICIENCIES

It probably leaks memory. We'll see.

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-HarfBuzz-Shaper.

You can find documentation for this module with the perldoc command.

    perldoc HarfBuzz::Shaper

Please report any bugs or feature requests using the issue tracker on
GitHub.

HarfBuzz website and documentation: L<https://harfbuzz.github.io/index.html>.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2020 by Johan Vromans

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

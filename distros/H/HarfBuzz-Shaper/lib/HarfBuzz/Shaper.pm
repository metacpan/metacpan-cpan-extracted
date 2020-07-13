#! perl

package HarfBuzz::Shaper;

use 5.010001;
use strict;
use warnings;
use Carp;
use Encode;

our $VERSION = '0.023';

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
complex languages like Devanagari, Hebrew or Arabic.

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

=head1 DISCLAIMER

This module provides a thin interface layer between Perl and the
native HarfBuzz library. It is agnostic with regard to the details of
multi-language typesetting. HarfBuzz has a friendly community to help
you.

L<https://lists.freedesktop.org/mailman/listinfo/harfbuzz>

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
    $self->{buffer} = hb_buffer_create();
    $self->{features} = [];

    if ( $opts->{font} ) {
	$self->set_font( delete $opts->{font} );
    }
    if ( $opts->{size} ) {
	$self->set_size( delete $opts->{size} );
    }

    return $self;
}

=head2 $hb->reset( [ I<full> ] )

Reset (clear) the buffer settings for font, size, language, direction
and script. With I<full>, also clears the font cache.

=cut

sub reset {
    my ( $self, $full ) = @_;

    for ( qw ( font size text language direction script ) ) {
	delete $self->{$_};
    }
    if ( $full ) {
	for ( keys %$self ) {
	    next unless /^(font|face)_/;
	    delete $self->{$_};
	}
	hb_buffer_reset( $self->{buffer} );
	# So basically we are like freshly created.
    }

    $self;
}

=head2 $hb->set_font( I<font filename> [ , I<size> ] )

Explicit way to set the font (and, optionally, the size) used for
shaping.

The settings persist across shaper() calls. Call without arguments to
remove the settings.

The font must be a TrueType or OpenType font. Font information is
cached internally, after the first call subsequent calls with the same
font filename are very fast.

=cut

sub set_font {
    my ( $self, $fontfile, $size ) = @_;

    unless ( defined $fontfile or defined $size ) {
	delete $self->{font};
	delete $self->{size};
	return $self;
    }

    croak("$fontfile: $!\n") unless -s -r $fontfile;
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

The setting persist across shaper() calls. Call without arguments to
remove the setting.

=cut

sub set_size {
    my ( $self, $size ) = @_;

    unless ( defined $size ) {
	delete $self->{size};
	return $self;
    }

    $self->{size} = $size;

    $self;
}

=head2 $hb->set_text( I<text> [ , ... ] )

Sets the text to shape. Multiple arguments are concatenated.

Note that the text must be Perl strings.

The setting persist across shaper() calls. Call without arguments to
remove the setting.

=cut

sub set_text {
    my ( $self, @text ) = @_;

    unless ( @_ > 1 and defined $text[0] ) {
	delete $self->{text};
	return $self;
    }

    $self->{text} = join( "", @text );

    $self;
}

=head2 $hb->set_features( I<feat> [ , ... ] )

Sets persistent features for shaping. Features are strings as described in
L<https://harfbuzz.github.io/harfbuzz-hb-common.html#hb-feature-from-string>
and
L<https://css-tricks.com/almanac/properties/f/font-feature-settings/#values>.

Multiple feature strings may be supplied.

Call without arguments to remove the persistent features.

=cut

sub set_features {
    my ( $self ) = shift;
    $self->{features} = [];
    $self->add_features(@_) if @_ && defined($_[0]);
    return $self;
}

=head2 $hb->add_features( I<feat> [ , ... ] )

Just like set_features, but the specified features are I<added> to the
set of persistent features.

=cut

sub add_features {
    my ( $self, @features ) = @_;
    foreach my $feature ( @features ) {
	push( @{ $self->{features} },
	      hb_feature_from_string($feature)
	      || croak("Unknown shaper feature: \"$feature\"") );
    }
}

=head2 $hb->set_language( I<lang> )

Sets the language for shaping. I<lang> must be a string containing a
valid BCP-47 language code.

The setting persist across shaper() calls. Call without arguments to
remove the setting.

=cut

sub set_language {
    my ( $self, $lang ) = @_;

    unless ( defined $lang ) {
	delete $self->{language};
	return $self;
    }

    $self->{language} = $lang;
    # This is merely for checking validity;
    hb_buffer_set_language( $self->{buffer}, $lang );
}

=head2 $hb->get_language

Returns the language currently set for this shaper, as a string.

When called after a successful shaper() call, it returns the actual
value used by shaper().

=cut

sub get_language {
    my ( $self ) = @_;
    hb_buffer_get_language( $self->{buffer} );
}

=head2 $hb->set_script( I<script> )

Sets the script (alphabet) for shaping. I<script> must be a string
containing a valid ISO-15924 script code. For example, C<"Latn"> for
the Latin (Western European) script, or C<"Arab"> for arabic script.

If you don't set a script, shaper() will make a guess based on the
text string. This may or may not yield desired results.

The setting persist across shaper() calls. Call without arguments to
remove the setting.

=cut

sub set_script {
    my ( $self, $script ) = @_;

    unless ( defined $script ) {
	delete $self->{script};
	return $self;
    }

    $self->{script} = $script;
    # This is merely for checking validity;
    hb_buffer_set_script( $self->{buffer}, $script );
}

=head2 $hb->get_script

Returns the script currently set for this shaper, as a string.

When called after a successful shaper() call, it returns the actual
value used by shaper().

=cut

sub get_script {
    my ( $self ) = @_;
    hb_buffer_get_script( $self->{buffer} );
}

=head2 $hb->set_direction( I<dir> )

Sets the direction for shaping. I<dir> must be a string containing a
valid direction setting: LTR (left-to-right), RTL (right-to-left), TTB
(top-to-bottom), or BTT (bottom-to-top).

If you don't set a direction, shaper() will make a guess based on the
text string. This may or may not yield desired results.

The setting persist across shaper() calls. Call without arguments to
remove the setting.

=cut

sub set_direction {
    my ( $self, $dir ) = @_;

    unless ( defined $dir ) {
	delete $self->{direction};
	return $self;
    }

    $self->{direction} = $dir;
    # This is merely for checking validity;
    hb_buffer_set_direction( $self->{buffer}, $dir );
}

=head2 $hb->get_direction

Returns the direction currently set for this shaper, as a string.

When called after a successful shaper() call, it returns the actual
value used by shaper().

=cut

sub get_direction {
    my ( $self ) = @_;
    hb_buffer_get_direction( $self->{buffer} );
}

=head2 $info = $hb->shaper( [ I<ref to features> ] )

Performs the actual shape operation.

I<features> is a reference to an array of feature strings. The
features will be I<added> to the list of features already set with
set_features/add_features. If the first (or only) feature is C<none>
all current features will be ignored and only subsequent features are
taken into account. Changes apply to this call only, the persistent
set of featutes is B<not> modified.

Upon completion an array of hashes is returned with one element for
each glyph to be rendered.

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
    my ( $self, $fp ) = @_;

    croak("HarfBuzz shape() without font")     unless $self->{font};
    croak("HarfBuzz shape() without fontsize") unless $self->{size};
    croak("HarfBuzz shape() without text")     unless defined $self->{text};

    my $features = $self->{features} || [];
    if ( $fp ) {
	foreach my $feature ( @$fp ) {
	    if ( "none" eq lc $feature ) {
		$features = [];
		next;
	    }
	    push( @$features,
		  hb_feature_from_string($feature)
		  || croak("Unknown shaper feature: \"$feature\"") );
	}
    }

    hb_buffer_clear_contents( $self->{buffer} );

    for ( qw( language script direction ) ) {
	next unless $self->{$_};
	# All setters return undef if something wrong.
	no strict 'refs';
	my $action = "hb_buffer_set_$_";
	$action->( $self->{buffer}, $self->{$_} )
	  || croak("Invalid $_: \"$self->{$_}\"" );
    }
    hb_buffer_add_utf8( $self->{buffer}, $self->{text} );

    hb_buffer_guess_segment_properties( $self->{buffer} );

    # Set the font point size for correct hinting.
    hb_font_set_ptem( $self->{font}, $self->{size} );
    # Set a scaling for precision (all info are ints!).
    my $scale = 1000;
    hb_font_set_scale( $self->{font}, $scale, $scale );
    my $info = hb_shaper( $self->{font}, $self->{buffer}, $features );

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

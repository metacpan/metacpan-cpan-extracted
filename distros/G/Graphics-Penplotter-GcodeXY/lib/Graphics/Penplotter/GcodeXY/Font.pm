package Graphics::Penplotter::GcodeXY::Font v0.7.2;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );
use strict;
use warnings;
use Role::Tiny;
use Carp        qw( croak );
use Readonly    qw( Readonly );
use Font::FreeType qw( FT_LOAD_NO_HINTING );

# ---------------------------------------------------------------------------
# Graphics::Penplotter::GcodeXY::Font
# Role providing TrueType font rendering for GcodeXY.
# ---------------------------------------------------------------------------

requires qw(_croak _flushPsegments newpath stroke gsave grestore translate _dohatching);

# ---------------------------------------------------------------------------
# Constants -- private copies of values defined in GcodeXY.pm.
# ---------------------------------------------------------------------------

Readonly my $EMPTY_STR => q{};
Readonly my $SPACE     => q{ };
Readonly my $EOL       => qq{\n};

# ---------------------------------------------------------------------------
# Module-level font search state
# ---------------------------------------------------------------------------

my $home      = $ENV{'HOME'};
my @locations = (
    './',
    $home . '/.fonts/',
    $home . '/.local/share/fonts/',
    '/usr/share/fonts/truetype/',
    '/usr/share/fonts/truetype/liberation/',
    '/usr/share/fonts/truetype/dejavu/',
    '/usr/share/fonts/truetype/msttcorefonts/',
    '/usr/share/fonts/',
    '/usr/local/share/fonts/',
    'C:/Windows/Fonts/',
);

# ===========================================================================
# FONT METHODS
# ===========================================================================

# Find, open and size a TrueType font face.
# Returns a Font::FreeType::Face object, or undef on failure.
sub setfont ($self, $font, $size = undef) {
    if ( !defined $font ) {
        $self->_croak('setfont: no font name specified');
        return undef;
    }
    my $nam = $self->findfont($font);
    if ( $nam eq $EMPTY_STR ) {
        $self->_croak( 'setfont: font ' . $font . ' not found' );
        return undef;
    }
    my $freetype = Font::FreeType->new;
    my $face     = $freetype->face( $nam, load_flags => FT_LOAD_NO_HINTING );
    if ( !defined $size ) {
        $size = $self->{fontsize};
    }
    if ( !defined $size ) {
        $self->_croak('setfont: no font size specified');
        return undef;
    }
    $self->{fontsize} = $size;
    $self->{fontname} = $nam;
    $face->set_char_size( $size, $size, 72, 72 );
    return $face;
}

# Globally set the current font size (does not open a font face).
sub setfontsize ($self, $size) {
    if ( !defined $size ) {
        $self->_croak('wrong number of args for setfontsize');
        return 0;
    }
    $self->{fontsize} = $size;
    return 1;
}

# Locate a font file by name, searching @locations.
# Returns the full path, or the empty string if not found.
sub findfont ($self, $name) {
    if ( !defined $name ) {
        $self->_croak('expecting 1 argument for findfont');
        return 0;
    }
    # Expand ~ to $HOME
    $name =~ s{\N{TILDE}}{$home};
    # If an absolute or relative path, return it directly if it exists
    if (   ( $name =~ m{\A\N{SOLIDUS}} )
        || ( $name =~ m{\A\N{FULL STOP}\N{FULL STOP}\N{SOLIDUS}} )
        || ( $name =~ m{\A\N{FULL STOP}\N{SOLIDUS}} ) )
    {
        return -e $name ? $name : $EMPTY_STR;
    }
    # Otherwise search the location list
    for my $dir (@locations) {
        my $path = $dir . $name;
        return $path if -f $path;
    }
    return $EMPTY_STR;
}

# Add one or more directories to the font search path.
sub addfontpath ($self, @paths) {
    if ( !@paths ) {
        $self->_croak('addfontpath: missing parameter(s)');
        return 0;
    }
    for my $path (@paths) {
        $path =~ s{\A\N{TILDE}}{$home};
        # Ensure trailing separator
        if (   ( $path !~ m{\N{SOLIDUS}\z} )
            && ( $path !~ m{\N{REVERSE SOLIDUS}\z} ) )
        {
            $path .= '/';
        }
        push @locations, $path;
    }
    return 1;
}

# Render a string without fill, advancing position after each glyph.
# The path is flushed after each character.
sub stroketext ($self, $face, $string) {
    if ( !defined $string ) {
        $self->_croak('stroketext: no string specified');
        return 0;
    }
    if ( !defined $face ) {
        $self->_croak('stroketext: no face specified');
        return 0;
    }
    $self->stroke();
    $self->_doglyphs( $face, $string, 0 );
    return 1;
}

# Render a string with hatch fill, advancing position after each glyph.
# The path is flushed after each character.
sub stroketextfill ($self, $face, $string) {
    if ( !defined $string ) {
        $self->_croak('stroketextfill: no string specified');
        return 0;
    }
    if ( !defined $face ) {
        $self->_croak('stroketextfill: no face specified');
        return 0;
    }
    $self->stroke();    # flush before hatching to avoid hatching previous shapes
    $self->_doglyphs( $face, $string, 1 );
    return 1;
}

# Return the total advance width of a string (including kerning).
sub textwidth ($self, $face, $s) {
    my @chars = split //, $s;
    my $len   = scalar @chars;
    my $k     = 0;
    my $hk    = $face->has_kerning();
    my ( $glyph, $adv );
    my $width = 0;
    my $gprev = undef;
    foreach my $i ( 0 .. $len - 1 ) {
        $glyph = $face->glyph_from_char_code( ord $chars[$i] );
        if ( !defined $glyph ) {
            $self->_croak( 'char not found in font: ' . $chars[$i] );
        }
        $adv = $glyph->horizontal_advance();
        if ( $gprev && $hk ) {
            $k = $face->kerning( $glyph->index, $gprev->index );
        }
        $width += $k   if $k;
        $width += $adv;
        $gprev = $glyph;
    }
    return $width;
}

# Internal: render each glyph of a string, optionally hatch-filling each one.
sub _doglyphs ($self, $face, $s, $fill) {
    my @chars = split //, $s;
    my $len   = scalar @chars;
    my $k     = 0;
    my $hk    = $face->has_kerning();
    my ( $glyph, $gprev, $adv, $d );
    $gprev = undef;
    foreach my $i ( 0 .. $len - 1 ) {
        $glyph = $face->glyph_from_char_code( ord $chars[$i] );
        if ( !defined $glyph ) {
            $self->_croak( 'char not found in font: ' . $chars[$i] );
        }
        $d = $glyph->svg_path();
        if ( $d eq $EMPTY_STR ) {
            $d = $SPACE;    # space character has no outline
        }
        else {
            # Work around a Font::FreeType bug: remove successive duplicate
            # path entries (equivalent to the Unix 'uniq' command).
            my @dtmp = split $EOL, $d;
            my $dlen = scalar @dtmp;
            if ( $dlen > 1 ) {
                while ( $dlen > 0 ) {
                    if ( $dtmp[ $dlen - 1 ] eq $dtmp[ $dlen - 2 ] ) {
                        splice @dtmp, $dlen - 1, 1;
                        $dlen--;
                        $d = join $EOL, @dtmp;
                    }
                    $dlen--;
                }
            }
        }
        $adv = $glyph->horizontal_advance();
        if ( $gprev && $hk ) {
            $k = $face->kerning( $glyph->index, $gprev->index );
        }
        if ($k) { $self->translate( $k, 0 ) }
        if ( $d ne $SPACE ) {
            $self->_dopath($d);
        }
        if ($fill) { $self->_dohatching() }
        $self->_flushPsegments();
        $self->newpath();
        $self->translate( $adv, 0 );
        $gprev = $glyph;
    }
    return 1;
}


1;

__END__

=head1 NAME

Graphics::Penplotter::GcodeXY::Font - TrueType font rendering for GcodeXY

=head1 DESCRIPTION

A L<Role::Tiny> role that adds TrueType font rendering and hatch fill to
L<Graphics::Penplotter::GcodeXY>.

Font outlines are obtained via L<Font::FreeType>, converted to SVG path
data, and rendered through the standard C<_dopath> machinery.  Kerning is
applied when the font supports it.

Hatch fill works by scanning the current path with a series of horizontal
lines at C<hatchsep> spacing, computing intersections with the path
segments using the Liang-Barsky algorithm (provided by the host class as
C<_getsegintersect>), and emitting the interior segments as gcode moves.

=head1 METHODS

=over 4

=item $face = setfont($filename, $size)

Locate, open and size a TrueType font.  C<$filename> may be a bare name
(searched in the font path), a relative path, or an absolute path.
C<$size> is in points.  Returns a L<Font::FreeType::Face> object, or
C<undef> on failure.

=item setfontsize($size)

Set the current font size in points without opening a face.

=item $path = findfont($name)

Search the font path list for C<$name>.  Returns the full path, or an
empty string if not found.

=item addfontpath(@dirs)

Prepend one or more directories to the font search path.  Tilde expansion
is applied.

=item stroketext($face, $string)

Render C<$string> using C<$face> without fill.  The current path is
flushed before rendering, and again after each glyph.  The drawing
position advances by the glyph advance width (with kerning).

=item stroketextfill($face, $string)

As C<stroketext>, but each glyph is hatch-filled before the path is
flushed.

=item $width = textwidth($face, $string)

Return the total advance width of C<$string> in the coordinate units of
C<$face>, accounting for kerning.

=item sethatchsep($sep)

Set the spacing between hatch lines, in the current drawing units.
Default is 0.012 inches (C<hatchsep> attribute on the object).

=item strokefill()

Hatch-fill the current path, then stroke and clear it.

=back

=head1 REQUIRED METHODS

This role requires the consuming class to provide:
C<_croak>, C<_flushPsegments>, C<newpath>, C<stroke>,
C<gsave>, C<grestore>, C<translate>, C<_getsegintersect>, C<_addtopage>.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com)

=head1 LICENSE

Same terms as Perl itself.

=cut

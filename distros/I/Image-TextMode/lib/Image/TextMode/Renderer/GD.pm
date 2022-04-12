package Image::TextMode::Renderer::GD;

use Moo;
use Module::Runtime ();
use GD;
use Image::TextMode::Palette::ANSI;
use Carp 'croak';
use File::ShareDir;

=head1 NAME

Image::TextMode::Renderer::GD - A GD-based renderer for text mode images

=head1 SYNOPSIS

    use Image::TextMode::Format::ANSI;
    use Image::TextMode::Renderer::GD;
    
    my $ansi = Image::TextMode::Format::ANSI->new;
    $ansi->read( $file );
    
    my $renderer = Image::TextMode::Renderer::GD->new;
    
    # render fullscale version
    print $renderer->fullscale( $ansi );
    
    # render thumnail version
    print $renderer->thumbnail( $ansi );

=head1 DESCRIPTION

This module allows you to render your text mode image though the GD
graphics library.

=head1 METHODS

=head2 new( %args )

Creates a new instance.

=head2 thumbnail( $source, \%options )

Renders a thumbnail-sized version of the image. This is mostly a pass-through to
C<fullscale()> with the resulting image being scaled down to 1 pixel width per
1 character column. Options specific to this method are:

=over 4

=item * zoom - a zoom factor for the thumbnail (default: n/a)

=back

See C<fullscale> for all of the other available options.

=cut

sub thumbnail {
    my ( $self, $source, $options ) = @_;

    $options = { %{ $source->render_options }, $options ? %$options : () };

    if ( $source->can( 'frames' ) ) {
        return $self->_render_animated_thumbnail( $source, $options );
    }

    my $image_l = do {
        local $options->{ format } = 'object';    ## no critic (Variables::ProhibitLocalVar)
        $self->fullscale( $source, $options );
    };

    my ( $width, $height ) = _thumbnail_size( $source, $image_l, $options );

    my $image = GD::Image->new( $width, $height, 1 );
    $image->copyResampled( $image_l, 0, 0, 0, 0, $width, $height,
        $image_l->getBounds );

    my $output = $options->{ format } || 'png';

    return $image if $output eq 'object';
    return $image->$output;
}

sub _render_animated_thumbnail {
    my ( $self, $source, $options ) = @_;
    my @frames = @{ $source->frames };
    $options->{ format } = 'object';
    $self->_prepare_options( $source, $options );
    my $frame = $self->_render_frame( $frames[ 0 ], $options );
    my ( $width, $height ) = _thumbnail_size( $source, $frame, $options );
    my $master = GD::Image->new( $width, $height, 1 );

    $master->copyResampled( $frame, 0, 0, 0, 0, $width, $height,
        $frame->getBounds );
    my $output = $master->gifanimbegin( 0 );
    $output .= $master->gifanimadd( 1, 0, 0, 15, 1 );

    shift @frames;
    for my $canvas ( @frames ) {
        $frame = $self->_render_frame( $canvas, $options );
        $master->copyResampled( $frame, 0, 0, 0, 0, $width, $height,
            $frame->getBounds );
        $output .= $master->gifanimadd( 1, 0, 0, 15, 1 );
    }

    $output .= $master->gifanimend;

    return $output;
}

sub _thumbnail_size {
    my ( $source, $image, $options ) = @_;

    my ( $width, $height ) = $source->dimensions;
    $height = $image->height / int( $image->width / $width + 0.5 );

    if ( my $zoom = $options->{ zoom } ) {
        $width  *= $zoom;
        $height *= $zoom;
    }

    return ( $width, $height );
}

=head2 fullscale( $source, \%options )

Renders a pixel-by-pixel representation of the text mode image. You may use the
following options to change the output:

=over 4

=item * crop - limit the display to this many rows (default: no limit)

=item * blink_mode - when false, use the 8th bit of an attribute byte as part of the background color (aka iCEColor) (default: differs by format)

=item * truecolor - set this to true to enable true color image output (default: false)

=item * 9th_bit - compatibility option to enable a ninth column in the font (default: false)

=item * dos_aspect - emulate the aspect ratio from DOS (default: false)

=item * ced - CED mode (black text on gray background) (default: false)

=item * font - override the image font; either a font object, or the last part of the clas name (e.g. 8x8)

=item * palette - override the image palette; either a palette object, or the last part of the class name (e.g. VGA)

=item * format - the output format (default: png)

=back

=cut

sub fullscale {
    my ( $self, $source, $options ) = @_;

    $options = { %{ $source->render_options }, $options ? %$options : () };

    $self->_prepare_options( $source, $options );

    if ( $source->can( 'frames' ) ) {
        $options->{ format } = 'object';
        my $master = GD::Image->new( @{ $options->{ full_dimensions } } );
        my $output = $master->gifanimbegin( 0 );
        for my $canvas ( @{ $source->frames } ) {
            my $obj = $self->_render_frame( $canvas, $options );

            $output .= $obj->gifanimadd( 1, 0, 0, 15, 1 );
        }
        $output .= $master->gifanimend;
        return $output;
    }

    return $self->_render_frame( $source, $options );
}

sub _prepare_options {
    my ( $self, $source, $options ) = @_;

    $options->{ font }    ||= $source->font;
    $options->{ palette } ||= $source->palette;
    $options->{ palette } = Image::TextMode::Palette::ANSI->new
        if $options->{ ced };

    for ( qw( font palette ) ) {
        next if ref $options->{ $_ };

        my $class
            = 'Image::TextMode::' . ucfirst( $_ ) . q(::) . $options->{ $_ };

        if ( !eval { Module::Runtime::require_module( $class ) } ) {
            croak sprintf( "Unable to load ${_} '%s'", $options->{ $_ } );
        }

        $options->{ $_ } = $class->new;

    }

    # Special case for XBin 512 char fonts, which maps to 2 x 256 char fonts
    if( $source->isa( 'Image::TextMode::Format::XBin' ) && $source->header->{ flags } & 16 ) {
      my $low_font = Image::TextMode::Font->new( {
        width => $options->{ font }->width,
        height => $options->{ font }->height,
        chars => [ @{ $options->{ font }->chars }[ 0..255 ] ],
      } );
      my $high_font = Image::TextMode::Font->new( {
        width => $options->{ font }->width,
        height => $options->{ font }->height,
        chars => [ @{ $options->{ font }->chars }[ 256..511 ] ],
      } );

      $options->{ font } = _font_to_gd( $low_font,
          { '9th_bit' => $options->{ '9th_bit' } } );
      $options->{ font_512 } = _font_to_gd( $high_font,
          { '9th_bit' => $options->{ '9th_bit' } } );
    }
    else {
      $options->{ font } = _font_to_gd( $options->{ font },
          { '9th_bit' => $options->{ '9th_bit' } } );
    }

    $options->{ truecolor } ||= 0;
    $options->{ format }    ||= 'png';

    my ( $width, $height ) = $source->dimensions;
    $height = $options->{ crop } if $options->{ crop };
    $options->{ full_dimensions } = [
        $width * $options->{ font }->width,
        $height * $options->{ font }->height
    ];

    if ( $options->{ dos_aspect } ) {
        my $ratio = $options->{ '9th_bit' } ? 1.35 : 1.2;
        $options->{ full_dimensions }->[ 1 ]
            = int( $options->{ full_dimensions }->[ 1 ] * $ratio + 0.5 );
    }
}

sub _render_frame {
    my ( $self, $canvas, $options ) = @_;

    my ( $width, $height ) = $canvas->dimensions;
    $height = $options->{ crop } if $options->{ crop };

    my $font     = $options->{ font };
    my $ftwidth  = $font->width;
    my $ftheight = $font->height;
    my $ced      = $options->{ ced };

    my $image = GD::Image->new( @{ $options->{ full_dimensions } },
        $options->{ truecolor } );

    my $colors = _fill_gd_palette( $options->{ palette }, $image );

    $image->fill( 0, 0, 7 ) if $ced;

    for my $y ( 0 .. $height - 1 ) {
        for my $x ( 0 .. $width - 1 ) {
            my $pixel = $canvas->getpixel_obj( $x, $y, $options );

            next unless $pixel;

            if ( defined $pixel->bg ) {
                $image->filledRectangle(
                    $x * $ftwidth,
                    $y * $ftheight,
                    ( $x + 1 ) * $ftwidth - 1,
                    ( $y + 1 ) * $ftheight - 1,
                    $colors->[ $ced ? 7 : $pixel->bg ]
                );
            }

            my $raw_pixel = $canvas->getpixel( $x, $y );
            my $gd_font = $font;
            if ( $options->{ 'font_512' } && ( $raw_pixel->{ attr } & 8 ) ) {
              $gd_font = $options->{ 'font_512' };
            }
            $image->string(
                $gd_font,
                $x * $ftwidth,
                $y * $ftheight,
                $pixel->char, $colors->[ $ced ? 0 : $pixel->fg ]
            );
        }
    }

    if ( $options->{ dos_aspect } ) {
        my $resized = GD::Image->new( $image->getBounds, 1 );
        $resized->copyResampled( $image, 0, 0, 0, 0,
            @{ $options->{ full_dimensions } },
            $image->width, $height * $ftheight );
        $image = $resized;
    }

    my $output = $options->{ format };

    return $image if $output eq 'object';
    return $image->$output;
}

sub _font_to_gd {
    my ( $font, $options ) = @_;
    my $ninth = $options->{ '9th_bit' };
    my $name = lc( ( split( /\::/s, ref $font ) )[ -1 ] );

    if (my $fn = eval {
            File::ShareDir::dist_file( 'Image-TextMode',
                $name . ( $ninth ? '_9b' : '' ) . '.fnt' );
        }
        )
    {
        return GD::Font->load( $fn );
    }

    require File::Temp;
    my $temp = File::Temp->new;
    _save_gd_font( $font, $options, $temp );
    close $temp or croak "Unable to close temp file: $!";

    return GD::Font->load( $temp->filename );
}

sub _save_gd_font {
    my ( $font, $options, $fh ) = @_;

    binmode( $fh );

    my $ninth     = $options->{ '9th_bit' };
    my $chars     = $font->chars;
    my $font_size = @$chars;

    print $fh pack( 'VVVV',
        $font_size, 0, $font->width + ( $ninth ? 1 : 0 ),
        $font->height );

    for my $charval ( 0 .. $font_size ) {
        my $char = $chars->[ $charval ];
        for ( @$char ) {
            my @binary = split( //s, sprintf( '%08b', $_ ) );

            if ( $ninth ) {
                push @binary,
                    (       $charval >= 0xc0
                        and $charval <= 0xdf ? $binary[ -1 ] : 0 );
            }

            print $fh pack( 'C*', @binary );
        }
    }
}

sub _fill_gd_palette {
    my ( $palette, $image ) = @_;
    my @allocations
        = map { $image->colorAllocate( @$_ ) } @{ $palette->colors };
    return \@allocations;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

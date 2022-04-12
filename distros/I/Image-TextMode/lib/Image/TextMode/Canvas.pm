package Image::TextMode::Canvas;

use Moo;
use Types::Standard qw( Int ArrayRef );
use Image::TextMode::Pixel;

=head1 NAME

Image::TextMode::Canvas - A canvas of text mode pixels

=head1 DESCRIPTION

This module represents the graphical portion of an image, i.e. a grid
of pixels.

=head1 ACCESSORS

=over 4

=item * width - the width of the canvas

=item * height - the height of the canvas

=item * pixeldata - an arrayref of arrayrefs of pixel data

=back

=cut

has 'width' => ( is => 'rw', lazy => 1, isa => Int, default => 0 );

has 'height' => ( is => 'rw', lazy => 1, isa => Int, default => 0 );

has 'pixeldata' => ( is => 'rw', lazy => 1, isa => ArrayRef, default => sub { [] } );

=head1 METHODS

=head2 new( %args )

Creates a new canvas.

=head2 getpixel( $x, $y )

Get raw pixel data at C<$x>, C<$y>.

=cut

sub getpixel {
    my ( $self, $x, $y ) = @_;
    return unless exists $self->pixeldata->[ $y ];    # avoid autovivification
    return $self->pixeldata->[ $y ]->[ $x ];
}

=head2 getpixel_obj( $x, $y, \%options )

Create a pixel object data at C<$x>, C<$y>. Available options include:

=over 4

=item * blink_mode - enabed or disable blink mode for the pixel object

=back

=cut

sub getpixel_obj {
    my ( $self, $x, $y, $options ) = @_;
    my $pixel = $self->getpixel( $x, $y );
    return unless $pixel;
    return Image::TextMode::Pixel->new( %$pixel, $options );
}

=head2 putpixel( \%pixel, $x, $y )

Store pixel data at C<$x>, C<$y>.

=cut

sub putpixel {
    my ( $self, $pixel, $x, $y ) = @_;
    $self->pixeldata->[ $y ]->[ $x ] = $pixel;

    my ( $w, $h ) = ( $x + 1, $y + 1 );
    $self->height( $h ) if $self->height < $h;
    $self->width( $w )  if $self->width < $w;
}

=head2 dimensions( )

returns a list of the width and height of the image.

=cut

sub dimensions {
    my $self = shift;
    return $self->width, $self->height;
}

=head2 clear_screen( )

Clears the canvas pixel data.

=cut

sub clear_screen {
    my $self = shift;
    $self->width( 0 );
    $self->height( 0 );
    $self->pixeldata( [] );
}

=head2 clear_line( $y, [ \@range ] )

Clears the data at line C<$y>. Specify a range to clear only a portion of
line C<$y>.

=cut

sub clear_line {
    my $self  = shift;
    my $y     = shift;
    my $range = shift;

    return unless defined $self->pixeldata->[ $y ];

    if ( !$range ) {
        $self->pixeldata->[ $y ] = [];
    }
    else {
        $range->[ 1 ] = @{ $self->pixeldata->[ $y ] } - 1 if $range->[ 1 ] == -1;
        $self->pixeldata->[ $y ]->[ $_ ] = undef
            for $range->[ 0 ] .. $range->[ 1 ];
    }
}

=head2 delete_line( $y )

Removes the line from the canvas, moving all subsquent lines up.

=cut

sub delete_line {
    my $self  = shift;
    my $y     = shift;

    return unless exists $self->pixeldata->[ $y ];

    delete @{ $self->pixeldata }[ $y ];
    $self->height( $self->height - 1 );
}

=head2 as_ascii( )

Returns only the character data stored in the canvas.

=cut

sub as_ascii {
    my ( $self ) = @_;

    my $output = '';
    for my $row ( @{ $self->pixeldata } ) {
        for my $col ( @$row ) {
            $output .= defined $col
                && defined $col->{ char } ? $col->{ char } : ' ';
        }
        $output .= "\n";
    }

    return $output;
}

=head2 max_x( $line )

Finds the last defined pixel on a given line. Useful for optimizing writes
in formats where width matters. Returns undef for a missing line.

=cut

sub max_x {
    my ( $self, $y ) = @_;
    my $line = $self->pixeldata->[ $y ];

    return unless $line;

    my $x;
    for ( 0 .. @$line - 1 ) {
        $x = $_ if defined $line->[ $_ ];
    }

    return $x;
}

=head2 ansiscale( $factor )

Perform nearest neighbor scaling in text mode. Returns a new textmode
image.

    # scale down to 1/4 the original size
    my $scaled = $image->ansiscale( 0.25 );

=cut

sub ansiscale {
    my ( $self, $factor ) = @_;

    my $new    = ( ref $self )->new;
    my $width  = $self->width * $factor;
    my $height = $self->height * $factor;

    $width  = int( $width + 1 )  if int( $width ) != $width;
    $height = int( $height + 1 ) if int( $height ) != $height;

    my $oldpixels = $self->pixeldata;
    my $newpixels = [];

    my $inv_ratio = ( 1 / $factor );

    for my $y ( 0 .. $height - 1 ) {
        for my $x ( 0 .. $width - 1 ) {
            my $px = int( $x * $inv_ratio );
            my $py = int( $y * $inv_ratio );

            $newpixels->[ $y ]->[ $x ] = $oldpixels->[ $py ]->[ $px ];
        }
    }

    $new->width( $width );
    $new->height( $height );
    $new->pixeldata( $newpixels );
    return $new;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

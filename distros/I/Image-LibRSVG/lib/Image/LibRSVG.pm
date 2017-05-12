package Image::LibRSVG;

# ----------------------------------------------------------------
# Original File Name:  Image/LibRSVG.pm
# Creation Date:       04.02.2004
# Description:         Loadable Perl-Package  
# -----------------------------------------------------------------
#
# -----------------------------------------------------------------
# Copyright (c) 2004 bestsolution.at Systemhaus GmbH
# -----------------------------------------------------------------

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SVGLibRSVG ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Image::LibRSVG', $VERSION);

# Preloaded methods go here.

sub loadImage {
    my $self      = shift;
    my $file_path = shift;
    my $dpi       = shift;
    my $args      = shift;
    
    my $rv;
    
    if( ! defined $args || (scalar keys %{ $args }) == 0 ) {
        $rv = $self->loadFromFile( $file_path );
    } elsif ( $args->{zoom} ) {
        $rv = $self->loadFromFileAtZoom( $file_path, $args->{zoom}->[0], $args->{zoom}->[1], $dpi );
    } elsif( $args->{dimesion} ) {
        if( defined $args->{dimension}->[2] && $args->{dimension}->[2] ) {
            $rv = $self->loadFromFileAtMaxSize( $file_path, $args->{dimension}->[0], $args->{dimension}->[1], $dpi );
        } else {
            $rv = $self->loadFromFileAtSize( $file_path, $args->{dimension}->[0], $args->{dimension}->[1], $dpi );
        }
    } else {
        $rv = $self->loadFromFileAtZoomWithMax( $file_path, $args->{zoom}->[0], $args->{zoom}->[1], $args->{dimension}->[0], $args->{dimension}->[1], $dpi );
    }
    
    return $rv;
}

sub loadImageFromString {
    my $self      = shift;
    my $file_path = shift;
    my $dpi       = shift;
    my $args      = shift;
    
    my $rv;
    
    if( ! defined $args || (scalar keys %{ $args }) == 0 ) {
        $rv = $self->loadFromString( $file_path );
    } elsif ( $args->{zoom} ) {
        $rv = $self->loadFromStringAtZoom( $file_path, $args->{zoom}->[0], $args->{zoom}->[1], $dpi );
    } elsif( $args->{dimesion} ) {
        if( defined $args->{dimension}->[2] && $args->{dimension}->[2] ) {
            $rv = $self->loadFromStringAtMaxSize( $file_path, $args->{dimension}->[0], $args->{dimension}->[1], $dpi );
        } else {
            $rv = $self->loadFromStringAtSize( $file_path, $args->{dimension}->[0], $args->{dimension}->[1], $dpi );
        }
    } else {
        $rv = $self->loadFromStringAtZoomWithMax( $file_path, $args->{zoom}->[0], $args->{zoom}->[1], $args->{dimension}->[0], $args->{dimension}->[1], $dpi );
    }
    
    return $rv;
}


1;
__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Image::LibRSVG - Perl extension for librsvg

=head1 SYNOPSIS

  use Image::LibRSVG;
  
  ## static Methods
  my $known_formats = Image::LibRSVG->getKnownFormats();
  my $formats       = Image::LibRSVG->getSupportedFormats();
  my $isSupported   = Image::LibRSVG->isFormatSupported("tiff");
  
  my $rsvg = new Image::LibRSVG();
  
  $rsvg->convert("my.svg", "my.png" );
  $rsvg->convertAtZoom("my.svg", "my.png", 1.5, 1.5 );
  $rsvg->convertAtMaxSize("my.svg", "my.png", 200, 300 );
  $rsvg->convertAtSize("my.svg", "my.png", 200, 300 );
  $rsvg->convertAtZoomWithMax("my.svg", "my.png", 1.5, 1.5, 200, 300 );
  
  $formats     = $rsvg->getSupportedFormats();
  $isSupported = $rsvg->isFormatSupported("tiff");
  
  $rsvg->loadImage( "my.svg" );
  
  open( SVGFILE, "< my.svg" );
  local( $/ ) ;
  $rsvg->loadImageFromString( <SVGFILE> );
  close SVGFILE;
  
  $rsvg->saveAs( "my.png" );
  $rsvg->saveAs( "my.jpg", "jpeg" );
  
  $rsvg->loadImage( "my.svg", 0, { zoom => [ 1.5, 1.5 ] } );
  $rsvg->saveAs( "zoomed.png" );
  
  my $bitmap = $rsvg->getImageBitmap();
  
=head1 ABSTRACT

  This module provides an Perl-Interface towards the gnome-lib
  librsvg-2.

=head1 DESCRIPTION

This module provides an Perl-Interface towards the gnome-lib
librsvg-2 which is able to convert SVG(Scaleable Vector Graphics)
into bitmapformats like (PNG,JPG,...). To which formats you can convert
the svg-files depends on your gdk-pixbuf configuration. Still at least
PNG and JPG should be available.

=head2 EXPORT

None by default.

=head2 Methods

=head3 Constructor

=over

=item * new()

=back

=head3 static methods

=over

=item * B<ArrayRef> getKnownFormats()

returns all formats known to gdk-pixbuf

=item * B<ArrayRef> getSupportedFormats()

returns all formats you can store your svg image into

=item * B<bool> isFormatSupported( String format )

returns true if you can store your image in this format else false

=back

=head3 member methods

=over

=item * B<bool> loadImage( B<String> svgfile[, B<int> dpi=0, B<HashRef> args] )

This is function provides a common call mechanism to for all 
functions below, the args-variable can hold the following values:

=over

=item Case 1( = loadFromFile ):

    undef
    
=item Case 2( = loadFromFile ):

    empty hashref

=item Case 3( = loadFromFileAtZoom )
    
    zoom->[0] ... x_zoom
    zoom->[1] ... y_zoom

=item Case 4( = loadFromFileAtMaxSize ):
    
    dimension->[0] ... x-size
    dimension->[1] ... y-size
    
=item Case 5( = loadFromFileAtSize ):

    dimension->[0] ... x-size
    dimension->[1] ... y-size
    dimension->[2] ... max-size-flag

=item Case 6( = loadFromFileAtZoomWithMax ):
    
    zoom->[0] ........ x_zoom
    zoom->[1] ........ y_zoom
    dimension->[0] ... x-size
    dimension->[1] ... y-size

=back

=item * B<bool> loadImageFromString( B<String> svgfile[, B<int> dpi=0, B<HashRef> args] )

Loads the image from an String containing a plain SVG. For information about args see loadImage.

=item * B<bool> loadFromFile(B<String> svgfile,[B<int> dpi=0])

=item * B<bool> loadFromFileAtZoom( B<String> svgfile, B<double> x_zoom, B<double> y_zoom[, B<int> dpi=0] )

=item * B<bool> loadFromFileAtMaxSize( B<String> svgfile, B<int> width, B<int height>[, B<int> dpi=0] )

=item * B<bool> loadFromFileAtSize( B<String> svgfile, B<int> width, B<int> height[, B<int> dpi=0] )

=item * B<bool> loadFromFileAtZoomWithMax( B<String> svgfile, B<double> x_zoom, B<double> y_zoom, B<int> width, B<int> height[, B<int> dpi=0] )

=item * B<bool> loadFromString(B<String> svgfile,[B<int> dpi=0])

=item * B<bool> loadFromStringAtZoom( B<String> svgfile, B<double> x_zoom, B<double> y_zoom[, B<int> dpi=0] )

=item * B<bool> loadFromStringAtMaxSize( B<String> svgfile, B<int> width, B<int height>[, B<int> dpi=0] )

=item * B<bool> loadFromStringAtSize( B<String> svgfile, B<int> width, B<int> height[, B<int> dpi=0] )

=item * B<bool> loadFromStringAtZoomWithMax( B<String> svgfile, B<double> x_zoom, B<double> y_zoom, B<int> width, B<int> height[, B<int> dpi=0] )

=item * B<bool> convert( B<String> svgfile, B<String> bitmapfile[, B<int> dpi=0, B<String> format="png", B<int> quality=100] )

=item * B<bool> convertAtZoom( B<String> svgfile, B<String> bitmapfile, B<double> x_zoom, B<double> y_zoom[, B<int> dpi=0, B<String> format="png", B<int> quality=100] )

=item * B<bool> convertAtMaxSize( B<String> svgfile, B<String> bitmapfile, B<int> width, B<int> height[, B<int> dpi=0, B<String> format="png", B<int> quality=100] )

=item * B<bool> convertAtSize( B<String> svgfile, B<String> bitmapfile, B<int> width, B<int>  height[, B<int> dpi=0, B<String> format="png", B<int> quality=100] )

=item * B<bool> convertAtZoomWithMax( B<String> svgfile, B<String> bitmapfile, B<double> x_zoom, B<double> y_zoom, B<int> width, B<int> height[, B<int> dpi=0, B<String> format="png", B<int> quality=100] )

=item * B<bool> saveAs( B<String> filename, [ B<String> type, B<String> quality ] )

Saves the image to a file

=item * B<SV> getBitmap( [ B<String> type, B<String> quality ] )

Saves the image to a scalar which can be passed on to other applications. This only return a useful
value if you have compiled it with a gdk-pixbuf greater than or equal to 2.4
    
=back

=head1 SEE ALSO

http://librsvg.sf.net

=head1 AUTHOR

Tom Schindl, E<lt>tom.schindl@bestsolution.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Tom Schindl and bestsolution Systemhaus GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

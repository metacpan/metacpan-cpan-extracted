package Image::Magick::Thumbnail::Fixed;

use 5.6.1;
use strict;
use warnings;
use Carp;

require Image::Magick;

our $VERSION = '0.04';

sub new {
  my $class = shift;  
  my $self = bless {}, $class;
}

sub debug {
  my $self = shift;
  $self->{debug} = shift;
}
 
sub thumbnail {
  my ($self, %args) = @_;
  
  my $im = new Image::Magick;
  
  # Required Parameters
  my $input   = $args{input};
  my $output  = $args{output};
  my $width   = $args{width};
  my $height  = $args{height};

  if( !$input ){
    carp "No input path specified";
    return undef;
  }
  
  if( !$output ){
    carp "No output path specified";
    return undef;
  }
  
  if( !$width ){
    carp "No width specified";
    return undef;
  }
  elsif( $width <= 0 ){
    carp "Invalid width";
    return undef;
  }
  
  if( !$height ){
    carp "No height specified";
    return undef;
  }elsif( $height <= 0 ){
    carp "Invalid height";
    return undef;
  }
  
  # Optional Parameters (passed to ImageMagick -- no local error checking)
  my $density = $args{density} || $width . "x" . $height;
  my $quality = $args{quality} || '70';
  my $bgcolor = $args{bgcolor} || 'white';
  my $format  = $args{format}  || 'jpg';
  my $compose = $args{compose} || 'over';
  my $gravity = $args{gravity} || 'center';
  

  if( $self->{debug} ){
    warn "Input   : $input\n";
    warn "Output  : $output\n";
    warn "ThumbWH : $width x $height\n";
    warn "Density : $density\n";
    warn "Quality : $quality\n";
    warn "BgColor : $bgcolor\n";
    warn "Format  : $format\n";
  }
  
  eval {

  	open(IMAGE,"<$input") or carp "Could not open $input: $!" and return undef;
  	my $err = $im->Read(file=>\*IMAGE);
  	die $err if $err;
	  close(IMAGE);

    # source image dimensions  
    my ($o_width, $o_height) = $im->Get('width','height');
  
  	warn "Source  : $o_width x $o_height\n" if $self->{debug};
   
    warn "Source image height <= 0 ($o_height)." and return undef if $o_height <= 0;
    warn "Source image width <= 0 ($o_width)." and return undef if $o_width  <= 0;
    
    # calculate image dimensions required to fit onto thumbnail
    my ($t_width, $t_height, $ratio);
    # wider than tall (seems to work...) needs testing
    if( $o_width > $o_height ){
      $ratio = $o_width / $o_height;
      $t_width = $width;    
      $t_height = $width / $ratio;
  
      # still won't fit, find the smallest size.
      while($t_height > $height){
        $t_height -= $ratio;
        $t_width -= 1;
      }
    }
    # taller than wide
    elsif( $o_height > $o_width ){
      $ratio = $o_height / $o_width;  
      $t_height = $height;
      $t_width = $height / $ratio;
  
      # still won't fit, find the smallest size.
      while($t_width > $width){
        $t_width -= $ratio;
        $t_height -= 1;
      }
    }
    # square (fixed suggested by Philip Munt phil@savvyshopper.net.au)
    elsif( $o_width == $o_height){
      $ratio = 1;
      $t_height = $width;
      $t_width  = $width;
       while (($t_width > $width) or ($t_height > $height)){
         $t_width -= 1;
         $t_height -= 1;
       }
    }

    warn "Ratio   : $ratio\n" if $self->{debug};
    warn "ThumbWH : $t_width x $t_height\n" if $self->{debug};      
  
    # Create thumbnail
    if( defined $im ){
      $im->Resize( width => $t_width, height => $t_height );
      $im->Set( quality => $quality );
      $im->Set( density => $density );
      
      my $thumb = new Image::Magick;
    
      $thumb->Set( size => $width . "x" . $height );
      $thumb->Set( quality => $quality );
      $thumb->Set( density => $density ); 
    
      $thumb->Read("gradient:$bgcolor-$bgcolor");
      
      $thumb->Composite( image   => $im, 
                         compose => $compose,
                         gravity => $gravity );
           
      $thumb->Write("$format:$output");
      
    }
  };
  if( $@ ){
    warn $@ and return undef;
  }
  return 1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!
 
=head1 NAME

Image::Magick::Thumbnail::Fixed - Perl extension for creating fixed sized thumbnails without distortion.

=head1 SYNOPSIS

  use Image::Magick::Thumbnail::Fixed;
  my $t = new Image::Magick::Thumbnail::Fixed;
  
  # Required parameters
  $t->thumbnail( input   => 'input.jpg',
                 output  => 'output.jpg',
                 width   => 96,
                 height  => 72 );
   
  # Required and optional parameters
  $t->thumbnail( input   => 'input.jpg',
                 output  => 'output.jpg',
                 width   => 96,
                 height  => 72,
                 density => '96x72',
                 gravity => 'center',
                 compose => 'over',
                 quality => '90',
                 bgcolor => 'white',
                 format  => 'jpg' );

=head1 DESCRIPTION

Create fixed sized thumbnails without distorting or stretching the source image. 

Example: The source image is 349 x 324 (1.077 ratio). The thumbnail image is to be 96x72 (1.333 ratio).
Resizing the source image to 96 x 72 will cause distortion. This module will first resize the source in memory
(to 66 x 71) and then compose it ontop of the thumbnail canvas.

=head1 PREREQUISITES

C<Image::Magick>

=cut


=head2 REQUIRED PARAMETERS

=over 4

=item input

The input path of the source image.

=item output

The output path of the thumbnail image.

=item width

The width of the thumbnail image.

=item height

The height of the thumbnail image.

=back

=head2 OPTIONAL PARAMETERS

See http://imagemagick.org/www/perl.html for information regarding optional parameters (density, gravity, compose, color, quality, format).

=over 4

=item density

Vertical and horizontal resolution in pixels of the image. Takes 
an ImageMagick 'geometry' string (ie: '96x72'). Default: width x height of the thumbnail.

=item gravity

Type of image gravity. Options: {Forget, NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast}
Default: center

=item compose

Composite operator. Options: {Over, In, Out, Atop, Xor, Plus, Minus, Add, Subtract, Difference, Bumpmap, Copy, Mask, Dissolve, Clear, Displace}
Default: over

=item bgcolor

Background color of the thumbnail canvas (will only show if the ratio of the source does not match the ratio of the thumbnail).
Options: http://imagemagick.org/www/color.html Default: white

=item quality

JPEG/MIFF/PNG compression level (range 0-100). 
Default: 70

=item format

Image format. 
Default: jpg


=head2 EXPORT

None by default.

=head1 VERSION HISTORY

Version 0.01 (18 August 2004): Initial Revision

Version 0.02 (31 August 2004): Perl 5.6.1 support, fixed height/width calculations that were broken in certain situations.

Version 0.03 (25 September 2004): made debug mode more verbose. Caught additional errors.

Version 0.04 (26 April 2005): Fixed debugging conditional that was too loud - pd <paul@dowling.id.au>, fixed bug with square images - Phillip Munt <phil@savvyshopper.net.au>.
 
=head1 SEE ALSO

L<Image::Magick>,
L<Image::Magick::Thumbnail>,
L<Image::Thumbnail>

=head1 AUTHOR

Adam Roth, E<lt>aroth@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Adam Roth, all rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

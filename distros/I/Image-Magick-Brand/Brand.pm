package Image::Magick::Brand;

use strict;
use warnings;
use Carp;

require Image::Magick;

our $VERSION = '0.01';

sub new {
  my $class = shift;  
  my $self = bless {}, $class;
}

sub debug {
  my $self = shift;
  $self->{debug} = shift;
}

sub brand {
  my ($self, %args) = @_;
    
  # Required Parameters
  my $source = $args{source};
  my $target = $args{target};
  my $output = $args{output};
  
  # Optional Parameters 
  my $gravity   = $args{gravity}   || 'SouthWest';
  my $composite = $args{composite} || 'over';
  my $format    = $args{format}    || 'jpg';
  my $quality   = $args{quality}   || 100;

  # Error Checking  
  if( !$source ){
    carp "No source image specified";
    return undef;
  }
  
  if( !$target ){
    carp "No target image specified.";
    return undef;
  }

  if( !$output ){
    carp "No output image specified.";
    return undef;
  }

  # Debug Output
  if( $self->{debug} ){
    warn "Source    : $source\n";
    warn "Target    : $target\n";
    warn "Output    : $output\n";
    warn "Gravity   : $gravity\n";
    warn "Composite : $composite\n";
    warn "Quality   : $quality\n";
    warn "Format    : $format\n";
  }  
  
  eval {

    my $im_s = new Image::Magick;
    my $im_t = new Image::Magick;

    my $err;
    
    open(IMAGE,"<$source") or carp "Could not open source image: $source ($!)" and return undef;
    $err = $im_s->Read(file=>\*IMAGE);
    die $err if $err;
    close(IMAGE);

    open(IMAGE,"<$target") or carp "Could not open target image: $target ($!)" and return undef;
    $err = $im_t->Read(file=>\*IMAGE);
    die $err if $err;
    close(IMAGE);

    $im_s->Set( quality => $quality );
    $im_t->Set( quality => $quality );

    $im_t->Composite( image     => $im_s, 
                      composite => 'over',
                      gravity   => $gravity );
                      
    $im_t->Write("$format:$output");                      
  };

  if( $@ ){
    warn $@ and return undef;
  }
  
  return 1;
}

1;
__END__

=head1 NAME

Image::Magick::Brand - Perl extension for creating branded images with ImageMagick.

=head1 SYNOPSIS

  use Image::Magick::Brand;
  my $b = new Image::Magick::Brand;
  
  $b->debug(1); # debugging statements on
  
  # Required parameters
  $b->brand( source => 'brand.png',
             target => 'photo.jpg',
             output => 'branded.jpg' );
   
  # Required and optional parameters
  $b->brand( source    => 'brand.png',
             target    => 'photo.jpg',
             output    => 'branded.jpg',
             gravity   => 'SouthWest',
             format    => 'jpg',
             composite => 'over',
             quality   => 75 );

=head1 DESCRIPTION

Create branded images by composing one image on top of another. For optimal results, use a transparent png (or gif...if you must)
as the source image. Note: You must have the appropriate system libraries installed to use certain image formats (ie: lipjpeg, libpng).
ImageMagick will complain if you don't.

Source + Target = Branded Image

       +---------+   +---------+
       |         |   |         |
       |         |   |         |
       |         |   | +--+    |
+--+   |         |   | |  |    |
|  | + |         | = | +--+    |
+--+   +---------+   +---------+

=head1 PREREQUISITES

C<Image::Magick>

=cut

=head1 PARAMETERS

=head2 REQUIRED PARAMETERS

=over 4

=item source

The input path of the source image ('brand image').

=over 4

=item target

The input path of the target image.

=over 4

=item output

The output path of the branded image.

=head2 OPTIONAL PARAMETERS

=item gravity

The gravity (location) of the source image on top of the target image.

 +---------+
 | 1  2  3 |
 |    4    |
 | 5  6  7 |
 +----------
 
 1 = NorthWest
 2 = North
 3 = NorthEast
 4 = Center
 5 = SouthWest (default)
 6 = South
 7 = SouthEast

=item quality

Quality for JPG/MIFF/PNG output (0-100). Default = 100.

=item composite

The 'composite' value as passed to ImageMagick's composite function. Default = 'over'. Read the docs for the other possible values.

=item format

The output format. Default = jpg. 

=cut

=head1 EXPORT

None by default.

=head1 VERSION HISTORY

Version 0.01 (03 May 2005): Initial Revision

=head1 SEE ALSO

L<Image::Magick>

L<Image::Magick::Thumbnail::Fixed>

http://imagemagick.org/script/perl-magick.php

=head1 AUTHOR

Adam Roth, E<lt>aroth@cpan.orgE<gt>

Originally developed for http://www.fetishcyclesfanclub.com. Let me know if you find this module useful.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Adam Roth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

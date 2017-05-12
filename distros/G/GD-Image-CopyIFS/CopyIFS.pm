package GD::Image::CopyIFS;

use strict;
use warnings;
use vars qw($VERSION);
require DynaLoader;
use GD;
use Carp;

@GD::Image::CopyIFS::ISA = qw(DynaLoader GD);

$VERSION = '0.25';

__PACKAGE__->bootstrap($VERSION);

sub GD::Image::thumbIFS {
  my ($self, $src_img, %args) = @_;
  croak "Must supply a GD::Image source"
    unless ($src_img and ref($src_img) eq 'GD::Image');
  my ($sx, $sy) = $src_img->getBounds();
  my ($dx, $dy);
  my ($scale, $x, $y, $max) = @args{qw(scale x y max)};
  if ($scale) {
    $dx = int($scale * $sx);
    $dy = int($scale * $sy);
  }
  elsif ($x and $y) {
    $dx = $x;
    $dy = $y;
  }
  elsif ($x) {
    $dx = $x;
    $dy = int($x / $sx * $sy);
  }
  elsif ($y) {
    $dy = $y;
    $dx = int($y / $sy * $sx);
  }
  elsif ($max) {
    if ($sx > $sy) {
      $dx = $max;
      $dy = int($dx / $sx * $sy);
    }
    else {
      $dy = $max;
      $dx = int($dy / $sy * $sx);
    }
  }
  else {
    croak "Please specify thumbnail size";
  }
  my $th = GD::Image->new($dx, $dy, 1);
  $th->copyIFS($src_img,0,0,0,0,$dx,$dy,$sx,$sy);
  return wantarray ? ($th, $dx, $dy) : $th;
}

1;

__END__

=head1 NAME

GD::Image::CopyIFS - fractal-based image copying and resizing

=head1 SYNOPSIS

  # zoom in on an area of an image
  use GD::Image::CopyIFS;
  my $width = 64;
  my $height = 60;
  my $scale = 4;
  my $neww = $scale * $width;
  my $newh = $scale * $height;
  my $src_file = 'src.jpeg';
  my $src_img = GD::Image->newFromJpeg($src_file, 1);
  my $dst_img = GD::Image->new($neww, $newh, 1);
  my @opts = ($src_img, 0, 0, 110, 120,
              $neww, $newh, $width, $height);
  $dst_img->copyIFS(@opts);
  my $dst_file = 'dst.jpeg';
  open(my $fh, '>', $dst_file) or die "Cannot open $dst_file: $!";
  binmode $fh;
  print $fh $im->jpeg;
  close $fh;

  # create a resized image scaled by a factor $scale
  use GD::Image::CopyIFS;
  my $src_file = 'src.jpeg';
  my $src_img = GD::Image->newFromJpeg($src_file, 1);
  my $scale = 2.45;
  my $dst_img = GD::Image->thumbIFS($src_img, scale => $scale);
  my $dst_file = 'dst.jpeg';
  open(my $fh, '>', $dst_file) or die "Cannot open $dst_file: $!";
  binmode $fh;
  print $fh $im->jpeg;
  close $fh;

=head1 DESCRIPTION

This module adds to the C<GD::Image> module of C<GD>
two methods: C<copyIFS>, used to copy and resize an area of
one image onto another image, and C<thumbIFS>, used to
create a rescaled image from an original. The C<copyIFS>
method is used analagously to the C<copyResized> or
C<copyResampled> methods of the C<GD> module.

The algorithm employed uses what is known as a fractal
interpolating function, which uses an Iterated Function
System (IFS) to interpolate functions specified at
discrete points. The basic procedure is to create an
IFS based on the pixel colors of an image, and then
from this construct a new IFS based on the parameters
specified when rescaling an area of the image.
A random iteration algorithm is then used
to construct an image from this new IFS. For details, see
http://ecommons.uwinnipeg.ca/archive/00000026/.

Note that this algorithm may give good results for images
of natural objects, as there is generally a fractal
nature present in most such shapes. It typically
will not give good results for more geometric shapes,
such as lettering.

=head1 FUNCTIONS

=over 4

=item C<$dst_img-E<gt>copyIFS(@opts)>

This method, which is used analagously to the
C<copyResized> and C<copyResampled> methods of the C<GD>
module, copies an area of one image onto another image.
The options are specified as

  $dst_img->copyIFS($srcImg,
                   $dstX, $dstY, $srcX, $srcY,
                   $dstW, $dstH, $srcW, $srcH,
                   $min_factor, $max_factor);

which takes the source of the image contained in the
C<GD::Image> object C<$srcImg> and copies an area starting
at C<($srcX, $srcY)>, of size C<($srcW, $srcH)>,
to the destination C<$dst_img>, starting at C<($dstX, $dstY)>,
of size C<($dstW, $dstH)>. Two optional paramaters,
C<$min_factor> and C<$max_factor>, may also be specified:

=over 4

=item min_factor

This number, between 0 and 1, determines the minimum fraction of 
the destination points to be colored by the IFS algorthm. The 
remainder simply use the nearest available pixel to determine 
the colour. Values very close to 1 will produce better looking 
images, but will take longer. A default of 0.999999 is used
if not specified.

=item max_factor

This number, greater than 1, determines the maximum number
of iterations that the IFS algorithm uses. A value of 1
will have this iteration number equal to the number of
pixels in the destination; increasing this value will
produce better looking images, but at the expense of speed.
Reasonable values are around 5-10. A default of 7 is used
if not specified.

=back

The default values of C<min_factor> and C<max_factor> will
be used if these are not passed to C<copyIFS>, but if you
want to specify them, both must be given.

=item C<$dst_img-E<gt>thumbIFS($src_img, %args)>

This method created a resized image from the source
image specified in the C<GD::Image> object C<$src_img>,
according to the arguments specified. These may be one
of the following:

=over 4

=item C<scale =E<gt> $scale>

This will scale the image by an amount specified by C<$scale>.

=item C<x =E<gt> $x, y =E<gt> $y>

This will create a resized image of size C<($x, $y))>.
If the specifications of either C<$x> or C<$y> are omitted, it
will be calculated from the proportional scaling 
specified by the other coordinate.

=item C<max =E<gt> $max>

This will create an image of maximum size C<$max> pixels.
This will, respectively, be either be the width or the
height of the resized image, depending on if the
original image has a larger width or height.

=back

=back

=head1 SEE ALSO

L<GD>

=head1 AUTHOR

Copyright (c) 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
All rights reserved.  This package is free software;
you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

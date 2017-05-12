package Image::Magick::PixelMosaic;

use strict;
use warnings;

our $VERSION = '0.03';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use Image::Magick;

=head1 NAME

Image::Magick::PixelMosaic - Pixelized mosaic filter for Image::Magick.

=head1 SYNOPSIS

  use Image::Magick;
  use Image::Magick::PixelMosaic;

  my $img = Image::Magick->new;
  $img->Read('hoge.jpg');
  my $pix = Image->Magick::PixelMosaic->new;
  $pix->src($img);

  # generates 4x4 pixelized mosaic on area (100,120)-(180,160)
  $pix->pixelize('80x40+100+120', [4,4]);

    
=head1 DESCRIPTION

This module generates pixelized mosaic on parts of images using L<Image::Magick>.

=head1 METHODS

=over 3

=item new [src => $obj]

Creates an C<Image::Magick::PixelMosaic> object.

Optional C<src> parameter expects C<Image::Magick> object.

  my $pix = Image::Magick::PixelMosaic->new(src => $img);

is equal to

  my $pix = Image::Magick::PixelMosaic->new;
  $pix->src($img);

=item src, src($obj)

Get or set Image::Magick object.

=item pixelize C<geometry> => I<geometry>, C<pixelsize> => I<pixel width&height>

Generates pixelized mosaic on specified geometry.

C<geomerty> must be specified as geometry form I<'WxH+X+Y'>.

C<pixelsize> must be specified as one of 'WxH', [W,H] or W (height==width).

All of W, H, X and Y must be non-negative integer.

If geometry exceeds area of source image, it will be automatically cropped. 

When height/width of image are '20x30' and

  $pix->pixelize('20x20+1+5', [4,6])

is called, efefctive pixelized area will be '16x24+1+5'.

=back

=head1 SEE ALSO

L<Image::Magick>

=head1 TODO

accept width/heigh/x/y options.

more pixel color decision algorithm (currently use average of pixel area)

=head1 AUTHOR

KATOU Akira (turugina) E<lt>turugina@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by KATOU Akira (turugina)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

sub new
{
  my ($cls,%opt_) = @_;

  my $self = bless { }, $cls;
  die $! if !$self;

  $self->src($opt_{src}) if exists $opt_{src};

  return $self;
}

sub src
{
  my ($self, $obj) = @_;

  if ( $obj ) {
    if (!$obj->isa('Image::Magick')) {
      die "specified object is not an Image::Magick";
    }
    $self->{src} = $obj;
  }
  return $self->{src};
}

sub pixelize
{
  my ($self, %opt) = @_;

  if (!$self->{src}) {
    die q/source Image::Magick object must be set before calling pixelize()/;
  }
  my $img = $self->{src};

  my ($geo,$psize) = @opt{qw/geometry pixelsize/};

  if (!$geo) {
    die q/geometry must be specified/;
  }
  if (!$psize) {
    die q/pixel size must be specified/;
  }

  $geo =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/ or die q/geometry must be 'WxH+X+Y'/;
  my ($w,$h,$xorig,$yorig) = ($1,$2,$3,$4);

  my ($pw,$ph) = do {
    if ( $psize =~ /^(\d+)x(\d+)$/ ) {
      ($1,$2);
    }
    elsif ( ref($psize) =~ /^ARRAY/ ) {
      @$psize[0,1];
    }
    elsif ( int $psize == $psize ) {
      ($psize,$psize);
    }
    else {
      die q/pixelsize must be one of 'WxH', [W,H] or W/;
    }
  };

  my $imgw = $img->Get(q/width/);
  my $imgh = $img->Get(q/height/);
  my ($xe,$ye) = ($xorig+$w,$yorig+$h);

  # clip area
  $xorig = _clip($xorig,  0, $imgw);
  $yorig = _clip($yorig,  0, $imgh);
  $xe    = _clip($xe, 0, $imgw);
  $ye    = _clip($ye, 0, $imgh);

  $xe -= $pw;
  $ye -= $ph;

  for ( my $x = $xorig; $x <= $xe; $x += $pw ) {
    for ( my $y = $yorig; $y <= $ye; $y += $ph ) {

      my @px = $img->GetPixels(
        x=>$x, y=>$y, width=>$pw, height=>$ph,
        map=>q/RGB/, normalize=>q/true/ );
      my $n = scalar(@px) / 3;
      for my $i ( 1 .. $n-1 ) {
        $px[0]+=$px[$i*3];
        $px[1]+=$px[$i*3+1];
        $px[2]+=$px[$i*3+2];
      }
      @px = map { int($_ * 255.0 / $n) } @px[0..2];

      my $color = sprintf(q/#%02x%02x%02x/, $px[0], $px[1], $px[2]);
      for my $xx ( $x .. $x+$pw-1 ) {
        for my $yy ( $y .. $y+$ph-1 ) {
          $img->Set("pixel[$xx,$yy]" => $color);
        }
      }
    }
  }
  $self;
}

sub _clip
{
  my ( $v, $min, $max ) = @_;

  return $min if $v < $min;
  return $max if $v > $max;
  return $v;
}

1;


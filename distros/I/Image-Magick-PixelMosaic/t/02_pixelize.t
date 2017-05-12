
use strict;
use warnings;

use Test::More tests => 14;

use Image::Magick;
use Image::Magick::PixelMosaic;

my $pix = Image::Magick::PixelMosaic->new;


my $img = _create_img([4,4],
  [[0xf00000, 0x00f000, 0x0, 0x0],
   [0x0000f0, 0x0,      0x0, 0x0],
   [0x0,      0x0,      0x0, 0x0],
   [0x0,      0x0,      0x0, 0x0]]);

$pix->src($img);

is( ref $pix->pixelize(geometry => '4x4+0+0', pixelsize => 4), ref $pix );

my $pxs = _get_pixels($img);
is( scalar(grep { $_ == 0x0f0f0f } @$pxs), 16);

$img = _create_img([5,5],
  [[0xf00000, 0x00f000, 0x0000f0, 0xf00000, 0x00f000],
   [0x0000f0, 0xf00000, 0x00f000, 0x0000f0, 0xf00000],
   [0x00f000, 0x0000f0, 0xf00000, 0x00f000, 0x0000f0],
   [0xf00000, 0x00f000, 0x0000f0, 0xf00000, 0x00f000],
   [0x0000f0, 0xf00000, 0x00f000, 0x0000f0, 0xf00000]]);

$pix->src($img);


is( ref $pix->pixelize(geometry => '6x6+0+1', pixelsize => '2x2'), ref $pix );

$pxs = _get_pixels($img);
is( scalar(grep { $_ == 0x3c3c78 } @$pxs[5,6,10,11]), 4 );
is( scalar(grep { $_ == 0x3c783c } @$pxs[7,8,12,13]), 4 );
is( scalar(grep { $_ == 0x783c3c } @$pxs[15,16,20,21]), 4 );
is( scalar(grep { $_ == 0x3c3c78 } @$pxs[17,18,22,23]), 4 );
is( scalar(grep { $_ == 0xf00000 } @$pxs[0,3,9,24]), 4 );
is( scalar(grep { $_ == 0x00f000 } @$pxs[1,4,19]), 3 );
is( scalar(grep { $_ == 0x0000f0 } @$pxs[2,14]), 2 );

$img = _create_img([5,5],
  [[0xf00000, 0x00f000, 0x0000f0, 0xf00000, 0x00f000],
   [0x0000f0, 0xf00000, 0x00f000, 0x0000f0, 0xf00000],
   [0x00f000, 0x0000f0, 0xf00000, 0x00f000, 0x0000f0],
   [0xf00000, 0x00f000, 0x0000f0, 0xf00000, 0x00f000],
   [0x0000f0, 0xf00000, 0x00f000, 0x0000f0, 0xf00000]]);

$pix->src($img);

# nothing will be changed
is( ref $pix->pixelize(geometry => '5x5+0+0', pixelsize => [100,6]), ref $pix );

$pxs = _get_pixels($img);
is( scalar(grep { $_ == 0xf00000 } @$pxs[0,3,6,9,12,15,18,21,24]), 9 );
is( scalar(grep { $_ == 0x00f000 } @$pxs[1,4,7,10,13,16,19,22]), 8 );
is( scalar(grep { $_ == 0x0000f0 } @$pxs[2,5,8,11,14,17,20,23]), 8 );

sub _create_img
{
  my ( $size, $pxs ) = @_;

  my $img = Image::Magick->new;
  $img->Read(q/xc:Black/);

  $img->Resize(geometry => join('x',@$size));

  my $y=0;
  for my $col ( @$pxs ) {
    my $x=0;
    for my $px ( @$col ) {
      $img->Set(qq/pixel[$x,$y]/ => sprintf("#%06x", $px));
    }
    continue {
      ++$x;
    }
  }
  continue {
    ++$y;
  }
  $img;
}

sub _get_pixels
{
  my ($img) = @_;

  my $w = $img->Get(q/width/);
  my $h = $img->Get(q/height/);

  my @ret;
  my @pxs = $img->GetPixels(geometry => qq/${w}x${h}+0+0/,
    map => q/RGB/, normalize => 0);
  @pxs = map { $_ >> 8 } @pxs;

  for ( 1 .. $h ) {
    for ( 1 .. $w ) {
      push @ret, (($pxs[0] << 16) | ($pxs[1] << 8) | $pxs[2]);
      shift @pxs;
      shift @pxs;
      shift @pxs;
    }
  }
  \@ret;
}

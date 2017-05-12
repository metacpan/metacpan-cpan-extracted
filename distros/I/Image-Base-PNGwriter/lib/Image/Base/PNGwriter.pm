# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-PNGwriter.
#
# Image-Base-PNGwriter is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-PNGwriter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.


# Crib notes:
#     ->plot() and in turn everything using that clips to the image size
#     automatically

package Image::Base::PNGwriter;
# Image::Base is good for 5.004 or some such far back, though
# Image::PNGwriter 0.01 requires 5.8.5, so that's the actual minimum.  It
# looks like Image::PNGwriter could probably go earlier, unless maybe it
# needs a new enough xsubpp for C++.
use 5.006;
use strict;
use warnings;
use Carp;
use Image::PNGwriter;

our $VERSION = 8;

# version 1.12 for ellipse() $fill
# version 1.16 for diamond()
use Image::Base 1.12;
our @ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Devel::Comments;

# Cribs:
#
# /usr/include/pngwriter.h

use constant _DEFAULT_PALETTE => { 'black' => [ 0,0,0 ],
                                   'white' => [ 1,1,1 ] };

sub new {
  my ($class, %params) = @_;
  ### Image-Base-PNGwriter new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    # needs the pngwriter copy-constructor ...
    die "Image cloning not yet implemented";
    #     my $self = $class;
    #     $class = ref $class;
    #     if (! defined $params{'-pngwriter'}) {
    #       $params{'-pngwriter'} = $self->get('-pngwriter')->clone;
    #     }
    #     # inherit everything else
    #     %params = (%$self, %params);
  }

  # -palette not yet documented, maybe call it -cindex anyway
  # FIXME: make a per-instance anon hash
  my $self = bless { -palette => _DEFAULT_PALETTE,
                     -zlib_compression => -1,
                   }, $class;
  if (! defined $params{'-pngwriter'}) {
    my $width = delete $params{'-width'};
    if (! defined $width) { $width = 1; }
    my $height = delete $params{'-height'};
    if (! defined $height) { $height = 1; }

    # can't pass undef to Image::PNGwriter->new
    my $filename = $params{'-file'};
    if (! defined $filename) { $filename = ''; }

    # the filename to new() supplied is not read, just recorded in the $pw
    my $pw = $self->{'-pngwriter'}
      = Image::PNGwriter->new ($width, $height,
                               0,  # background
                               $filename);
  }
  my $filename = delete $params{'-file'};

  $self->set (%params);

  if (defined $filename) {
    $self->load ($filename);
  }
  ### $self
  return $self;
}

my %attr_to_get_method = (-width     => 'getwidth',
                          -height    => 'getheight',
                          # these not documented yet ...
                          -bitdepth  => 'getbitdepth',
                          -gamma     => 'getgamma',
                          -colortype => 'getcolortype');
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-PNGwriter _get(): $key
  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-pngwriter'}->$method;
  }
  ### field: $self->{$key}
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %params) = @_;

  if (exists $params{'-pngwriter'}) {
    $self->{'-pngwriter'} = delete $params{'-pngwriter'};
    delete $self->{'-file'};
    delete $self->{'-zlib_compression'};
    delete $self->{'-title'};
    delete $self->{'-author'};
    delete $self->{'-description'};
    delete $self->{'-software'};
  }

  if (exists $params{'-width'} || exists $params{'-height'}) {
    my $width = (exists $params{'-width'}
                 ? delete $params{'-width'}
                 : $self->{'-pngwriter'}->getwidth);
    my $height = (exists $params{'-height'}
                  ? delete $params{'-height'}
                  : $self->{'-pngwriter'}->getheight);
    $self->{'-pngwriter'}->resize ($width, $height);
  }

  # not documented, yet ...
  if (exists $params{'-gamma'}) {
    $self->{'-pngwriter'}->setgamma (delete $params{'-gamma'});
  }

  %$self = (%$self, %params);

  if (exists $params{'-file'}) {
    $self->{'-pngwriter'}->pngwriter_rename ($params{'-file'});
  }
  if (exists $params{'-zlib_compression'}) {
    $self->{'-pngwriter'}->setcompressionlevel ($params{'-zlib_compression'});
  }

  # not documented yet ...
  if (exists $params{'-title'} || exists $params{'-author'} || exists $params{'-description'} || exists $params{'-software'}) {
    $self->{'-pngwriter'}->settext
      (map {defined $params{$_} ? $params{$_} : ''} '-title', '-author', '-description', '-software');
  }
}

#-------------------------------------------------------------------------------
# load/save

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  $self->{'-pngwriter'}->readfromfile ($filename);
}
sub save {
  my ($self, $filename) = @_;
  if (@_ == 2) {
    $self->set('-file', $filename);
  }
  $self->{'-pngwriter'}->write_png;
}


#-------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### xy: $x, $y, $colour
  my $pw = $self->{'-pngwriter'};
  $x = int($x);
  $y = int($y);
  $x++;
  $y = $pw->getheight - $y;
  if (@_ == 4) {
    ### plot: $x, $y, $self->colour_to_drgb($colour)
    $pw->plot ($x, $y, $self->colour_to_drgb($colour));
  } else {
    ### dread: $x, $y, $pw->dread($x,$y,1), $pw->dread($x,$y,2), $pw->dread($x,$y,3)
    return sprintf ('#%02X%02X%02X',
                    map {int (255 * $pw->dread($x,$y,$_) + 0.5)} 1,2,3);
  }
}
sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  my $pw = $self->{'-pngwriter'};
  my $height = $pw->getheight;
  $pw->line ($x1+1, $height-$y1,
             $x2+1, $height-$y2,
             $self->colour_to_drgb($colour));
}
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-PNGwriter rectangle(): $x1, $y1, $x2, $y2, $colour, $fill

  my $pw = $self->{'-pngwriter'};
  my $height = $pw->getheight;
  my $method = ($fill ? 'filledsquare' : 'square');
  $pw->$method ($x1+1, $height-$y1,
                $x2+1, $height-$y2,
                $self->colour_to_drgb($colour));
}

# Only $pw->circle available, apparently.  For radius 2 it draws something
# like
#
#       O
#      O O
#     O . O
#      O O
#       O
#
# which is x2==x1+4 and y2==y1+4.  The parameters to circle() are integers,
# so only odd number of pixels across like this can be done ($x2-$x1 an even
# number), others go to Image::Base.
#
sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### ellipse(): $x1, $y1, $x2, $y2, $colour, $fill
  my $xr = $x2 - $x1;
  if (! ($xr & 1) && $xr == ($y2 - $y1)) {
    my $pw = $self->{'-pngwriter'};
    $xr /= 2;
    ### $xr
    ### x centre: $x1+$xr
    ### y centre: $pw->getheight() - ($y1+$xr)
    my $method = ($fill ? 'filledcircle' : 'circle');
    $pw->$method ($x1+$xr+1, $pw->getheight() - ($y1+$xr), $xr,
                  $self->colour_to_drgb($colour));
  } else {
    ### plain Image-Base
    shift->SUPER::ellipse(@_);
  }
}

sub diamond {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### diamond(): "$x1,$y1, $x2,$y2, $colour, fill=".($fill||0)
  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  my $pw = $self->{'-pngwriter'};

  if ($w && $h) {

    ### x centre: $x1+int(($w+1)/2)+1
    ### y centre: $pw->getheight() - ($y1+int($h/2)+1)
    ### $w
    ### $h

    my $method = ($fill ? 'filleddiamond' : 'diamond');
    $pw->$method ($x1+int(($w+1)/2)+1,
                  $pw->getheight() - ($y1+int($h/2)),
                  $w, $h,
                  $self->colour_to_drgb($colour));
  } else {
    # 1xN or Nx1 dubious in PNGwriter 0.5.3, use rectangle instead
    shift->rectangle (@_);
  }
}

#------------------------------------------------------------------------------
# colours

# not documented, yet ...
sub colour_to_drgb {
  my ($self, $colour) = @_;
  if (exists $self->{'-palette'}->{$colour}) {
    $colour = $self->{'-palette'}->{$colour};
  }
  if (ref $colour) {
    return @$colour;
  }

  # 1 to 4 digit hex, equally spaced from 00 -> 0.0 through FF -> 1.0, or
  # FFFF -> 1.0 etc.
  # Crib: [:xdigit:] matches some wide chars, but hex() as of perl 5.12.4
  # doesn't accept them, so only 0-9A-F
  if ($colour =~ /^#(([0-9A-F]{3}){1,4})$/i) {
    my $len = length($1)/3; # of each group, so 1,2,3 or 4
    my $divisor = hex('F' x $len);
    return (map {hex($_)/$divisor}
            substr ($colour, 1, $len),      # full size groups
            substr ($colour, 1+$len, $len),
            substr ($colour, -$len));
  }

  croak "Unknown colour: $colour";
}

1;
__END__

=for stopwords PNG pngwriter filename Ryde Zlib Zlib's Image::Base::PNGwriter Image::PNGwriter Image-Base-PNGwriter

=head1 NAME

Image::Base::PNGwriter -- draw PNG format images

=head1 SYNOPSIS

 use Image::Base::PNGwriter;
 my $image = Image::Base::PNGwriter->new (-width => 100,
                                          -height => 100);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');
 $image->ellipse (30,30, 90,90, '#AAAA3333DDDD');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::PNGwriter> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::PNGwriter

=head1 DESCRIPTION

C<Image::Base::PNGwriter> extends C<Image::Base> to create or update PNG
format image files using the C<Image::PNGwriter> module and PNGwriter
library.

The native PNGwriter has more features, but this module is an easy way to
point C<Image::Base> style code at a PNGwriter to get PNG from some
C<Image::Base> code.

X,Y coordinates are the usual C<Image::Base> style 0,0 at the top-left
corner.  The underlying PNGwriter library is 1,1 at the bottom-left but
C<Image::Base::PNGwriter> converts.

=head2 Colour Names

Colours can be

     "#RGB"           1 to 4 digit hex
     "#RRGGBB"
     "#RRRGGGBBB"
     "#RRRRGGGGBBBB"
     "black"
     "white"

There's no colour name database in PNGwriter and no names here except
"black" and "white".

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for behaviour common to all Image-Base classes.

=over 4

=item C<$image = Image::Base::PNGwriter-E<gt>new (key=E<gt>value,...)>

Create and return an image object.  A new image can be started with
C<-width> and C<-height>,

    $image = Image::Base::PNGwriter->new (-width => 200,
                                          -height => 100);

Or an existing file can be read,

    $image = Image::Base::PNGwriter->new
               (-file => '/some/filename.png');

Or an C<Image::PNGwriter> object can be given,

    my $p = Image::PNGwriter->new(200,100, 0, '/tmp/foo.png');
    $image = Image::Base::PNGwriter->new (-pngwriter => $p);

=item C<$image-E<gt>ellipse ($x1,$y1, $x2,$y2, $colour)>

=item C<$image-E<gt>ellipse ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw an ellipse within the rectangle top-left corner C<$x1>,C<$y1> and
bottom-right C<$x2>,C<$y2>.  Optional C<$fill> true means a filled ellipse.

In the current implementation circles with an odd diameter (meaning
C<$x2-$x1+1> is an odd number and equal to C<$y2-$y1+1>) are drawn with
PNGwriter and the rest go to C<Image::Base>.  This is a bit inconsistent but
uses the features of PNGwriter as far as possible and its drawing should be
faster.

=item C<$image-E<gt>diamond ($x1,$y1, $x2,$y2, $colour)>

=item C<$image-E<gt>diamond ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw a diamond shape within the rectangle top-left C<$x1>,C<$y1> and
bottom-right C<$x2>,C<$y2>.  Optional C<$fill> true means a filled diamond.

In PNGwriter 0.5.3 a filled diamond might miss the top-most pixel for some
sizes.  Currently there's no attempt to do anything about that here.  At
small sizes the shape sometimes isn't very good either.

=back

=head1 ATTRIBUTES

The following attributes can be C<get()> and C<set()>.

=over

=item C<-file> (string filename)

The file to load in a C<new()>, and the default filename for subsequent
C<save()> or C<load()>.

=item C<-width> (integer)

=item C<-height> (integer)

Setting these changes the size of the image, but also clears it to all
black.  The image must be at least 1x1 pixels.

=item C<-zlib_compression> (integer 0-9 or -1)

The amount of data compression to apply when saving.  The value is Zlib
style 0 for no compression up to 9 for maximum.  -1 means Zlib's default
level (which is usually 6).

=item C<-pngwriter> (C<Image::PNGwriter> object)

The underlying C<Image::PNGwriter> object in use.

Filename and compression level can't be read out of a pngwriter object,
which means that if you set C<-pngwriter> then a C<get()> of the C<-file> or
C<-zlib_compression> will return C<undef> and there's no default filename
for C<load()>.  But a C<save()> uses the filename and compression in the
object.  Perhaps this will improve in the future.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::PNGwriter>,
L<Image::Base::GD>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-pngwriter/index.html

=head1 LICENSE

Image-Base-PNGwriter is Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-PNGwriter is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-PNGwriter is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-PNGwriter.  If not, see <http://www.gnu.org/licenses/>.

=cut

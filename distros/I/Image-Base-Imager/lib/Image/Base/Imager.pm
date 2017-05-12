# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Imager.
#
# Image-Base-Imager is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Imager is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imager.  If not, see <http://www.gnu.org/licenses/>.



# cf Imager::Draw -- drawing operations
# Seems to auto-clip to width,height.

package Image::Base::Imager;
use 5.004;
use strict;
use Carp;

# maybe Imager 0.39 of Nov 2001 for oop style tags, or something post 0.20
# for the oopery, but don't think need to force that here (just list in the
# Makefile.PL PREREQ_PM)
use Imager;

use vars '$VERSION', '@ISA';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 11;

# uncomment this to run the ### lines
# use Smart::Comments '###';


# As of Imager 0.79 there's nothing to set the Zlib compression level for a
# -zlib_compression attribute.
#
# An -allow_partial could set allow_partial=> on read().
#

sub new {
  my ($class, %params) = @_;
  ### Image-Base-Imager new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $class;
    if (! defined $params{'-imager'}) {
      $params{'-imager'} = $self->get('-imager')->copy;
    }
    # inherit everything else
    %params = (%$self, %params);
    ### copy params: \%params
  }

  my $want_load = 1;
  if (! defined $params{'-imager'}) {
    my $width  = delete $params{'-width'};
    my $height = delete $params{'-height'};
    my $filename = $params{'-file'};
    if (! defined $filename) {
      # default 1x1 image since xsize=>undef,ysize=>undef is a 0x0
      # nothingness where settag() won't store -file_format
      if (! defined $width) { $width = 1; }
      if (! defined $height) { $height = 1; }
    }
    $params{'-imager'} = Imager->new (xsize => $width,
                                      ysize => $height,
                                      file  => $filename)
      || croak "Cannot create image: ",Imager->errstr;
    # set -file as filename, but have already loaded
    $want_load = 0;
  }
  my $self = bless {}, $class;
  $self->set (%params);

  if ($want_load && defined $params{'-file'}) {
    $self->load;
  }

  ### new made: $self
  return $self;
}


my %attr_to_tag = (-hotx => 'cur_hotspotx', # get and set
                   -hoty => 'cur_hotspoty',
                  );
my %attr_to_get_method = (-width    => 'getwidth',
                          -height   => 'getheight',
                          -ncolours => 'colorcount',
                          -file_format => \&_imager_get_file_format,
                         );
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-Imager _get(): $key

  if (my $tag = $attr_to_tag{$key}) {
    ### $tag
    ### is: [$self->{'-imager'}->tags(name=>$tag)]
    return scalar(($self->{'-imager'}->tags(name=>$tag))[0]);
  }
  if (my $method = $attr_to_get_method{$key}) {
    ### $method
    ### is: $self->{'-imager'}->$method()
    return  $self->{'-imager'}->$method();
  }
  return $self->SUPER::_get ($key);
}
sub _imager_get_file_format {
  my ($i) = @_;
  ### _imager_get_file_format() from tags: [$i->tags]
  # tags() returns a list of the values
  return scalar(($i->tags (name => 'i_format'))[0]);
}

my %attr_to_img_set = (-width  => 'xsize',
                       -height => 'ysize',
                      );
sub set {
  my ($self, %param) = @_;
  ### Image-Base-Imager set(): \%param

  foreach my $key ('-ncolours') {
    if (exists $param{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  # apply this first
  if (my $i = delete $param{'-imager'}) {
    $self->{'-imager'} = $i;
  }

  my $i = $self->{'-imager'};
  if (exists $param{'-file_format'}) {
    my $format = delete $param{'-file_format'};
    if (defined $format) { $format = lc($format); }
    ### apply -file_format with settag() i_format: $format
    $i->settag (name => 'i_format', value => $format);
    ### tags now: [$i->tags]
  }
  foreach my $key (keys %param) {
    if (my $tag = $attr_to_tag{$key}) {
      ### settag: $tag
      $i->settag (name => $tag, value => delete $param{$key});
      ### tags now: [$i->tags]
    }
  }

  my @set;
  foreach my $key (keys %param) {
    if (my $attribute = $attr_to_img_set{$key}) {
      push @set, $attribute, delete $param{$key};
    }
  }
  if (@set) {
    ### @set
    $i->img_set(@set);
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  ### Image-Base-Imager load(): @_
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  my $i = $self->{'-imager'};
  $i->read (file => $filename)
    or croak "Cannot load: ",$i->errstr;
  ### $i
  ### size: $i->getwidth.'x'.$i->getheight
  ### tags: [$i->tags]
}

# not yet documented ...
sub load_fh {
  my ($self, $fh) = @_;
  my $i = $self->{'-imager'};
  $i->read (fh => $fh)
    or croak "Cannot load: ",$i->errstr;
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Imager save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  my $i = $self->{'-imager'};
  my $type = _imager_get_file_format($i);
  my $quality = $self->{'-quality_percent'};
  ### file: $filename
  ### type: $type

  # think it's ok to pass undef as $quality, and that the options can be
  # passed even when not saving to the respective formats
  $i->write (file => $filename,
             type => $type,
             jpegquality      => $quality,
             tiff_jpegquality => $quality)
    or croak "Cannot save: ",$i->errstr;
}

# not yet documented ...
sub save_fh {
  my ($self, $fh) = @_;
  my $i = $self->{'-imager'};
  $i->write (fh => $fh,
             type => _imager_get_file_format($i))
    or croak "Cannot save: ",$i->errstr;
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-Imager xy: $x,$y,$colour
  my $i = $self->{'-imager'};
  if (@_ == 4) {
    $i->setpixel (x => $x, y => $y, color => $colour);

  } else {
    my $cobj = $i->getpixel (x => $x, y => $y);
    if (! defined $cobj) {
      # getpixel() returns undef if x,y outside image size
      return undef;
    }
    my @rgba = $cobj->rgba;
    ### @rgba
    # if ($a == 0) {
    #   return 'None';
    # }
    return sprintf ('#%02X%02X%02X', @rgba[0,1,2]);
  }
}
sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-Imager line: @_
  $self->{'-imager'}->line (x1 => $x1,
                            y1 => $y1,
                            x2 => $x2,
                            y2 => $y2,
                            color => $colour);
}
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Imager rectangle: @_

  $self->{'-imager'}->box (xmin => $x1,
                           ymin => $y1,
                           xmax => $x2,
                           ymax => $y2,
                           color => $colour,
                           filled => $fill);
}

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Imager ellipse: "$x1, $y1, $x2, $y2, $colour"

  my $diam = $x2-$x1;
  if (! ($diam & 1) && $y2-$y1 == $diam) {
    ### use circle
    $self->{'-imager'}->circle (x => ($x2+$x1)/2,
                                y => ($y2+$y1)/2,
                                r => $diam/2,
                                color => $colour,
                                filled => $fill);
  } else {
    ### use superclass ellipse
    shift->SUPER::ellipse (@_);
  }
}

sub diamond {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Imager diamond() ...

  # $imager->polygon() for filled poly is always anti-alias, but don't want
  # that, or not by default, so polyline() for unfilled and Image::Base for
  # filled

  if ($fill) {
    shift->SUPER::diamond(@_);

  } else {
    # 0 1 2 3 4
    # x1=0, x2=4 -> xh=2
    #
    # 0 1 2 3 4 5
    # x1=0, x2=5 -> xh=2
    #
    my $xh = ($x2 - $x1);
    my $yh = ($y2 - $y1);
    my $xeven = ($xh & 1);
    my $yeven = ($yh & 1);
    $xh = int($xh / 2);
    $yh = int($yh / 2);
    ### assert: $x1+$xh == $x2-$xh || $x1+$xh+1 == $x2-$xh
    ### assert: $y1+$yh == $y2-$yh || $y1+$yh+1 == $y2-$yh

    $self->{'-imager'}->polyline (points => [ [$x1+$xh,$y1],  # top centre

                                              # left
                                              [$x1,$y1+$yh],
                                              ($yeven ? [$x1,$y2-$yh] : ()),

                                              # bottom
                                              [$x1+$xh,$y2],
                                              ($xeven ? [$x2-$xh,$y2] : ()),

                                              # right
                                              ($yeven ? [$x2,$y2-$yh] : ()),
                                              [$x2,$y1+$yh],

                                              ($xeven ? [$x2-$xh,$y1] : ()),
                                              ($fill ? () : [$x1+$xh,$y1]),
                                            ],
                                  color => $colour);
  }
}

#------------------------------------------------------------------------------
# colours

sub add_colours {
  my $self = shift;
  ### add_colours: @_
  $self->{'-imager'}->addcolors (colors => \@_);
}


# sub _validate_file_format {
#   my ($format) = @_;
#   if (! defined $format) {
#     return; # undef is ok
#   }
# 
#   # in Imager 0.80 'cur' works but isn't in the types lists
#   my $lform = lc($format);
#   foreach my $f ('cur', Imager->read_types, Imager->write_types) {
#     if ($lform eq $f) {
#       return;
#     }
#   }
# 
#   croak 'Unrecognised -file_format: ',$format;
# }

1;
__END__

=for stopwords PNG Imager filename Ryde Zlib Imager RGB JPEG PNM GIF BMP ICO Paletted paletted pre-load png jpeg imager hotspot Image-Base-Imager paletted non-paletted ie packbits

=head1 NAME

Image::Base::Imager -- draw images using Imager

=head1 SYNOPSIS

 use Image::Base::Imager;
 my $image = Image::Base::Imager->new (-width => 100,
                                       -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::Imager> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Imager

=head1 DESCRIPTION

C<Image::Base::Imager> extends C<Image::Base> to create or
update image files using the C<Imager> module.

As of Imager 0.80 the supported file formats for read and write include PNG,
JPEG, TIFF, PNM, GIF, BMP, and ICO (including CUR).  See L<Imager::Files>
for the full list.

Colour names are anything recognised by C<Imager::Color>.  As of Imager 0.80
this means the GIMP F<Named_Colors> if you have the GIMP installed, the X11
F<rgb.txt>, hex "#RGB", "#RRGGBB", etc.  The system F<rgb.txt> is used if
available, otherwise a copy in C<Imager::Color::Table>.  An C<Imager::Color>
object can also be given.

=head2 Paletted Images

For a paletted image, if Imager is given a colour not already in the palette
then it converts the whole image to RGB.  C<Image::Base::Imager> doesn't try
do anything about that yet.  An C<add_colours> can pre-load the palette.

The C<Image::Base> intention is just to throw colour names at drawing
functions, so perhaps C<Image::Base::Imager> should extend the palette when
necessary, or choose a close colour if full.  But an
C<$imager-E<gt>to_paletted> after all drawing might come out better than
colours as drawing proceeds.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::Imager-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = Image::Base::Imager->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = Image::Base::Imager->new (-file => '/some/filename.png');

Or an C<Imager> object can be given,

    $image = Image::Base::Imager->new (-imager => $iobj);

=item C<$image-E<gt>ellipse ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw an ellipse within the rectangle with top-left corner C<$x1>,C<$y1> and
bottom-right C<$x2>,C<$y2>.  Optional C<$fill> true means a filled ellipse.

In the current implementation circles an odd number of pixels
(ie. width==height and odd) are drawn with Imager and ellipses and even
circles as such go to C<Image::Base>.  This is a bit inconsistent but uses
the features of Imager as far as possible and its drawing should be faster.

=item C<$i-E<gt>diamond ($x0, $y0, $x1, $y1, $colour)>

=item C<$i-E<gt>diamond ($x0, $y0, $x1, $y1, $colour, $fill)>

Draw a diamond shape within the rectangle top left C<$x0,$y0> and bottom
right C<$x1,$y1> using C<$colour>.  If optional argument C<$fill> is true
then the diamond is filled.

For reference, in the current implementation unfilled diamonds use the
Imager C<polyline()> but filled diamonds use the C<Image::Base> code since
the Imager filled C<polygon()> is always blurred by anti-aliasing and don't
want that (or not by default).

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save to C<-file>, or with a C<$filename> argument set C<-file> then save to
that.

The file format is taken from the C<-file_format> (see below) if that was
set by a C<load> or explicit C<set>, otherwise Imager follows the filename
extension.  In both cases if format or extension is unrecognised then
C<save()> croaks.

=item C<$image-E<gt>add_colours ($name, $name, ...)>

Add colours to the image palette.  Colour names are the same as to the
drawing functions.

    $image->add_colours ('red', 'green', '#FF00FF');

For a non-paletted image C<add_colours> does nothing since in that case each
pixel has RGB component values, rather than an index into a palette.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Setting these changes the size of the image.

=item C<-imager>

The underlying C<Imager> object.

=item C<-file_format> (string or C<undef>)

The file format as a string like "png" or "jpeg", or C<undef> if unknown or
never set.

After C<load()> the C<-file_format> is the format read.  Setting
C<-file_format> can change the format for a subsequent C<save()>.

This is held in the imager "i_format" tag and passed as the C<type> when
saving.  If C<undef> when saving, Imager will look at the filename
extension.

There's no attempt to check or validate the C<-file_format> value, since
it's possible to add new formats to Imager at run time.  Expect C<save()> to
croak if the format is unknown.

=item C<-hotx> (integer or C<undef>, default C<undef>)

=item C<-hoty> (integer or C<undef>, default C<undef>)

The cursor hotspot in CUR images (variant of ICO).  These are the
C<cur_hotspotx> and C<cur_hotspoty> tags in the Imager object.

=item C<-ncolours> (integer, read-only)

The number of colours allocated in the palette, or C<undef> on a
non-paletted image.  (The Imager C<colorcount>.)

This is similar to the C<-ncolours> of C<Image::Xpm>.

=item C<-quality_percent> (0 to 100 or C<undef>)

The image quality when saving to JPEG format, or to TIFF format with jpeg
compression method.  JPEG compresses by reducing colours and resolution in
ways that are not too noticeable to the human eye.  100 means full quality,
no such reductions.  C<undef> means the Imager default, which is 75.

C<-quality_percent> becomes the C<jpegquality> and C<tiff_jpegquality>
options to the Imager write (see L<Imager::Files/JPEG> and
L<Imager::Files/TIFF>).  TIFF is only affected if its C<tiff_compression>
tag is set to "jpeg" using Imager C<settag()> (the default is "packbits").

=back

There's no C<-zlib_compression> currently since believe Imager version 0.79
doesn't have anything to apply that to PNG saving.

=head1 SEE ALSO

L<Image::Base>,
L<Imager>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-imager/index.html

=head1 LICENSE

Image-Base-Imager is Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-Imager is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Imager is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Imager.  If not, see <http://www.gnu.org/licenses/>.

=cut

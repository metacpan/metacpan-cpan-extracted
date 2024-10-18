# Copyright 2010, 2011, 2012, 2019, 2024 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::GD;
use 5.006;
use strict;
use warnings;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 17;

use Image::Base 1.12; # version 1.12 for ellipse() $fill
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub new {
  my ($class, %params) = @_;
  ### Image-Base-GD new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    if (! defined $params{'-gd'}) {
      $params{'-gd'} = $self->get('-gd')->clone;
    }
    # inherit everything else
    %params = (%$self, %params);
    ### copy params: \%params
  }

  my $self = bless { -allocate_colours => 1,
                     -zlib_compression => -1,
                     -file_format => 'png' }, $class;
  if (! defined $params{'-gd'}) {
    if (defined (my $filename = delete $params{'-file'})) {
      $self->load ($filename);

    } else {
      my $truecolor = !! delete $params{'-truecolor'};
      my $width = delete $params{'-width'};
      my $height = delete $params{'-height'};
      require GD;
      my $gd = $self->{'-gd'} = GD::Image->new ($width, $height, $truecolor)
        || croak "Cannot create GD";  # undef if cannot create
      $gd->alphaBlending(0);
    }
  }
  $self->set (%params);
  ### new made: $self
  return $self;
}

my %attr_to_get_method = (-width      => 'width',
                          -height     => 'height',
                          -ncolours   => 'colorsTotal',

                          # these not documented yet ...
                          -truecolor  => 'isTrueColor',
                          -interlaced => 'interlaced');
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-GD _get(): $key

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-gd'}->$method;
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-GD set(): \%param

  foreach my $key ('-width', '-height', '-ncolours') {
    if (exists $param{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  # these not documented yet ...
  if (exists $param{'-interlaced'}) {
    $self->{'-gd'}->interlaced (delete $param{'-interlaced'});
  }
  if (exists $param{'-truecolor'}) {
    my $gd = $self->{'-gd'};
    if (delete $param{'-truecolor'}) {
      if (! $gd->isTrueColor) {
        die "How to turn palette into truecolor?";
      }
    } else {
      if ($gd->isTrueColor) {
        $gd->trueColorToPalette;
      }
    }
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->{'-file'};
  } else {
    $self->set('-file', $filename);
  }

  my $fh;
  open $fh, '<', $filename
    or croak "Cannot open file $filename: $!";
  binmode $fh
    or croak 'Error setting binary mode: ',$!;

  my $filepos = tell($fh);
  my $bytes = '';
  read($fh,$bytes,9);
  ### $bytes

  my $file_format;
  my $method;
  if    ($bytes =~ /^\x89PNG/)        { $file_format = 'png';  }
  elsif ($bytes =~ /^\xFF\xD8/)       { $file_format = 'jpeg'; }
  elsif ($bytes =~ /^GIF8/)           { $file_format = 'gif';  }
  elsif ($bytes =~ /^gd2\0/)          { $file_format = 'gd2';  }
  elsif ($bytes =~ m{^/\* XPM \*/})   { $file_format = 'xpm'; }
  elsif ($bytes =~ m/^#define /)      { $file_format = 'xbm';
                                        $method = "_newFromXbm"; }
  elsif ($bytes =~ m/^\0\0/)          { $file_format = 'wbmp';
                                        $method = "_newFromWBMP"; }

  # Image::WMF (as of 1.01) doesn't have a file reader to then extend perhaps.
  # elsif ($bytes =~ m/^\327\315\306\232/) {
  #   require Image::WMF;
  #   my $class = 'Image::WMF';
  #   $file_format = 'wmf';
  #   $method = "newFromWMF"; }

  # GD::SVG (as of 0.33) doesn't have a file reader to then extend perhaps.
  # elsif ($bytes =~ m/^<?xml/) {
  #   require GD::SVG;
  #   my $class = 'GD::SVG::Image';
  #   $file_format = 'svg';
  #   $method = "newFromSVG"; }

  elsif ($bytes =~ /^\xFF[\xFF\xFE]/
         || (length($bytes) >= 4
             && do {
               my ($width, $height) = unpack 'nn', $bytes;
               -s $fh == 4 + 3 + 256*3 + $width * $height
             })) {
    $file_format = 'gd';
  } else {
    croak "Unrecognised file format";
  }
  $method ||= "newFrom\u$file_format";
  ### $method

  my $fh_filename = $filename;
  if ($file_format eq 'xpm' || ! seek($fh,$filepos,0)) {
    require File::Temp;
    my $tempfh = File::Temp->new (UNLINK => 0);
    binmode $tempfh or croak 'Error setting binary mode: ',$!;

    my $rest = do { local $/; <$fh> }; # slurp
    print $tempfh $bytes, $rest or croak 'Error writing temp file: ',$!;
    seek $tempfh, 0, 0 or croak "Error rewinding temp file: $!";

    # require File::Copy;
    # File::Copy::copy($fh,$tempfh)
    #     or croak "Error copying $filename: $!";
    ### input size: -s $fh
    ### copied size: -s $tempfh
    ### tell fh: tell($fh)
    ### tell temp: tell($tempfh)

    close $fh or croak "Error closing $filename: $!";

    $fh = $tempfh;
    $fh_filename = $tempfh->filename;
  }
  ### tell: tell($fh)

  require GD;
  my $gd;
  if ($file_format eq 'xpm') {
    # newFromXpm() will only read a filename, not a handle
    ### newFromXpm(): $fh_filename
    $gd = GD::Image->newFromXpm($fh_filename);
  } else {
    $gd = GD::Image->$method($fh);
  }
  ### $gd

  close $fh
    or croak "Error closing $fh_filename: $!";

  if (! $gd) {
    croak "Unrecognised data or error reading ",$filename;

    # undef $@;
    # my $err = $@;
    # newFromXpm() error message dodgy
    # if (defined $err) {
    #   croak $err;
    # } else {
    # }
  }

  $self->{'-gd'} = $gd;
  $self->{'-file_format'} = $file_format;
  $gd->alphaBlending(0);
}

# check -file_format, don't call an arbitrary func/method through its name
my %file_format_save_method = (jpeg => 'jpeg',
                               gif  => 'gif',
                               gd   => 'gd',
                               gd2  => 'gd2',
                               png  => 'png',
                               svg  => 'svg', # experimental for GD::SVG::Image
                               wmf  => 'wmf', # experimental for Image::WMF
                              );
my %text_mode = (svg => 1);

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-GD save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->{'-file'};
  }
  ### $filename

  my $gd = $self->{'-gd'};
  my $file_format;
  if (defined ($file_format = $self->{'-file_format'})) {
    $file_format = lc($file_format);
  } else {
    $file_format = 'png'; # default
  }

  my $data;
  if ($file_format eq 'png') {
    $data = $gd->png ($self->get('-zlib_compression'));
  } elsif ($file_format eq 'jpeg') {
    my $quality = $self->get('-quality_percent');
    $data = $gd->jpeg (defined $quality ? $quality : -1);
  } elsif ($file_format eq 'wbmp') {
    # In libgd 2.0.36 gdImageWBMPCtx() the "foreground" index arg becomes
    # WBMP_BLACK.  In WAP world black is the foreground is it?  In any case
    # 'black' here makes save+load of a GD to wbmp come back the right way
    # around.
    # http://www.wapforum.org/what/technical/SPEC-WAESpec-19990524.pdf
    ### wbmp fg: $self->colour_to_index('black')
    $data = $gd->wbmp ($self->colour_to_index('black'));
  } elsif (my $method = $file_format_save_method{$file_format}) {
    $data = $gd->$method;
  } else {
    croak 'Cannot save file format ',$file_format;
  }

  # or maybe File::Slurp::write_file($filename,{binmode=>':raw'})
  my $fh;
  (open $fh, '>', $filename
   and ($text_mode{$file_format} || binmode($fh))
   and print $fh $data
   and close $fh)
    or croak "Error writing $filename: $!";
}

#------------------------------------------------------------------------------

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-GD xy(): $x,$y,$colour

  my $gd = $self->{'-gd'};
  if (@_ == 4) {
    $gd->setPixel ($x, $y, $self->colour_to_index($colour));
    ### setPixel: $self->colour_to_index($colour)
  } else {
    my $pixel = $gd->getPixel ($x, $y);
    #### getPixel: $pixel
    if ($pixel == $gd->transparent) {
      #### is transparent
      return 'None';
    }
    if ($pixel >= 0x7F000000) {
      #### pixel has fully-transparent alpha 0x7F
      return 'None';
    }
    #### rgb: $gd->rgb($pixel)
    return sprintf ('#%02X%02X%02X', $gd->rgb($pixel));
  }
}

sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-GD line(): @_

  $self->{'-gd'}->line ($x1,$y1,$x2,$y2, $self->colour_to_index($colour));
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-GD rectangle(): @_[1..$#_]

  # ### index: $self->colour_to_index($colour)

  # libgd circa 2.0.35 gdImageFilledRectangle() has a bug where if the x1,x2
  # range is all negative then it draws a pixels in the x=0 left edge.  Or
  # similarly if y1,y2 all negative then it draws in the y=0 top edge.
  # Think this is a bug, the comments in the code suggest it's supposed to
  # drawn nothing for all-negative.  In any case avoid this in the interests
  # of behaving like other Image-Base new style clipping 0,0,width,height.
  #
  if ($x2 < 0 || $y2 < 0) {
    ### all negative, workaround to drawn nothing ...
    return;
  }

  # libgd circa 2.0.35 has a bug where it draws a $y1==$y2 unfilled
  # rectangle with dodgy sides like
  #
  #     *      *
  #     ********
  #     *      *
  #
  # As a workaround send $y1==$y2 to filledRectangle() instead.
  #
  my $method = ($fill || $y1 == $y2
                ? 'filledRectangle'
                : 'rectangle');
  $self->{'-gd'}->$method ($x1,$y1,$x2,$y2, $self->colour_to_index($colour));
}

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-GD ellipse: "$x1, $y1, $x2, $y2, $colour, ".($fill||0)

  # If width $xw or height $yw is an odd number then GD draws the extra
  # pixel on the higher value side, ie. the centre is the rounded-down
  # position.  Dunno if that should be relied on.
  #
  # some versions of libgd prior to 2.0.36 seem to draw nothing for
  # filledEllipse() on an x1==x2 y1==y2 single-pixel ellipse.  Try sending 1
  # or 2 pixel wide or high to the base ellipse() and from there to
  # filledRectangle() instead.
  #
  my $xw = $x2 - $x1;
  my $yw = $y2 - $y1;
  my $gd = $self->{'-gd'};
  if ($gd->isa('GD::SVG::Image')
      || ($xw > 1 && ! ($xw & 1)
          && $yw > 1 && ! ($yw & 1))) {
    ### x centre: $x1 + $xw/2
    ### y centre: $y1 + $yw/2
    ### $xw+1
    ### $yw+1
    my $method = ($fill ? 'filledEllipse' : 'ellipse');
    $gd->$method ($x1 + $xw/2, $y1 + $yw/2,
                  $xw+1, $yw+1,
                  $self->colour_to_index($colour));
  } else {
    ### use Image-Base by pixels ...
    shift->SUPER::ellipse(@_);
  }
}

sub diamond {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-GD diamond() ...

  my $gd = $self->{'-gd'};
  if ($x1 == $x2 || $y1 == $y2) {
    # as of libgd 2.0.36 a filledpolygon of 1x1 or Nx1 draws no pixels, go
    # to rectangle in that case
    $gd->filledRectangle ($x1,$y1,$x2,$y2,
                          $self->colour_to_index($colour));

  } else {
    my $xh = ($x2 - $x1);
    my $yh = ($y2 - $y1);
    my $xeven = ($xh & 1);
    my $yeven = ($yh & 1);
    $xh = int($xh / 2);
    $yh = int($yh / 2);
    ### assert: $x1+$xh+$xeven == $x2-$xh
    ### assert: $y1+$yh+$yeven == $y2-$yh

    my $poly = GD::Polygon->new;
    $poly->addPt ($x1+$xh,$y1);  # top centre

    # left
    $poly->addPt ($x1,$y1+$yh);
    if ($yeven) { $poly->addPt ($x1,$y2-$yh); }

    # bottom
    $poly->addPt ($x1+$xh,$y2);
    if ($xeven) { $poly->addPt ($x2-$xh,$y2); }

    # right
    if ($yeven) { $poly->addPt ($x2,$y2-$yh); }
    $poly->addPt ($x2,$y1+$yh);

    # top again
    if ($xeven) { $poly->addPt ($x2-$xh,$y1); }

    ### $poly
    my $method = ($fill ? 'filledPolygon' : 'openPolygon');
    $gd->$method ($poly, $self->colour_to_index($colour));
  }
}

#------------------------------------------------------------------------------
# colours

sub add_colours {
  my $self = shift;
  ### add_colours: @_

  my $gd = $self->{'-gd'};
  if ($gd->isTrueColor) {
    ### no allocation in truecolor
    return;
  }

  foreach my $colour (@_) {
    ### $colour
    if ($colour eq 'None') {
      if ($gd->transparent() != -1) {
        ### transparent already: $gd->transparent()
        next;
      }
      if ((my $index = $self->{'-gd'}->colorAllocateAlpha(0,0,0,127)) != -1) {
        $gd->transparent ($index);
        ### transparent now: $gd->transparent
        next; # successful
      }

    } else {
      my @rgb = _colour_to_rgb255($colour);
      if ($gd->can('colorExact')  # not available in Image::WMF pre 1.03
          && $gd->colorExact(@rgb) != -1) {
        ### already exists: $gd->colorExact(@rgb)
        next;
      }
      if ($gd->colorAllocate(@rgb) != -1) {
        ### allocated
        next;
      }
    }
    croak "Cannot allocate colour: $colour";
  }
}

# not documented yet ...
sub colour_to_index {
  my ($self, $colour) = @_;
  ### Image-Base-GD colour_to_index(): $colour
  my $gd = $self->{'-gd'};
  # while ($gd->isa('GD::Window')) {
  #   $gd = $gd->{im};
  # }

  if ($colour eq 'None') {
    if ($gd->isTrueColor) {
      ### truecolor transparent: $gd->colorAllocateAlpha(0,0,0,127)
      return $gd->colorAllocateAlpha(0,0,0,127);
    }

    # Crib note: gdImageColorExactAlpha() doesn't take the single
    # transparent() colour as equivalent to all transparents but instead
    # looks for R,G,B to match as well as the alpha.
    #
    if ((my $index = $gd->transparent) != -1) {
      ### existing palette transparent: $index
      return $index;
    }
    if (! $self->{'-allocate_colours'}) {
      croak "No transparent index set";
    }
    if ((my $index = $self->{'-gd'}->colorAllocate(0,0,0)) != -1) {
      $gd->transparent ($index);
      ### transparent now: $gd->transparent
      return $index;
    }
    croak "No colour cells free to create transparent";
  }

  my @rgb = _colour_to_rgb255($colour);
  ### @rgb
  if ($self->{'-allocate_colours'}) {
    if ($gd->can('colorExact')  # not available in Image::WMF
        && (my $index = $gd->colorExact (@rgb)) != -1) {
      ### existing exact: $index
      return $index;
    }
    if ((my $index = $gd->colorAllocate (@rgb)) != -1) {
      ### allocate: $index
      return $index;
    }
  }
  ### closest: $gd->colorClosest(@rgb)
  return $gd->colorClosest (@rgb);
}

sub _colour_to_rgb255 {
  my ($colour) = @_;

  # 1 to 4 digit hex
  # Crib: [:xdigit:] matches some wide chars, but hex() as of perl 5.12.4
  # doesn't accept them, so only 0-9A-F
  if ($colour =~ /^#(([0-9A-F]{3}){1,4})$/i) {
    my $len = length($1)/3; # of each group, so 1,2,3 or 4
    return (map {hex(substr($_ x 2, 0, 2))} # first 2 chars of replicated
            substr ($colour, 1, $len),      # full size groups
            substr ($colour, 1+$len, $len),
            substr ($colour, -$len));
  }

  require GD::Simple;
  if (defined (my $aref = GD::Simple->color_names->{lc($colour)})) {
    ### table: $aref
    return @$aref;
  }
  croak "Unknown colour: $colour";
}

1;
__END__

=for stopwords GD gd libgd filename Ryde Zlib Zlib's truecolor RGBA PNG png JPEG jpeg XPM WBMP SVG svg GIF wmf libjpeg

=head1 NAME

Image::Base::GD -- draw images with GD

=head1 SYNOPSIS

 use Image::Base::GD;
 my $image = Image::Base::GD->new (-width => 100,
                                   -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::GD> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::GD

=head1 DESCRIPTION

C<Image::Base::GD> extends C<Image::Base> to create or update image files in
various formats using the C<GD> module and library (libgd version 2 or
higher).

Native GD drawing has many more features but this module is an easy way to
point C<Image::Base> style code at a GD and is a good way to get PNG and
other formats out of C<Image::Base> code.

=head2 Colour Names

Colour names for drawing are

    GD::Simple->color_names()
    "#RGB"           hex upper or lower case
    "#RRGGBB"
    "#RRRGGGBBB"
    "#RRRRGGGGBBBB"
    "None"           transparent

See L<GD::Simple> for its C<color_names()> list.  Special "None" means
transparent.  Colours are allocated when first used.  GD works in 8-bit
components so 3 and 4-digit hex forms are truncated to the high 2 hex
digits, and 1-digit hex "#123" expands to "#112233".

=head2 File Formats

C<GD> can read and write

    png      with libpng
    jpeg     with libjpeg
    gif      unless disabled in GD.pm
    wbmp     wireless app bitmap

And prior to libgd version 2.32 (now gone),

    gd       GD's own format, raw
    gd2      GD's own format, compressed

And read-only,

    xpm      with libXpm
    xbm

PNG, JPEG and XPM are available if libgd is compiled with the respective
support libraries.  GIF will be unavailable if the Perl C<GD> interface was
built with its option to disable GIF.

C<load()> auto-detects the file format and calls the corresponding
C<newFromPng()> etc.  "gd" file format differs between libgd 1.x and 2.x.
libgd 2.x could load the 1.x format, but always wrote 2.x so that's what
C<save()> here gives.  Both "gd" formats were a byte dump mainly intended
for temporary files but are unsupported in current libgd.

WBMP is a bitmap format and is treated by GD as colours black "#000000" for
0 and white "#FFFFFF" for 1.  On save, any non-black is treated as white 1
too, but not sure that's a documented feature.

=head2 Other GD Modules

Some other modules implement a GD-like interface with other output types or
features.  To the extent they're GD-compatible they should work passed in as
a C<-gd> object here.

C<GD::SVG::Image> (see L<GD::SVG>) can be saved with C<-file_format> set to
"svg".  (Or see C<Image::Base::SVG> to go directly to an C<SVG> module
object if that's desired.)

C<Image::WMF> (see L<Image::WMF>) can be saved by setting C<-file_format>
to "wmf".

C<GD::Window> (see L<GD::Window>) as of its version 0.02 almost works in
C<passThrough> mode, but look for a bug fix post 0.02.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::GD-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    $image = Image::Base::GD->new (-width => 200, -height => 100);

Or an existing file can be read,

    $image = Image::Base::GD->new (-file => '/some/filename.png');

Or a C<GD::Image> object can be given,

    $image = Image::Base::GD->new (-gd => $gdimageobject);

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

Create and return a copy of C<$image>.  The GD within C<$image> is cloned
(per C<$gd-E<gt>clone()>).  The optional parameters are applied to the new
image as per C<set()>.

    # copy image, new compression level
    my $new_image = $image->new (-zlib_compression => 9);

=item C<$colour = $image-E<gt>xy ($x, $y)>

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set an individual pixel.

Currently the C<$colour> return is hex "#RRGGBB", or "None" for a fully
transparent pixel.  Partly transparent pixels are returned as a colour.

=item C<$image-E<gt>rectangle ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw a rectangle with corners at C<$x1>,C<$y1> and C<$x2>,C<$y2>.  If
C<$fill> is true then it's filled, otherwise just the outline.

GD library 2.0.36 has a bug when drawing 1-pixel high C<$y1 == $y2> unfilled
rectangles where it adds 3-pixel high sides to the result.
C<Image::Base::GD> has a workaround to avoid that.  The intention isn't to
second guess GD, but this fix is easy to apply and makes the output
consistent with other C<Image::Base> modules.

=item C<$image-E<gt>ellipse ($x1,$y1, $x2,$y2, $colour)>

=item C<$image-E<gt>ellipse ($x1,$y1, $x2,$y2, $colour, $fill)>

Draw an ellipse within the rectangle with top-left corner C<$x1>,C<$y1> and
bottom-right C<$x2>,C<$y2>.  Optional C<$fill> true means a filled ellipse.

In the current implementation, ellipses with odd length sides (meaning
C<$x2-$x1+1> and C<$y2-$y1+1> both odd numbers) are drawn with GD.  The rest
go to C<Image::Base> because GD circa 2.0.36 doesn't seem to draw even
widths very well.  This different handling for different sizes is a bit
inconsistent.

=item C<$image-E<gt>add_colours ($name, $name, ...)>

Add colours to the GD palette.  Colour names are the same as for the drawing
functions.

    $image->add_colours ('red', 'green', '#FF00FF');

The drawing functions automatically add a colour if it doesn't already exist
so C<add_colours()> is not needed, but it can be used to initialize the
palette with particular desired colours.

For a truecolor GD, C<add_colours()> does nothing since in that case each
pixel has its own RGBA rather than an index into a palette.

=item C<< $image->load >>

=item C<< $image->load ($filename) >>

Read the C<-file>, or set C<-file> to C<$filename> and then read.  This
creates and sets a new underlying C<-gd> because it's not possible to read
into an existing GD image object, only a new one.

=item C<$image-E<gt>save>

=item C<$image-E<gt>save ($filename)>

Save to C<-file>, or with a C<$filename> argument set C<-file> then save to
that.  The file format written is taken from the C<-file_format> (see
below).

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a GD image cannot be changed once created.

=item C<-ncolours> (integer, read-only)

The number of colours allocated in the palette, or C<undef> on a truecolor
GD (which doesn't have a palette).

This count is similar to the C<-ncolours> of C<Image::Xpm>.

=item C<-file_format> (string)

The file format as a string like "png" or "jpeg".  See L</File Formats>
above for the choices.

After C<load()> the C<-file_format> is the format read.  Setting
C<-file_format> can change the format for a subsequent C<save>.

The default is "png", which means a newly created image (not read from a
file) is saved as PNG by default.

=item C<-quality_percent> (0 to 100 or C<undef>)

The image quality when saving to JPEG format.  JPEG compresses by reducing
colours and resolution.  100 means full quality, no such reductions.
C<undef> means the libjpeg default (which is normally 75).

This becomes the C<$quality> parameter to C<$gd-E<gt>jpeg()>.

=item C<-zlib_compression> (integer 0-9 or -1, default -1)

The amount of data compression to apply when saving.  The value is Zlib
style 0 for no compression up to 9 for maximum effort.  -1 means Zlib's
default level (usually 6).

This becomes the C<$compression_level> parameter to C<$gd-E<gt>png()>.

=item C<-gd>

The underlying C<GD::Image> object.

=back

=head1 BUGS

Putting colour "None" into pixels requires GD "alpha blending" turned off.
C<Image::Base::GD> turns off blending for GD objects it creates, but
currently if you pass in a C<-gd> then you must set the blending yourself if
you're going to use None.  Is that the best way?  The ideal might be to save
and restore blending while drawing None, but there's no apparent way to read
back the blending out of a GD to later restore.  Or maybe turn blending off
and leave it off on first drawing any None.

=head1 SEE ALSO

L<Image::Base>,
L<GD>,
L<GD::Simple>

L<Image::Base::PNGwriter>,
L<Image::Xpm>

L<GD::SVG>, L<GD::Window>, L<Image::WMF>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-gd/index.html

=head1 LICENSE

Image-Base-GD is Copyright 2010, 2011, 2012, 2019, 2024 Kevin Ryde

Image-Base-GD is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-GD is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

=cut

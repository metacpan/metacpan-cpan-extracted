# Copyright 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::Wx::Image;
use 5.008;
use strict;
use Carp;
use Wx;
our $VERSION = 4;

use Image::Base;
our @ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class, %params) = @_;
  ### Image-Base-Wx-Image new: \%params

  my $self;
  my $wximage = delete $params{'-wximage'};
  my $filename = delete $params{'-file'};

  if (ref $class) {
    # $obj->new(...) means make a copy, with some extra settings
    $self = bless { %$class }, ref $class;

    # clone wximage if a new one not given in the %params
    if (! defined $wximage) {
      # wxPerl circa 0.9901 doesn't have the copy-on-write constructor, so a
      # full ->Copy
      $wximage = $self->{'-wximage'}->Copy;
    }
  } else {
    if (! $wximage) {
      # no clear parameter ?
      $wximage = Wx::Image->new
        (delete $params{'-width'}||0,
         delete $params{'-height'}||0);
    }
    $self = bless { }, $class;
  }
  $self->set (-wximage => $wximage,
              %params);
  ### $filename
  if (defined $filename) {
    $self->load ($filename);
  }
  ### new created: $self
  return $self;
}

my %attr_to_get_method
  = (-width  => 'GetWidth',
     -height => 'GetHeight');
my %attr_to_option
  = (-hotx   => Wx::wxIMAGE_OPTION_CUR_HOTSPOT_X(),
     -hoty   => Wx::wxIMAGE_OPTION_CUR_HOTSPOT_Y(),
     -quality_percent => Wx::wxIMAGE_OPTION_QUALITY(),
    );
sub _get {
  my ($self, $key) = @_;
  my $wximage = $self->{'-wximage'};
  if (my $method = $attr_to_get_method{$key}) {
    return $wximage->$method();
  }
  if (my $option = $attr_to_option{$key}) {
    # all of the above options are integers hence GetOptionInt()
    return ($wximage->HasOption($option)
            ? $wximage->GetOptionInt($option)
            : undef);
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-Base-Wx-Image set: \%params

  # -wximage before applying -width,-height
  if (my $wximage = delete $params{'-wximage'}) {
    $self->{'-wximage'} = $wximage;
  }
  if (exists $params{'-width'} || exists $params{'-height'}) {
    my $wximage = $self->{'-wximage'};
    my $width = (exists $params{'-width'}
                 ? delete $params{'-width'}
                 : $wximage->GetWidth);
    my $height = (exists $params{'-height'}
                  ? delete $params{'-height'}
                  : $wximage->GetHeight);
    $wximage->Resize(Wx::Size->new($width,$height),
                     0,0,0); # fill with black
  }
  foreach my $key (keys %params) {
    if (my $option = $attr_to_option{$key}) {
      $self->{'-wximage'}->SetOption($option, delete $params{$key});
    }
  }
  %$self = (%$self,
            %params);
  ### set leaves: $self
}

#------------------------------------------------------------------------------
# load/save
#
# $self->{'-wximage'}->LoadFile($filename,Wx::wxBITMAP_TYPE_ANY()) tries all
# registered handlers, but doesn't seem to report which one succeeded.
#
# Wx::Image::GetHandlers not wrapped in wxPerl 0.9901.

# Note: must try CUR before ICO to pick up HotSpotX and HotSpotY
my @file_formats = (qw(BMP
                       GIF
                       JPEG
                       PCX
                       PNG
                       PNM
                       TIF
                       XPM
                       CUR
                       ICO
                       ANI));
my @image_types = map { my $constant = "wxBITMAP_TYPE_$_";
                        my $type = eval "Wx::$constant()";
                        if (! defined $type) {
                          die "Oops, no $constant: $@";
                        }
                        $type } @file_formats;
### @image_types

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  ### load: $filename

  $filename = "$filename"; # stringize to dispatch to file read
  open my $fh, '<', $filename
    or croak "Cannot load $filename: $!";

  my $wximage = $self->{'-wximage'};
  foreach my $i (0 .. $#file_formats) {
    my $file_format = $file_formats[$i];
    my $type = $image_types[$i];
    ### $file_format
    ### $type

    my $handler = Wx::Image::FindHandlerType($type) || next;
    ### $handler
    if ($handler->LoadFile ($wximage, $fh, $self->{'-load_verbose'})) {
      $self->{'-file_format'} = $file_format;
      return;
    }
    seek $fh,0,0 or croak "Cannot rewind $filename: $!";
  }
  croak "Cannot load ",$filename;
}

# sub load_fh {
#   my ($self, $fh, $filename) = @_;
#   ### load_fh()
# 
#   $self->{'-wximage'}->LoadFile($fh,Wx::wxBITMAP_TYPE_ANY())
#     or croak "Cannot read file",
#       (defined $filename ? (' ',$filename) : ());
# }

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Pixbuf save(): @_
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  my $file_format = $self->get('-file_format')
    || croak "-file_format not set";
  $file_format = lc($file_format);
  if ($file_format eq 'jpg') {
    $file_format = 'jpeg';
  }
  my $handler = Wx::Image::FindHandlerMime("image/$file_format")
    || Wx::Image::FindHandlerMime("image/x-$file_format")
      || do {
        my $class = "Wx::\U$file_format\EHandler";
        $class->isa('Wx::ImageHandler') && $class->new
      }
        || croak "Unrecognised -file_format ",$file_format;

  open my $fh, '>', $filename
    or croak "Cannot save $filename: $!";
  $handler->SaveFile($self->{'-wximage'}, $fh)
    or croak "Error saving $filename (handler ",$handler->GetName,")";
  close $fh
    or croak "Error saving $filename: $!";
}

sub save_fh {
  my ($self, $fh, $filename) = @_;
  ### Image-Base-Pixbuf save(): @_

  my $file_format = $self->get('-file_format');
  # if (! defined $file_format) {
  #   $file_format = _filename_to_format($filename);
  #   if (! defined $file_format) {
  #     croak 'No -file_format set';
  #   }
  # }

  $self->{'-wximage'}->SaveFile($fh, "image/$file_format")
    or croak "Cannot save file",
      (defined $filename ? (' ',$filename) : ());
}

#------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;
  my $wximage = $self->{'-wximage'};
  if (@_ >= 4) {
    if (lc($colour) eq 'none') {
      # wx 2.8.12 docs say InitAlpha is an error if already have alpha data.
      # That doesn't seem to be so, but check just in case.
      unless ($wximage->HasAlpha) { $wximage->InitAlpha; }

      # SetAlphaXY() for dubious overload dispatch in wxPerl 0.9901
      $wximage->SetAlphaXY($x,$y,0);

    } else {
      $wximage->SetRGB($x,$y, $self->colour_to_rgb($colour));
    }
  } else {
    if ($x < 0 || $y < 0
        || $x >= $wximage->GetWidth || $y >= $wximage->GetHeight) {
      return undef;
    }
    if ($wximage->IsTransparent($x,$y,128)) {
      return 'None';
    }
    return sprintf('#%02X%02X%02X',
                   $wximage->GetRed($x,$y),
                   $wximage->GetBlue($x,$y),
                   $wximage->GetGreen($x,$y));
  }
}

sub line {
  my $self = shift;
  my ($x1,$y1, $x2,$y2, $colour) = @_;
  ### Image-Base-Wx-Image line() ...

  if (lc($colour) ne 'none'
      && ($x1 == $x2 || $y1 == $y2)) {
    # horizontal or vertical as rectangle
    if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); }
    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); }
    $self->{'-wximage'}->SetRGB(Wx::Rect->new($x1,$y1, $x2-$x1+1, $y2-$y1+1),
                                $self->colour_to_rgb($colour));
  } else {
    $self->SUPER::line(@_);
  }
}

sub rectangle {
  my $self = shift;
  my ($x1, $y1, $x2, $y2, $colour, $fill) = @_;
  # ### Image-Base-Wx-Image rectangle: "$x1, $y1, $x2, $y2, $colour, $fill"

  # 2xN, Nx2 or filled with SetRGB(rect)
  my $w = $x2-$x1;
  my $h = $y2-$y1;
  if (lc($colour) ne 'none'
      && ($fill || ($w <= 1 || $h <= 1))) {
    $self->{'-wximage'}->SetRGB(Wx::Rect->new($x1,$y1, $w+1, $h+1),
                                $self->colour_to_rgb($colour));
  } else {
    $self->SUPER::rectangle(@_);
  }
}

sub ellipse {
  my $self = shift;
  my ($x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Wx-Image ellipse: "$x1, $y1, $x2, $y2, $colour, ".($fill||0)

  my $w = $x2-$x1;
  my $h = $y2-$y1;
  if (lc($colour) ne 'none'
      && ($fill || ($w == 0 || $h == 0))) {
    # horizontal or vertical line as rectangle
    $self->{'-wximage'}->SetRGB(Wx::Rect->new($x1,$y1, $w+1, $h+1),
                                $self->colour_to_rgb($colour));
  } else {
    $self->SUPER::rectangle(@_);
  }
}

#------------------------------------------------------------------------------
# colours

my %colour_obj = (set   => [0xFF,0xFF,0xFF],
                  clear => [0,0,0]);
sub colour_to_rgb {
  my ($self, $colour) = @_;

  # builtin names
  if (my $aref = $colour_obj{lc($colour)}) {
    return @$aref;
  }

  # 1 to 4 digit hex
  if ($colour =~ /^#(([0-9A-F]{3}){1,4})$/i) {
    my $len = length($1)/3; # of each group, so 1,2,3 or 4
    return (map {hex(substr($_ x 2, 0, 2))} # first 2 chars of replicated
            substr ($colour, 1, $len),      # groups of $len each
            substr ($colour, 1+$len, $len),
            substr ($colour, -$len));
  }

  my $colour_obj = Wx::ColourDatabase::Find($colour);
  if (! $colour_obj->IsOk) {
    croak "ColourDatabase unrecognised name: ",$colour;
  }
  return ($colour_obj->Red, $colour_obj->Green, $colour_obj->Blue);
}

1;
__END__

=for stopwords resized filename Ryde bitmap

=head1 NAME

Image::Base::Wx::Image -- draw into a Wx::Image

=for test_synopsis my $wximage

=head1 SYNOPSIS

 use Image::Base::Wx::Image;
 my $image = Image::Base::Wx::Image->new
                 (-width => 200, -height => 100);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Wx::Image> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Wx::Image

=head1 DESCRIPTION

C<Image::Base::Wx::Image> extends C<Image::Base> to draw
into a C<Wx::Image>.

A C<Wx::Image> is platform-independent 24-bit RGB image.  Drawing is done
with C<SetRGB()> of pixels and rectangles.  A C<Wx::Image> cannot be drawn
with C<Wx::DC> or displayed directly, though it can be converted to a
platform-dependent C<Wx::Bitmap> for display.

=head2 File Formats

The file formats supported in Wx 2.8 include the following, perhaps
depending which supporting libraries it was built with.

    BMP      always available
    PNG
    JPEG
    GIF      load-only
    PCX
    PNM
    TIFF
    TGA      load-only
    IFF      load-only
    XPM
    ICO
    CUR
    ANI      load-only

Each format has a C<Wx::ImageHandler> class.  C<save()> creates a handler
for the target C<-file_format> as necessary.  C<load()> attempts all the
globally registered handlers.  All formats can be registered with

    Wx::InitAllImageHandlers();

Or just selected ones with for example

    Wx::Image::AddHandler (Wx::PNGHandler->new);

=head2 Colour Names

Colour names are 1 to 4 digit hex and anything recognised by
C<Wx::ColourDatabase>,

    "pink" etc        wxColourDatabase
    "#RGB"            1 to 4 digit hex
    "#RRGGBB"
    "#RRRGGGBBB"
    "#RRRRGGGGBBB"
    "None"            transparent

Special colour "None" means transparent, which is applied by C<SetAlpha()>
on the drawn pixels.  The way it's done here is slightly experimental yet.
In the current code drawing a colour doesn't turn pixels back to opaque.
The intention would be that it should, but don't really want to do a
C<SetAlpha> call on top of C<SetRGB> for every pixel.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::Wx::Image-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  It can read a file,

    $image = Image::Base::Wx::Image->new
               (-file => '/my/file/name.bmp');

Or start a new image created with width and height,

    $image = Image::Base::Wx::Image->new
                 (-width  => 200,
                  -height => 100);

Or be pointed at an existing wxImage object,

    my $wximage = Wx::Image->new (200, 100);
    my $image = Image::Base::Wx::Image->new
                 (-wximage => $wximage);

Further parameters are applied per C<set> (see L</ATTRIBUTES> below).

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set the pixel at C<$x>,C<$y>.

Getting a pixel is per C<Wx::Image> C<GetPixel()>.  In the current code colours
are returned in "#RRGGBB" form.

=item C<< $image->load () >>

=item C<< $image->load ($filename) >>

Read the C<-file>, or set C<-file> to C<$filename> and then read.

The file format is detected by attempting each of the globally added image
format handlers.

Currently the possible formats are a hard-coded list, but the intention
would be to use C<Wx::Image::GetHandlers> if/when available.  The repeated
load attempts probably means a seekable file is required, so some special
devices are no good.  Perhaps could be improved by automatically copying to
a tempfile if necessary.

=item C<< $image->save () >>

=item C<< $image->save ($filename) >>

Write to the C<-file>, or set C<-file> to C<$filename> and then write.
C<-file_format> is the saved format.

An existing handler for the C<-file_format> from C<FindHandler> is used if
registered.  Otherwise a handler is created for the purpose with
C<Wx::PNGHandler> etc (but not added to the globals with C<AddHandler>).

If C<-file_format> is not set then the current code doesn't look at the
C<$filename> extension such as ".png" etc the way the underlying
C<$wximage-E<gt>SaveFile()> does.  Perhaps it could do so in the future.

=back

=head1 ATTRIBUTES

=over

=item C<-wximage> (C<Wx::Image> object)

The target C<Wx::Image>.

=item C<-file_format> (string, default undef)

The file format from the last C<load()> and the format to use in C<save()>.
This is one of the C<wxBITMAP_TYPE_XXX> names such as "PNG" or "JPEG".

=item C<-width> (integer)

=item C<-height> (integer)

The size of the image.  These are per C<$wximage-E<gt>GetWidth()> and
C<$wximage-E<gt>GetHeight()>.

Setting these resizes the image with C<$wximage-E<gt>Resize()>, filling any
expanded area with black.

=item C<-quality_percent> (0 to 100 or C<undef>)

The image quality when saving to JPEG format.  JPEG compresses by reducing
colours and resolution in ways that are not too noticeable to the human eye.
100 means full quality, no such reductions.  C<undef> means the Wx default.

This is the C<quality> for C<$wximage-E<gt>GetOption()> and
C<$wximage-E<gt>SetOption()>.

=item C<-hotx> (integer or undef, default undef)

=item C<-hoty> (integer or undef, default undef)

The cursor hotspot in CUR images.

These are C<wxIMAGE_OPTION_CUR_HOTSPOT_X> and
C<wxIMAGE_OPTION_CUR_HOTSPOT_Y> to C<$wximage-E<gt>GetOption()> and
C<$wximage-E<gt>SetOption()>.

(XPM format has an optional hotspot too, but Wx circa 2.8.12 doesn't seem to
read it.)

=back

=head1 SEE ALSO

L<Wx>,
L<Image::Base>,
L<Image::Base::Wx::DC>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-wx/index.html

=head1 LICENSE

Copyright 2012 Kevin Ryde

Image-Base-Wx is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Wx is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

=cut

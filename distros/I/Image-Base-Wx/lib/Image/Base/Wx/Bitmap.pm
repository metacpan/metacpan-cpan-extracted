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


package Image::Base::Wx::Bitmap;
use 5.008;
use strict;
use Carp;
use Wx;
our $VERSION = 4;

use Image::Base::Wx::DC;
our @ISA = ('Image::Base::Wx::DC');

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class_or_self, %params) = @_;
  ### Image-Base-Wx-Bitmap new: @_

  my $filename = delete $params{'-file'};
  my $wxbitmap = delete $params{'-wxbitmap'};
  my $dc = delete $params{'-dc'};

  my $class;
  if (ref $class_or_self) {
    # $obj->new(...) means make a copy, with some extra settings
    $class = ref $class_or_self;
    %params = (%$class_or_self, %params);
  } else {
    $class = $class_or_self;
  }

  if (ref $class_or_self) {
    # clone wxbitmap if a new one not given in the %params
    if (! defined $wxbitmap) {
      ### copy ...
      # maybe no copy-on-write constructor in 0.9909 ?
      $wxbitmap = $class_or_self->{'-wxbitmap'};
      ### $wxbitmap
      $wxbitmap = $wxbitmap->GetSubBitmap
        (Wx::Rect->new(0,0, $wxbitmap->GetWidth, $wxbitmap->GetHeight));
      ### copy: $wxbitmap
    }
  } else {
    if (! $wxbitmap) {
      ### new bitmap ...
      my $depth = $params{'-depth'};
      if (! defined $depth) { $depth = -1; }
      $wxbitmap = Wx::Bitmap->new
        (delete $params{'-width'}||1,
         delete $params{'-height'}||1,
         $depth);
    }
  }
  if (! defined $dc) {
    $dc = Wx::MemoryDC->new;
    $dc->SelectObject($wxbitmap);
    $dc->IsOk or croak "Oops, MemoryDC not IsOk()";
    ### new dc: $dc
  }
  my $self = $class->SUPER::new(%params,
                                -wxbitmap => $wxbitmap,
                                -dc => $dc);
  if (defined $filename) {
    $self->load($filename);
  }
  ### $self
  return $self;
}

my %attr_to_get_method
  = (-width  => 'GetWidth',
     -height => 'GetHeight',
     -depth  => 'GetDepth');
my %attr_to_option
  = (
     # -hotx   => Wx::wxbitmap_OPTION_CUR_HOTSPOT_X(),
     # -hoty   => Wx::wxbitmap_OPTION_CUR_HOTSPOT_Y(),
     # -quality_percent => 'quality',
    );
sub _get {
  my ($self, $key) = @_;

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-wxbitmap'}->$method();
  }
  if (my $option = $attr_to_option{$key}) {
    return $self->{'-wxbitmap'}->GetOptionInt($option);
  }
  return $self->SUPER::_get($key);
}

# my %attr_to_set_method
#   = (-width  => 'SetWidth',
#      -height => 'SetHeight',
#      -depth  => 'SetDepth');
sub set {
  my ($self, %params) = @_;
  ### Image-Base-Wx-Bitmap set: \%params

  # -wxbitmap before applying -width,-height
  if (my $wxbitmap = delete $params{'-wxbitmap'}) {
    $self->{'-wxbitmap'} = $wxbitmap;
  }
  if (exists $params{'-width'} || exists $params{'-height'}) {
    croak "-width or -height are read-only";
    # my $wxbitmap = $self->{'-wxbitmap'};
    # my $width = (exists $params{'-width'}
    #              ? delete $params{'-width'}
    #              : $wxbitmap->GetWidth);
    # my $height = (exists $params{'-height'}
    #               ? delete $params{'-height'}
    #               : $wxbitmap->GetHeight);
    # $wxbitmap->Resize(Wx::Size->new($width,$height),
    #                  0,0,0); # fill with black
  }
  foreach my $key (keys %params) {
    if (my $option = $attr_to_option{$key}) {
      return $self->{'-wxbitmap'}->GetOptionInt($option);
    }
  }
  $self->SUPER::set(%params);
  ### set leaves: $self
}

#------------------------------------------------------------------------------
# load/save

# Note: must try CUR before ICO to pick up HotSpotX and HotSpotY
my @file_formats = (qw(BMP
                       GIF
                       JPEG
                       PCX
                       PNG
                       PNM
                       TIF
                       CUR
                       ICO
                       ANI
                       XPM
                     ));
my @bitmap_types = map { my $constant = "wxBITMAP_TYPE_$_";
                        my $type = eval "Wx::$constant()";
                        if (! defined $type) {
                          die "Oops, no $constant: $@";
                        }
                        $type } @file_formats;
my %file_formats = (map {$file_formats[$_] => $bitmap_types[$_]}
                    0 .. $#file_formats);
$file_formats{'JPG'} = $file_formats{'JPEG'};
### @bitmap_types

sub load {
  my ($self, $filename) = @_;
  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  ### load: $filename

  # stringize in case perhaps future LoadFile() overloads to a handle too
  $filename = "$filename";

  my $wxbitmap = $self->{'-wxbitmap'};
  foreach my $i (0 .. $#file_formats) {
    my $file_format = $file_formats[$i];
    my $type = $bitmap_types[$i];
    ### $file_format
    ### $type

    # my $handler = Wx::Bitmap::FindHandlerType($type) || next;
    # ### $handler
    # if ($handler->LoadFile ($wxbitmap, $fh)) {
    #   ### loaded ...
    #   ### wxbitmap isok: $wxbitmap->IsOk
    #   $self->{'-file_format'} = $file_format;
    #   return;
    # }

    if ($wxbitmap->LoadFile ($filename, $type)) {
      ### loaded ...
      ### wxbitmap isok: $wxbitmap->IsOk
      $self->{'-file_format'} = $file_format;
      return;
    }
  }

  croak "Cannot load ",$filename;
}

# Would have to copy to a tempfile.
# sub load_fh {
#   my ($self, $fh, $filename) = @_;
#   ### load_fh()
# 
#   $self->{'-wxbitmap'}->LoadFile($fh,Wx::wxBITMAP_TYPE_ANY())
#     or croak "Cannot read file",
#       (defined $filename ? (' ',$filename) : ());
# }

sub save {
  my ($self, $filename) = @_;
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  my $file_format = $self->get('-file_format')
    || croak "-file_format not set";
  my $type = $file_formats{uc($file_format)};
  if (! defined $type) {
    croak "Unrecognised file format ",$self->get('-file_format');
  }
  ### $file_format
  ### $type

  if ($self->{'-wxbitmap'}->SaveFile($filename,$type)) {
    return;
  }
  croak "Cannot save ",$filename;
}

# Would have to SaveFile() to a file and then copy to $fh.
# sub save_fh {
#   my ($self, $fh, $filename) = @_;
# 
#   my $file_format = $self->get('-file_format');
#   # if (! defined $file_format) {
#   #   $file_format = _filename_to_format($filename);
#   #   if (! defined $file_format) {
#   #     croak 'No -file_format set';
#   #   }
#   # }
# 
#   $self->{'-wxbitmap'}->SaveFile($fh, "image/$file_format")
#     or croak "Cannot save file",
#       (defined $filename ? (' ',$filename) : ());
# }

#------------------------------------------------------------------------------

1;
__END__

=for stopwords resized filename Ryde bitmap

=head1 NAME

Image::Base::Wx::Bitmap -- draw into a Wx::Bitmap

=for test_synopsis my $wxbitmap

=head1 SYNOPSIS

 use Image::Base::Wx::Bitmap;
 my $image = Image::Base::Wx::Bitmap->new
                 (-wxbitmap => $wxbitmap);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Wx::Bitmap> is a subclass of C<Image::Base::Wx::DC>,

    Image::Base
      Image::Base::Wx::DC
        Image::Base::Wx::Bitmap

=head1 DESCRIPTION

C<Image::Base::Wx::Bitmap> extends C<Image::Base> to draw into a
C<Wx::Bitmap>.

C<Wx::Bitmap> is a platform-dependent colour image with a specified
bits-per-pixel depth.  The supported depths depend on the platform but
include at least the screen depth and 1-bit monochrome.

Drawing is done with a wxMemoryDC as per the C<Image::Base::Wx::DC>.  This
subclass adds file load and save for the C<Wx::Bitmap>.

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

C<load()> detects the format, but a handler for the format must have been
registered globally.  All formats can be registered with

    Wx::InitAllImageHandlers();

This is suggested since otherwise load XPM seems to behave as an "ANY" which
might trick the detection attempts.  The C<Wx::Image> handlers are used by
C<Wx::Bitmap> so registering desired formats there might be enough.

=head2 Colour Names

Colour names are anything recognised by C<< Wx::Colour->new() >>, as
described in L<Image::Base::Wx::DC/Colour Names>.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for behaviour common to all Image-Base classes.

=over 4

=item C<$image = Image::Base::Wx::Bitmap-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  It can read a file,

    $image = Image::Base::Wx::Bitmap->new
               (-file => '/my/file/name.bmp');

Or create a new bitmap with width and height.  The default C<-depth> is the
bits-per-pixel of the screen, or something else can be given.

    $image = Image::Base::Wx::Bitmap->new
                 (-width  => 200,
                  -height => 100,
                  -depth => 1);   # monochrome

Or a new image can be pointed at an existing C<Wx::Bitmap>,

    my $wxbitmap = Wx::Bitmap->new (200, 100);
    my $image = Image::Base::Wx::Bitmap->new
                 (-wxbitmap => $wxbitmap);

Further parameters are applied per C<set> (see L</ATTRIBUTES> below).

=back

=head1 ATTRIBUTES

=over

=item C<-wxbitmap> (C<Wx::Bitmap> object)

The target bitmap object.

=item C<-dc> (C<Wx::MemoryDC> object)

The C<Wx::DC> used to draw into the bitmap.  A suitable DC is created for
the bitmap automatically, but it can be set explicitly if desired.

=item C<-file_format> (string, default undef)

The file format from the last C<load()> and the format to use in C<save()>.
This is one of the C<wxBITMAP_TYPE_XXX> names such as "PNG" or "JPEG".

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of the bitmap, per C<$wxbitmap-E<gt>GetWidth()> and
C<$wxbitmap-E<gt>GetHeight()>.  Currently these are read-only.  Can a bitmap
be resized dynamically?

=item C<-depth> (integer, read-only)

The number of bits per pixel in the bitmap, per
C<$wxbitmap-E<gt>GetDepth()>.  Currently this is read-only.  Can a bitmap be
reformatted dynamically?

=back

=head1 BUGS

Wx circa 2.8.12 on Gtk prints C<g_log()> warnings on attempting to load an
unknown file format, including an empty file or garbage.  This is apparently
from attempting it as an XPM.  Is that a Wx bug?

=head1 SEE ALSO

L<Wx>,
L<Image::Base>,
L<Image::Base::Wx::DC>,
L<Image::Base::Wx::Image>

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

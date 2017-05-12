# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Magick.
#
# Image-Base-Magick is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Magick is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Magick.  If not, see <http://www.gnu.org/licenses/>.


# file:///usr/share/doc/imagemagick-doc/www/perl-magick.html
# file:///usr/share/doc/imagemagick-doc/www/formats.html

require 5;
package Image::Base::Magick;
use strict;
use Carp;
use Fcntl;
use Image::Magick;
use vars '$VERSION', '@ISA';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 4;

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub new {
  my ($class, %params) = @_;
  ### Image-Base-Magick new(): %params
  my $err;

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    if (! defined $params{'-imagemagick'}) {
      $params{'-imagemagick'} = $self->get('-imagemagick')->Clone;
    }
    # inherit everything else
    %params = (%$self, %params);
    ### copy params: \%params
  }

  if (! defined $params{'-imagemagick'}) {
    # Crib: passing attributes to new() is the same as a subsequent set()
    # except you don't get an error return from new()
    my $m = $params{'-imagemagick'} = Image::Magick->new;

    # must apply -width, -height as "size" before ReadImage()
    if (exists $params{'-width'} || exists $params{'-height'}) {
      my $width = delete $params{'-width'} || 0;
      my $height = delete $params{'-height'} || 0;
      ### Set(size) -width,-height: "${width}x${height}"
      if ($err = $m->Set (size => "${width}x${height}")) {
        croak $err;
      }
    }
    ### ReadImage xc-black
    if ($err = $m->ReadImage('xc:black')) {
      croak $err;
    }
  }
  my $self = bless {}, $class;
  $self->set (%params);

  if (defined $params{'-file'}) {
    $self->load;
  }

  ### new made: $self
  return $self;
}

# "size" is the size of the canvas
# "width" and "height" are the size of a ReadImage() file, or something
# file:///usr/share/doc/imagemagick/www/perl-magick.html#get-attribute
#
sub _magic_get_width {
  my ($m, $idx) = @_;
  my $size;
  if (defined ($size = $m->Get('size'))) {
    # ### $size
    # ### split: [ split /x/, $size ]
    # ### return: (split /x/, $size)[$idx||0]
    return (split /x/, $size)[$idx||0];
  } else {
    return 0;
  }
}
sub _magic_get_height {
  my ($m) = @_;
  _magic_get_width ($m, 1);
}
my %attr_to_get_func = (-width  => \&_magic_get_width,
                        -height => \&_magic_get_height,
                       );
my %attr_to_GetSet = (-file        => 'filename',
                      # these not documented yet ...
                      -ncolours    => 'colors',
                      -file_format => 'magick',
                     );
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-Magick _get(): $key

  my $m = $self->{'-imagemagick'};
  {
    my $func;
    if ($func = $attr_to_get_func{$key}) {
      return &$func($m);
    }
  }
  {
    my $attribute;
    if ($attribute = $attr_to_GetSet{$key}) {
      ### Get: $attribute
      ### is: $m->Get($attribute)
      return  $m->Get($attribute);
    }
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-Base-Magick set(): \%params

  {
    my $key;
    foreach $key ('-ncolours') {
      if (exists $params{$key}) {
        croak "Attribute $key is read-only";
      }
    }
  }

  # apply this first
  {
    my $m;
    if ($m = delete $params{'-imagemagick'}) {
      $self->{'-imagemagick'} = $m;
    }
  }

  my $m = $self->{'-imagemagick'};
  my @set;

  if (exists $params{'-width'} || exists $params{'-height'}) {
    # FIXME: might prefer a crop on shrink, and some sort of extend-only on
    # grow

    my @resize;
    my $width = delete $params{'-width'};
    if (defined $width && $width != _magic_get_width($m)) {
      push @resize, width => $width;
    }
    my $height = delete $params{'-height'};
    if (defined $height && $height != _magic_get_height($m)) {
      push @resize, height => $height;
    }
    # my $width = delete $params{'-width'};
    # my $height = delete $params{'-height'};
    if (! defined $width)  { $width = _magic_get_width($m); }
    if (! defined $height) { $height = _magic_get_height($m); }
    # $m->Resize (width => $width, height => $height);

    if (@resize) {
      ### Resize
      $m->Resize (@resize);
    }
    ### Set(size): "${width}x${height}"
    push @set, size => "${width}x${height}";
  }

  {
    my $key;
    foreach $key (keys %params) {
      my $attribute;
      if ($attribute = $attr_to_GetSet{$key}) {
        push @set, $attribute, delete $params{$key};
      }
    }
  }
  if (@set) {
    ### Set(): @set
    my $err;
    if ($err = $m->Set(@set)) {
      croak $err;
    }
  }

  ### store params: %params
  %$self = (%$self, %params);
}

sub load {
  my ($self, $filename) = @_;
  ### Image-Base-Magick load()
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### load filename: $filename
  ### into m: $self->{'-imagemagick'}


  # This nonsense seems to be necessary to read from a filehandle to avoid
  # "%d" interpretation on a named file.
  #
  # Must temporary $m->Set(filename=>'') or else Read() seems to prefer the
  # filename attribute over the Read(file=>), or something.
  #
  # sysopen() is used to avoid perl two-arg open() whitespace stripping etc.
  #
  # @$m=() clear out existing image, as the Read() adds to the canvas.
  #

  sysopen FH, $filename, Fcntl::O_RDONLY()
    or croak "Cannot open $filename: $!";
  binmode FH
    or croak "Cannot set binmode for $filename: $!";

  my $m = $self->{'-imagemagick'};
  my $err;
  if ($err = $m->Set(filename => '')) {
    close FH;
    croak 'Oops, cannot temporarily unset filename attribute: ',$err;
  }

  my @old_ims = @$m;
  @$m = ();

  ### empty before load: $m
  ### file size: -s \*FH
  ### width: $m->Get('width')
  ### height: $m->Get('height')
  ### size: $m->Get('size')
  ### filename: $m->Get('filename')

  my $readerr = $m->Read (file => \*FH);

  ### load leaves magick: $m
  ### array: [@$m]
  ### width: $m->Get('width')
  ### height: $m->Get('height')
  ### size: $m->Get('size')

  if ($err = $m->Set(filename => $filename)) {
    close FH;
    @$m = @old_ims;
    croak 'Oops, cannot restore filename attribute: ',$err;
  }

  if (! close FH) {
    @$m = @old_ims;
    return "Error closing $filename: $!";
  }

  if ($readerr) {
    @$m = @old_ims;
    croak $readerr;
  }

  if (! scalar(@$m)) {
    @$m = @old_ims;
    croak 'ImageMagick Read didn\'t read an image';
  }

  # canvas size as size of image loaded
  my ($width, $height);
  if (! defined ($width = $m->Get('width'))
      || ! defined ($height = $m->Get('height'))) {
    @$m = @old_ims;
    croak 'ImageMagick Read didn\'t give width,height';
  }
  my $size = "${width}x${height}";
  if ($err = $m->Set (size => $size)) {
    @$m = @old_ims;
    croak "Cannot set size $size: $err";
  }
}


# my $m = $self->{'-imagemagick'};
# my @old_ims = @$m;
# @$m = ();
# if (my $err = $m->Read ($filename)) {
#   @$m = @old_ims;
#   croak $err;
# }


# not documented ... probably doesn't work
sub load_fh {
  my ($self, $fh) = @_;
  ### Image-Base-Magick load_fh()
  my $err;
  if ($err = $self->{'-imagemagick'}->Read (file => $fh)) {
    croak $err;
  }
}

# not yet documented ... and untested
sub load_string {
  my ($self, $str) = @_;
  my $err;
  if ($err = $self->{'-imagemagick'}->Read (blob => $str)) {
    croak $err;
  }
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Magick save(): @_
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename
  ### _save_options: _save_options($self)


  # Not using Write(filename=>) because it expands "%d" to a sequence
  # number, per file:///usr/share/doc/imagemagick/www/perl-magick.html#read
  #
  # Use sysopen() so as not to interpret whitespace etc on $filename.
  #
  sysopen (FH, $filename,
           Fcntl::O_WRONLY() | Fcntl::O_TRUNC() | Fcntl::O_CREAT())
    or croak "Cannot create $filename: $!";
  binmode FH
    or croak "Cannot set binmode on $filename: $!";
  {
    my $err;
    if ($err = $self->{'-imagemagick'}->Write (file => \*FH,
                                               _save_options($self))) {
      close FH;
      croak $err;
    }
  }
  close FH
    or croak "Error closing $filename: $!";

  $self->set('-file', $filename);
}

# if (my $err = $self->{'-imagemagick'}->Write (filename => $filename,
#                                               _save_options($self))) {
#   croak $err;
# }


# not yet documented ... might not work
sub save_fh {
  my ($self, $fh) = @_;
  my $err;
  if ($err = $self->{'-imagemagick'}->Write (file => $fh,
                                                _save_options($self))) {
    croak $err;
  }
}

sub _save_options {
  my ($self) = @_;

  # For PNG "quality" option is zlib_compression*10.  Or for undef or -1
  # compressionomit the quality parameter.  Docs
  # file:///usr/share/doc/imagemagick/www/command-line-options.html#quality
  # Code coders/png.c WriteOnePNGImage() doing png_set_compression_level()
  # of quality/10 with maximum 9
  #
  my $m = $self->{'-imagemagick'};
  my $format = $m->Get('magick');
  if ($format eq 'png') {
    my $zlib_compression = $self->{'-zlib_compression'};
    if (defined $zlib_compression && $zlib_compression >= 0) {
      return (quality => $zlib_compression * 10);
    }
  }
  # For JPEG and MIFF "quality" option is a percentage 0 to 100
  # file:///usr/share/doc/imagemagick-doc/www/perl-magick.html#set-attribute
  my $quality = $self->{'-quality_percent'};
  if (defined $quality) {
    return (quality => $quality);
  }
  return;
}

# Circa ImageMagick 6.7.7.10 "pixel[]" such as
#
#     $err = $m->set ("pixel[$x,$y]", $colour);
#
# when setting a negative X,Y or big positive X,Y somehow gets $err
#
#     Exception 445: pixels are not authentic `black' @ error/cache.c/QueueAuthenticPixelCacheNexus/4387 at t/MyTestImageBase.pm line 326
# 
# Using primitive=>'point' avoids that.

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-Magick xy(): $x,$y,$colour
  my $m = $self->{'-imagemagick'};
  my $err;
  if (@_ == 4) {
    $err = $m->Draw (primitive => 'point',
                     fill   => $colour,
                     points => "$x,$y");

    # Or maybe SetPixel(), but it takes color=>[$r,$g,$b] arrayref, not string
    # $err = $m->SetPixel (x=>$x, y=>$y, color=>$colour);

  } else {
    # cf $m->get("pixel[123,456]") gives a string "$r,$g,$g,$a"

    # GetPixel() gives list ($r,$g,$b) each in range 0 to 1
    my @rgb = $m->GetPixel (x => $x, y => $y);
    ### @rgb
    if (@rgb == 1) {
      $err = $rgb[0];
    } else {
      return sprintf '#%02X%02X%02X', map {$_*255} @rgb;
    }
  }
  if ($err) {
    croak $err;
  }
}
sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-Magick line: @_
  my $err;
  if ($err = $self->{'-imagemagick'}->Draw (primitive => 'line',
                                            fill => $colour,
                                            points => "$x1,$y1 $x2,$y2")) {
    croak $err;
  }
}
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Magick rectangle: @_
  # ### index: $self->colour_to_index($colour)

  my $m = $self->{'-imagemagick'};
  my $err;
  if ($x1==$x2 && $y1==$y2) {
    # primitive=>rectangle of 1x1 seems to draw nothing

    ### use set pixel[]
    $err = $m->set ("pixel[$x1,$y1]", $colour);

    # $err = $m->Draw (primitive => 'point',
    #                  fill => $colour,
    #                  points => "$x1,$y1");

  } else {
    $err = $m->Draw (primitive => 'rectangle',
                     ($fill ? 'fill' : 'stroke'), $colour,
                     points => "$x1,$y1 $x2,$y2");
  }
  if ($err) {
    croak $err;
  }
}

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Magick ellipse: "$x1, $y1, $x2, $y2, $colour"

  my $m = $self->{'-imagemagick'};
  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  my $err;
  if ($w || $h) {
    ### more than 1 pixel wide and/or high, primitive=>ellipse
    ### ellipse: (($x1+$x2)/2).','.(($y1+$y2)/2).' '.($w/2).','.($h/2).' 0,360'
    $err = $m->Draw (primitive => 'ellipse',
                     strokewidth => .25,
                     ($fill ? 'fill' : 'stroke') => $colour,
                     points => ((($x1+$x2)/2).','.(($y1+$y2)/2)
                                .' '
                                .($w/2).','.($h/2)
                                .' 0,360'));
  } else {
    ### only 1 pixel wide and/or high, primitive=>line
    $err = $m->Draw (primitive => 'line',
                     fill => $colour,
                     points => "$x1,$y1 $x2,$y2");
  }
  if ($err) {
    croak $err;
  }
}

sub diamond {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Magick diamond() ...

  my $xh = ($x2 - $x1);
  my $yh = ($y2 - $y1);
  my $xeven = ($xh & 1);
  my $yeven = ($yh & 1);
  $xh = int($xh / 2);
  $yh = int($yh / 2);
  ### x centre: $x1+$xh, $x2-$xh
  ### assert: $x1+$xh+$xeven == $x2-$xh
  ### assert: $y1+$yh+$yeven == $y2-$yh

  my $m = $self->{'-imagemagick'};
  my $err;
  if ($x1 == $x2 && $y1 == $y2) {
    # 1x1 polygon doesn't seem to draw any pixels in imagemagick 6.6, do it
    # as a single point instead
    $err = $m->set ("pixel[$x1,$y1]", $colour);

  } else {
    $err = $m->Draw (primitive => 'polygon',
                     ($fill ? 'fill' : 'stroke') => $colour,
                     strokewidth => 0,
                     points => (($x1+$xh).' '.$y1  # top centre

                                # left
                                .' '.$x1.' '.($y1+$yh)

                                .($yeven ? ' '.$x1.' '.($y2-$yh)  : '')

                                # bottom
                                .' '.($x1+$xh).' '.$y2
                                .($xeven ? ' '.($x2-$xh).' '.$y2   : '')

                                # right
                                .($yeven ? ' '.$x2.' '.($y2-$yh)  : '')
                                .' '.$x2.' '.($y1+$yh)

                                .($xeven ? ' '.($x2-$xh).' '.$y1  : '')
                               ));
  }
  if ($err) {
    croak $err;
  }
}

# sub add_colours {
#   my $self = shift;
#   ### add_colours: @_
# 
#   my $m = $self->{'-imagemagick'};
# }

1;
__END__

=for stopwords PNG Magick filename filenames undef Ryde Zlib Zlib's ImageMagick ImageMagick's RGB

=head1 NAME

Image::Base::Magick -- draw images using Image Magick

=head1 SYNOPSIS

 use Image::Base::Magick;
 my $image = Image::Base::Magick->new (-width => 100,
                                                       -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,50, 70,70, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::Magick> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Magick

=head1 DESCRIPTION

C<Image::Base::Magick> extends C<Image::Base> to create or
update image files using C<Image::Magick>.

The native ImageMagick drawing has hugely more features, but this module is
a way to point C<Image::Base> style code at an ImageMagick canvas and use
the numerous file formats ImageMagick can read and write.

=head2 Colour Names

Colour names are anything recognised by ImageMagick,

    http://imagemagick.org/www/color.html
    file:///usr/share/doc/imagemagick/www/color.html

    #RGB    1, 2, 4-digit hex
    #RRGGBB
    #RRRRGGGGBBBB
    names roughly per X11
    colors.xml file

F<colors.xml> is in F</etc/ImageMagick/>, or in the past in
F</usr/share/ImageMagick-6.6.0/config/> with whatever version number.

=head2 Anti-Aliasing

By default ImageMagick uses "anti-aliasing" to blur the edges of lines and
circles drawn.  This is unlike the other C<Image::Base> modules but
currently it's not changed or overridden in the methods here.  Perhaps that
will change, or perhaps only for canvases created by C<new()> (as opposed to
supplied in a C<-imagemagick> parameter).  You can turn it off explicitly
with

    my $m = $image->get('-imagemagick');
    $m->Set (antialias => 0);

=head2 Graphics Magick

The C<Graphics::Magick> module using the graphicsmagick copy of imagemagick
should work, to the extent it's compatible with imagemagick.  There's
nothing to choose C<Graphics::Magick> as such currently, but a
C<Graphics::Magick> object can be created and passed in as the
C<-imagemagick> target,

    my $m = Graphics::Magick->new (size => '200x100')
    $m->ReadImage('xc:black');
    my $image = Image::Base::Magick-new (-imagemagick => $m);

As of graphicsmagick 1.3.12 there's something bad in its Perl XS interface
causing segvs attempting to write to a file handle, which is what
C<$image-E<gt>save()> does.  An C<$m-E<gt>Write()> to a file works.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::Magick-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with
C<-width> and C<-height>,

    my $image = Image::Base::Magick->new (-width => 200,
                                          -height => 100);

Or an existing file can be read,

    my $image = Image::Base::Magick->new
                   (-file => '/some/filename.png');

Or an C<Image::Magick> object can be given,

    $image = Image::Base::Magick->new (-imagemagick => $mobj);

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Setting these changes the size of the image.

In the current code a C<Resize()> is done which means the existing image is
stretched, but don't depend on that.  It might make more sense to crop when
shrinking and pad with black when extending.

=item C<-imagemagick>

The underlying C<Image::Magick> object.

=item C<-file> (string, default C<undef>)

The filename for C<load> or C<save>, or passed to C<new> to load a file.

The filename is used literally, it doesn't have ImageMagick's "%d" scheme
for sets of numbered files.  The code here is only geared towards a single
image in a canvas, and using the filename literally is the same as other
C<Image::Base> modules.

=item C<-file_format> (string or C<undef>)

The file format as a string like "PNG" or "JPEG", or C<undef> if unknown or
never set.

C<load()> sets C<-file_format> to the format read.  Setting C<-file_format>
can change the format for a subsequent C<save()>, or set the format for a
newly created image.

This sets the C<magick> attribute of the ImageMagick object.  The available
formats are per

    http://imagemagick.org/www/formats.html
    file:///usr/share/doc/imagemagick/www/formats.html

Some of the choices are pseudo-formats, for example saving as "X" displays a
preview window in X windows, or "PRINT" writes to the printer.

=item C<-quality_percent> (0 to 100 or C<undef>)

The image quality when saving to JPEG and similar lossy formats which
compress by reducing colours and resolution in ways not too noticeable to
the human eye.  100 means full quality, no such reductions.  C<undef> means
the imagemagick C<DefaultImageQuality>, which is 75.

This attribute becomes the C<quality> parameter to
C<$imagemagick-E<gt>Write()>.

=item C<-zlib_compression> (integer 0-9 or -1, default C<undef>)

The amount of data compression to apply when saving.  The value is Zlib
style 0 for no compression up to 9 for maximum effort.  -1 means Zlib's
default, usually 6.  C<undef> or never set means ImageMagick's default,
which is 7.

This attribute becomes the C<quality> parameter to
C<$imagemagick-E<gt>Write()> when saving PNG.

=back

For reference, ImageMagick (as of version 6.7.7) doesn't read or write the
cursor "hotspot" of XPM format, so there's no C<-hotx> and C<-hoty> options.

=head1 SEE ALSO

L<Image::Base>,
L<Image::Magick>

L<Image::Base::GD>,
L<Image::Base::PNGwriter>,
L<Image::Base::Imager>,
L<Image::Base::Gtk2::Gdk::Pixbuf>,
L<Image::Base::Prima::Image>,
L<Image::Xbm>,
L<Image::Xpm>,
L<Image::Pbm>

L<Prima::Image::Magick>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-magick/index.html

=head1 LICENSE

Image-Base-Magick is Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-Magick is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Magick is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Magick.  If not, see <http://www.gnu.org/licenses/>.

=cut

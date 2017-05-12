# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::Gtk2::Gdk::Image;
use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = 11;
use base 'Image::Base';

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my ($class, %params) = @_;
  ### Image-GdkImage new: \%params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    croak "Cannot clone a GdkImage yet";
  }

  if (! exists $params{'-gdkimage'}) {
    ### create new GdkImage

    my $image_type = delete $params{'-image_type'} || 'fastest';
    my $visual = delete $params{'-visual'}
      || ($params{'-colormap'} && $params{'-colormap'}->get_visual)
        || Gtk2::Gdk::Visual->get_system;
    ### $image_type
    ### $visual

    $params{'-gdkimage'} = Gtk2::Gdk::Image->new ($image_type,
                                                  $visual,
                                                  delete $params{'-width'},
                                                  delete $params{'-height'});
  }

  my $self = bless {}, $class;
  $self->set (%params);
  ### $self
  return $self;
}

my %attr_to_get_method = (-colormap   => 'get_colormap',
                          -visual     => 'get_visual',
                          -width      => 'get_width',
                          -height     => 'get_height',
                          -depth      => 'get_depth',

                          # not documented yet, maybe a more specific name ...
                          -image_type => 'get_image_type',
                         );
sub _get {
  my ($self, $key) = @_;

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-gdkimage'}->$method;
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-GdkImage set(): \%params

  %$self = (%$self, %params);

  if (defined (my $colormap = delete $self->{'-colormap'})) {
    $self->{'-gdkimage'}->set_colormap ($colormap);
  }
  ### set leaves: $self
}

#------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;

  my $gdkimage = $self->{'-gdkimage'};
  unless ($x >= 0
          && $y >= 0
          && $x < $gdkimage->get_width
          && $y < $gdkimage->get_height) {
    ### outside 0,0,width,height ...
    return undef;  # fetch or store
  }

  if (@_ >= 4) {
    ### Image-GdkImage xy: "$x, $y, $colour"
    $gdkimage->put_pixel ($x,$y, $self->colour_to_pixel($colour));
  } else {
    return $self->pixel_to_colour($gdkimage->get_pixel ($x,$y))
  }
}

sub colour_to_pixel {
  my ($self, $colour) = @_;
  ### colour_to_pixel: $colour
  if (defined (my $pixel = $self->{'-colour_to_pixel'})) {
    return $pixel;
  }
  if ($colour =~ /^\d+$/) {
    return $colour;
  }
  if ($colour eq 'set') {
    return 1;
  }
  if ($colour eq 'clear') {
    return 0;
  }

  my $gdkimage = $self->{'-gdkimage'};
  if (my $colormap = $gdkimage->get_colormap) {
    # think parse and rgb_find are client-side operations, no need to cache
    # the results
    #
    my $colorobj = Gtk2::Gdk::Color->parse ($colour)
      || croak "Cannot parse colour: $colour";
    $colormap->rgb_find_color ($colorobj);
    ### rgb_find_color: $colorobj->to_string
    ### pixel: $colorobj->pixel
    return $colorobj->pixel;
  }
  if ($gdkimage->get_depth == 1) {
    if ($colour =~ /^#(000)+$/) {
      return 0;
    } elsif ($colour  =~ /^#(FFF)+$/i) {
      return 1;
    }
  }
  croak "No colormap to interpret colour: $colour";
}

sub pixel_to_colour {
  my ($self, $pixel) = @_;
  ### pixel_to_colour: $pixel
  if (my $colormap = $self->{'-gdkimage'}->get_colormap) {
    my $colorobj = $colormap->query_color($pixel);
    ### in colormap: $colorobj->to_string
    ### pixel: $colorobj->pixel
    return sprintf '#%04X%04X%04X',
      $colorobj->red, $colorobj->green, $colorobj->blue;
  } else {
    return $pixel;
  }
}

1;
__END__

=for stopwords undef Ryde Gdk Images GdkImage colormap ie toplevel Gtk Pango pixmap

=head1 NAME

Image::Base::Gtk2::Gdk::Image -- draw into a Gtk2::Gdk::Image

=head1 SYNOPSIS

 use Image::Base::Gtk2::Gdk::Image;
 my $image = Image::Base::Gtk2::Gdk::Image->new
                 (-width => 100,
                  -height => 100,
                  -colormap => Gtk2::Gdk::Colormap->get_system);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Gtk2::Gdk::Image> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Gtk2::Gdk::Image

=head1 DESCRIPTION

C<Image::Base::Gtk2::Gdk::Image> extends C<Image::Base> to create and draw
into GdkImage objects.  It requires Perl-Gtk2 1.240 for the full GdkImage
support there.  A GdkImage is pixel data in client-side memory.  There's no
file load or save, just drawing operations.

Colour names are raw integer pixel values, and special names "set" and
"clear" for pixel values 1 and 0 to use with bitmaps.  If the GdkImage has a
colormap then also anything recognised by C<< Gtk2::Gdk::Color->parse >>,
such as "pink" and hex #RRGGBB or #RRRRGGGGBBB.  As of Gtk 2.20 the colour
names are the Pango compiled-in copy of the X11 F<rgb.txt>.

A GdkImage is designed to copy pixel data between client memory and a window
(or pixmap) on the server.  Because it uses a C<Gtk2::Gdk::Visual> it's
restricted to the depths (bits per pixel) supported the server windows and
so isn't a general purpose pixel array.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::Gtk2::Gdk::Image-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  It can be pointed at an existing
C<Gtk2::Gdk::Image>,

    $image = Image::Base::Gtk2::Gdk::Image->new
                 (-gdkimage => $gdkimage);

Or a new C<Gtk2::Gdk::Image> created,

    $image = Image::Base::Gtk2::Gdk::Image->new
                 (-width  => 10,
                  -height => 10);

Creating a GdkImage requires a size and visual, and optionally a colormap.

    -width    =>  integer
    -height   =>  integer
    -visual   =>  Gtk2::Gdk::Visual object
    -colormap =>  Gtk2::Gdk::Colormap object or undef

C<-visual> defaults to the visual of the C<-colormap> if given, or to the
Gtk "system" visual otherwise.

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set the pixel at C<$x>,C<$y>.

Currently if the GdkImage has a colormap then colours are returned in
#RRRRGGGGBBBB form.  Without a colormap the return is the integer pixel
value integer.

=back

=head1 ATTRIBUTES

=over

=item C<-gdkimage> (C<Gtk2::Gdk::Image> object)

The target C<Gtk2::Gdk::Image> object.

=item C<-width> (integer, read and create only)

=item C<-height> (integer, read and create only)

The size of a GdkImage cannot be changed once created.

=item C<-visual> (C<Gtk2::Gdk::Visual>, read or create only)

=item C<-colormap> (C<Gtk2::Gdk::Colormap>, read/write)

=item C<-depth> (integer, read-only)

The GdkImage C<get_depth>, being the bits per pixel.

=back

=head1 SEE ALSO

L<Gtk2::Gdk::Image>,
L<Image::Base>,
L<Image::Base::Gtk2::Gdk::Drawable>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/image-base-gtk2/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Gtk2 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Gtk2.  If not, see L<http://www.gnu.org/licenses/>.

=cut

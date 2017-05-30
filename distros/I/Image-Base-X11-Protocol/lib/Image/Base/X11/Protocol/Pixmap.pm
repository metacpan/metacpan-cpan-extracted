# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

# This file is part of Image-Base-X11-Protocol.
#
# Image-Base-X11-Protocol is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-X11-Protocol is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-X11-Protocol.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::X11::Protocol::Pixmap;
use 5.004;
use strict;
use Carp;
use X11::Protocol::Other;
use vars '@ISA', '$VERSION';

use Image::Base::X11::Protocol::Drawable;
@ISA = ('Image::Base::X11::Protocol::Drawable');

$VERSION = 15;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  my ($class, %params) = @_;
  ### X11-Protocol-Pixmap new()

  if (my $pixmap = delete $params{'-pixmap'}) {
    $params{'-drawable'} = $params{'-pixmap'};
  }
  my $X = $params{'-X'};

  if (! defined $params{'-drawable'}) {
    my $screen = $params{'-screen'};
    my $for_window = delete $params{'-for_window'};
    my $for_drawable = delete $params{'-for_drawable'}
      || $for_window
        || (defined $screen && $X->{'screens'}->[$screen]->{'root'})
          || $X->{'root'};

    my $depth = $params{'-depth'};
    if (! defined $depth) {
      if (my $screen_info = X11::Protocol::Other::root_to_screen_info($X, $for_drawable)) {
        $depth = $screen_info->{'root_depth'};
      } else {
        my %geom = $X->GetGeometry($for_drawable);
        $depth = $geom{'depth'};
        if (! defined $params{'-root'}) {
          $params{'-root'} = $geom{'root'};
        }
      }
    }
    ### $depth

    if ($for_window && ! defined $params{'-colormap'}) {
      ### default colormap from window
      my %attrs = $X->GetWindowAttributes ($for_window);
      my $visual = $attrs{'visual'};
      if ($depth == $X->{'visuals'}->{$visual}->{'depth'}) {
        $params{'-colormap'} = $attrs{'colormap'};
      }
    }

    my $pixmap = $params{'-drawable'} = $X->new_rsrc;
    ### X11-Protocol-Pixmap CreatePixmap
    ### ID: $pixmap
    ### $for_window
    ### depth: $depth
    ### width: $params{'-width'}
    ### height: $params{'-height'}
    $X->CreatePixmap ($pixmap,
                      $for_drawable,
                      ($params{'-depth'} = $depth),
                      $params{'-width'},
                      $params{'-height'});
  }
  return $class->SUPER::new (%params);
}

sub _get {
  my ($self, $key) = @_;
  if ($key eq '-pixmap') {
    $key = '-drawable';
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  if (exists $params{'-pixmap'}) {
    $params{'-drawable'} = delete $params{'-pixmap'};
  }
  $self->SUPER::set(%params);
}

1;
__END__

=for stopwords undef Ryde pixmap pixmaps XID colormap ie drawable superclasses

=head1 NAME

Image::Base::X11::Protocol::Pixmap -- draw into an X11::Protocol pixmap

=for test_synopsis my ($win)

=head1 SYNOPSIS

 use Image::Base::X11::Protocol::Drawable;
 my $X = X11::Protocol->new;

 use Image::Base::X11::Protocol::Pixmap;
 my $image = Image::Base::X11::Protocol::Pixmap->new
               (-X          => $X,
                -width      => 200,
                -height     => 100,
                -for_window => $win);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::X11::Protocol::Pixmap> is a subclass of
C<Image::Base::X11::Protocol::Drawable>,

    Image::Base
      Image::Base::X11::Protocol::Drawable
        Image::Base::X11::Protocol::Pixmap

=head1 DESCRIPTION

C<Image::Base::X11::Protocol::Pixmap> extends C<Image::Base> to create and
draw into X pixmaps by sending drawing requests to an X server using
C<X11::Protocol>.  There's no file load or save, just drawing operations.

=head1 FUNCTIONS

See L<Image::Base::X11::Protocol::Drawable/FUNCTIONS> and
L<Image::Base/FUNCTIONS> for behaviour inherited from the superclasses.

=over 4

=item C<$image = Image::Base::X11::Protocol::Pixmap-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  An existing pixmap can be used,
usually with a colormap for where to allocate colours.

    $image = Image::Base::X11::Protocol::Pixmap->new
                 (-X        => $x11_protocol_obj,
                  -pixmap   => $pixmap_xid,
                  -colormap => $colormap_xid);

Or a new pixmap can be created,

    $image = Image::Base::X11::Protocol::Pixmap->new
                 (-X      => $x11_protocol_obj,
                  -width  => 100,
                  -height => 100);  # default screen and depth

A pixmap requires a size, screen and depth, plus a colormap if allocating
colours instead of making a bitmap or similar.  The default is the
C<X11::Protocol> object's current C<choose_screen> and the depth of the root
window on that screen, or desired settings can be applied with

    -screen   => integer screen number
    -depth    => integer bits per pixel
    -colormap => integer XID

If C<-depth> is given and it's not the screen's default depth then there's
no default colormap (since the screen's default would be wrong).  This
happens when creating a bitmap,

    $image = Image::Base::X11::Protocol::Pixmap->new
                 (-width   => 10,
                  -height  => 10,
                  -depth   => 1);  # bitmap, no colormap

The following further helper options can create a pixmap for use with a
particular window or another pixmap,

    -for_drawable =>  integer XID
    -for_window   =>  integer XID

C<-for_drawable> means the depth and screen of that pixmap or window.
C<-for_window> likewise and in addition the colormap fetched from it per
C<GetWindowAttributes>.  Getting this information is a server round-trip
(except for a root window) so if you already know those things then passing
them as C<-screen>, C<-depth> and C<-colormap> is faster.

=back

=head1 ATTRIBUTES

See C<Image::Base::X11::Protocol::Drawable> for the base drawable attributes
inherited.

=over

=item C<-pixmap> (XID integer)

The target pixmap.  C<-drawable> and C<-pixmap> access the same attribute.

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

The size of a pixmap cannot be changed once created.

The maximum size allowed by the protocol is 32767x32767, and minimum 1x1.
When creating a pixmap currently the sizes are chopped by Perl's C<pack> to
a signed 16 bits, which means 32768 to 65535 results in an X protocol error
(being negatives), but for instance 65546 wraps around to 10 and will seem
to work.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::X11::Protocol::Drawable>,
L<Image::Base::X11::Protocol::Window>,
L<X11::Protocol>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-x11-protocol/index.html

=head1 LICENSE

Image-Base-X11-Protocol is Copyright 2010, 2011, 2012, 2013 Kevin Ryde

Image-Base-X11-Protocol is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Image-Base-X11-Protocol is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Image-Base-X11-Protocol.  If not, see <http://www.gnu.org/licenses/>.

=cut

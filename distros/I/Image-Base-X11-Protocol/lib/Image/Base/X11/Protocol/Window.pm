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


# X11::Protocol::Ext::SHAPE
# /usr/share/doc/x11proto-xext-dev/shape.txt.gz
# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#

package Image::Base::X11::Protocol::Window;
use 5.004;
use strict;
use Carp;
use vars '@ISA', '$VERSION';

use Image::Base::X11::Protocol::Drawable;
@ISA = ('Image::Base::X11::Protocol::Drawable');

# uncomment this to run the ### lines
# use Smart::Comments;

$VERSION = 14;


sub new {
  my ($class, %params) = @_;
  ### X11-Protocol-Window new()

  # lookup -colormap from -window if not supplied
  if (! defined $params{'-colormap'}) {
    my %attrs = $params{'-X'}->GetWindowAttributes ($params{'-window'});
    $params{'-colormap'} = $attrs{'colormap'};
  }

  # alias -window to -drawable
  if (my $win = delete $params{'-window'}) {
    $params{'-drawable'} = $win;
  }

  return $class->SUPER::new (%params);
}

sub DESTROY {
  my ($self) = @_;
  ### X11-Protocol-Window DESTROY
  _free_bitmap_gc($self);
  shift->SUPER::DESTROY (@_);
}
sub _free_bitmap_gc {
  my ($self) = @_;
  if (my $bitmap_gc = delete $self->{'_bitmap_gc'}) {
    ### FreeGC bitmap_gc: $bitmap_gc
    $self->{'-X'}->FreeGC ($bitmap_gc);
  }
}

my %get_window_attributes = (-colormap => 1,
                             -visual   => 1);
sub _get {
  my ($self, $key) = @_;
  ### X11-Protocol-Window _get(): $key

  if (! exists $self->{$key}) {
    if ($get_window_attributes{$key}) {
      my $attr = ($self->{'_during_get'}->{'GetWindowAttributes'} ||= do {
        my %attr = $self->{'-X'}->GetWindowAttributes ($self->{'-drawable'});
        foreach my $field ('visual') {
          if (! exists $self->{"-$field"}) {  # unchanging
            $self->{"-$field"} = $attr{$field};
          }
        }
        \%attr
      });
      return $attr->{substr($key,1)};
    }
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;

  if (exists $params{'-drawable'}) {
    _free_bitmap_gc ($self);
    delete $self->{'-visual'};  # must be refetched, or provided in %params
  }

  my $width  = delete $params{'-width'};
  my $height = delete $params{'-height'};

  # set -drawable before applying -width and -height
  $self->SUPER::set (%params);

  if (defined $width || defined $height) {
    $self->{'-X'}->ConfigureWindow
      ($self->{'-drawable'},
       (defined $width  ? (width => $width)   : ()),
       (defined $height ? (height => $height) : ()));
  }
}

#------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Window xy(): "$x, $y".(@_>=4 && ", $colour")

  if ((my $X = $self->{'-X'})->{'ext'}->{'SHAPE'}) {

    # don't overflow INT16 in requests
    if ($x < 0 || $y < 0 || $x > 0x7FFF || $y > 0x7FFF) {
      ### entirely outside max possible drawable ...
      return undef; # fetch or store
    }

    if (@_ >= 4) {
      if ($colour eq 'None') {
        ### Window xy() subtract shape ...
        $X->ShapeRectangles ($self->{'-drawable'},
                             'Bounding',
                             'Subtract',
                             0,0, # offset
                             'YXBanded',
                             [ $x,$y, 1,1 ]);
        return;
      }
    } else {
      ### Window xy() fetch shape ...
      my ($ordering, @rects) = $X->ShapeGetRectangles ($self->{'-drawable'},
                                                       'Bounding');
      ### @rects
      if (! _rects_contain_xy($x,$y,@rects)) {
        return 'None';
      }
    }
  }
  shift->SUPER::xy (@_);
}

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour) = @_;
  ### X11-Protocol-Window line(): $x1,$y1, $x2,$y2, $colour

  if ($colour eq 'None'
      && (my $X = $self->{'-X'}) ->{'ext'}->{'SHAPE'}) {

    unless (Image::Base::X11::Protocol::Drawable::_line_any_positive($x1,$y1, $x2,$y2)) {
      ### nothing positive ...
      return;
    }
    my $bitmap_width = abs($x2-$x1)+1;
    my $bitmap_height = abs($y2-$y1)+1;
    if ($bitmap_width > 0x7FFF || $bitmap_height > 0x7FFF
        || $x1 < -0x8000 || $x2 < -0x8000
        || $x1 > 0x7FFF || $x2 > 0x7FFF
        || $y1 < -0x8000 || $y2 < -0x8000
        || $y1 > 0x7FFF || $y2 > 0x7FFF) {
      ### coordinates would overflow, use superclass ...
      shift->SUPER::line(@_);
      return;
    }

    my ($bitmap, $bitmap_gc) = _make_bitmap_and_gc
      ($self, $bitmap_width , $bitmap_height);

    my $xmin = ($x1 < $x2 ? $x1 : $x2);
    my $ymin = ($y1 < $y2 ? $y1 : $y2);
    $X->PolySegment ($bitmap, $bitmap_gc,
                     $x1-$xmin,$y1-$ymin, $x2-$xmin,$y2-$ymin);
    $X->ShapeMask ($self->{'-drawable'},
                   'Bounding',
                   'Subtract',
                   $xmin,$ymin, # offset
                   $bitmap);
    $X->FreePixmap ($bitmap);
  } else {
    shift->SUPER::line (@_);
  }
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Window rectangle: $x1, $y1, $x2, $y2, $colour, $fill
  if ($colour eq 'None'
      && (my $X = $self->{'-X'}) ->{'ext'}->{'SHAPE'}) {

    unless ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF) {
      ### entirely outside max possible drawable ...
      return;
    }

    # don't underflow INT16 -0x8000 x,y in request
    # retain negativeness so as not to bring unfilled sides into view
    if ($x1 < -1) { $x1 = -1; }
    if ($y1 < -1) { $y1 = -1; }

    # don't overflow CARD16 width,height in request
    if ($x2 > 0x7FFF) { $x2 = 0x7FFF; }
    if ($y2 > 0x7FFF) { $y2 = 0x7FFF; }

    my @rects;
    my $width = $x2 - $x1 + 1;
    my $height = $y2 - $y1 + 1;
    if ($fill
        || $width <= 2
        || $height <= 2) {
      # filled, or unfilled 2xN or Nx2 as one rectangle
      @rects = ([ $x1, $y1, $width, $height ]);
    } else {
      # unfilled, line segments
      @rects = ([ $x1, $y1,   $width, 1    ],  # top
                [ $x1,$y1+1,  1, $height-2 ],  # left
                [ $x2,$y1+1,  1, $height-2 ],  # right
                [ $x1, $y2,   $width, 1    ]); # bottom
    }
    $X->ShapeRectangles ($self->{'-drawable'},
                         'Bounding',
                         'Subtract',
                         0,0, # offset
                         'YXBanded', @rects);

  } else {
    $self->SUPER::rectangle ($x1, $y1, $x2, $y2, $colour, $fill);
  }
}
sub Image_Base_Other_rectangles {
  ### X11-Protocol-Window rectangles() ...
  my $self = shift;
  my $colour = shift;
  my $fill = shift;

  # ENHANCE-ME: multiple rectangles at once to ShapeRectangles()
  ### rectangles: @_
  while (@_) {
    $self->rectangle (shift,shift,shift,shift, $colour, $fill);
  }
}

sub ellipse {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Window ellipse(): $x1,$y1, $x2,$y2, $colour
  if ($colour eq 'None'
      && (my $X = $self->{'-X'}) ->{'ext'}->{'SHAPE'}) {
    ### use shape ...

    unless ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF) {
      ### entirely outside max possible drawable ...
      return;
    }
    if ($x1 < -0x8000 || $x2 > 0x7FFF || $y1 < -0x8000 || $y2 > 0x7FFF) {
      ### coordinates would overflow, use superclass ...
      shift->SUPER::ellipse(@_);
      return;
    }

    my $win = $self->{'-drawable'};
    my $w = $x2 - $x1;
    my $h = $y2 - $y1;
    if ($w <= 1 || $h <= 1) {
      $X->ShapeRectangles ($win,
                           'Bounding',
                           'Subtract',
                           0,0, # offset
                           'YXBanded',
                           [ $x1, $y1, $w+1, $h+1 ]);
    } else {
      my ($bitmap, $bitmap_gc) = _make_bitmap_and_gc ($self, $w+1, $h+1);

      # fill+outline per comments in Drawable.pm
      my @args = ($bitmap, $bitmap_gc, [ 0, 0, $w, $h, 0, 365*64 ]);
      if ($fill) {
        $X->PolyFillArc (@args);
      }
      $X->PolyArc (@args);

      $X->ShapeMask ($self->{'-drawable'},
                     'Bounding',
                     'Subtract',
                     $x1,$y1, # offset
                     $bitmap);
      $X->FreePixmap ($bitmap);
    }
  } else {
    shift->SUPER::ellipse (@_);
  }
}

sub diamond {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Window diamond(): $x1,$y1, $x2,$y2, $colour

  if ($colour eq 'None'
      && (my $X = $self->{'-X'}) ->{'ext'}->{'SHAPE'}) {
    ### use shape ...

    if ($x1==$x2 && $y1==$y2) {
      # 1x1 polygon draws nothing, do it as a point instead
      $self->xy ($x1,$y1, $colour);
      return;
    }

    unless ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF) {
      ### entirely outside max possible drawable ...
      return;
    }
    if ($x1 < -0x8000 || $x2 > 0x7FFF || $y1 < -0x8000 || $y2 > 0x7FFF) {
      ### coordinates would overflow, use superclass ...
      shift->SUPER::diamond(@_);
      return;
    }

    my $drawable = $self->{'-drawable'};

    $x2 -= $x1;   # offset so 0,0 to x2,y2
    $y2 -= $y1;
    my ($bitmap, $bitmap_gc)
      = _make_bitmap_and_gc ($self, $x2+1, $y2+1);  # width,height
    Image::Base::X11::Protocol::Drawable::_diamond_drawable
        ($X, $bitmap, $bitmap_gc, 0,0, $x2,$y2, $fill);
    $X->ShapeMask ($drawable,
                   'Bounding',
                   'Subtract',
                   $x1,$y1,     # offset
                   $bitmap);
    $X->FreePixmap ($bitmap);

  } else {
    shift->SUPER::diamond (@_);
  }
}

#------------------------------------------------------------------------------
sub _make_bitmap_and_gc {
  my ($self, $width, $height) = @_;
  ### _make_bitmap_and_gc(): "$width,$height"
  my $X = $self->{'-X'};

  my $bitmap = $X->new_rsrc;
  ### CreatePixmap of bitmap: $bitmap
  $X->CreatePixmap ($bitmap, $self->{'-drawable'}, 1, $width, $height);

  my $bitmap_gc = $self->{'_bitmap_gc'};
  if ($bitmap_gc) {
    $X->ChangeGC ($bitmap_gc, foreground => 0);
  } else {
    $bitmap_gc = $X->new_rsrc;
    $X->CreateGC ($bitmap_gc, $bitmap, foreground => 0);
  }
  $X->PolyFillRectangle ($bitmap, $bitmap_gc, [0,0, $width,$height]);
  $X->ChangeGC ($bitmap_gc, foreground => 1);
  return ($bitmap, $bitmap_gc);
}

#------------------------------------------------------------------------------

# _rects_contain_xy($x,$y, [$rx,$ry,$rw,$rh],...) returns true if pixel
# $x,$y is within any of the given rectangle arrayrefs.
#
# For any order except Unsorted could stop searching when $ry > $y, if that
# was worth the extra code.
#
sub _rects_contain_xy {
  ### _rects_contain_xy() ...
  my $x = shift;
  my $y = shift;
  while (@_) {
    my ($rx,$ry,$width,$height) = @{(shift)};
    if ($rx <= $x && $rx+$width > $x
        && $ry <= $y && $ry+$height > $y) {
      ### found: "$x,$y  in  $rx,$ry, $width,$height"
      return 1;
    }
  }
  ### not found ...
  return 0;
}


1;
__END__

#   if (! exists $self->{$key} && $window_attributes{$key}) {
#     return $self->_get_window_attributes->{substr($key,1)};
#   }
# 
# sub _get_window_attributes {
#   my ($self) = @_;
#   return ($self->{'_cache'}->{'GetWindowAttributes'} ||= do {
#     ### X11-Protocol-Drawable GetWindowAttributes: $self->{'-drawable'}
#     my %attrs = $self->{'-X'}->GetWindowAttributes ($self->{'-drawable'});
#     ### \%attrs
#     \%attrs
#   });
# }

=for stopwords undef Ryde colormap ie resizes XID subclasses superclasses Drawable resizing

=head1 NAME

Image::Base::X11::Protocol::Window -- draw into an X11::Protocol window

=for test_synopsis my ($win_xid)

=head1 SYNOPSIS

 use Image::Base::X11::Protocol::Drawable;
 my $X = X11::Protocol->new;

 use Image::Base::X11::Protocol::Window;
 my $image = Image::Base::X11::Protocol::Window->new
               (-X      => $X,
                -window => $win_xid);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::X11::Protocol::Window> is a subclass of
C<Image::Base::X11::Protocol::Drawable>,

    Image::Base
      Image::Base::X11::Protocol::Drawable
        Image::Base::X11::Protocol::Window

=head1 DESCRIPTION

C<Image::Base::X11::Protocol::Window> extends C<Image::Base> to draw into an
X window by speaking directly to an X server using C<X11::Protocol>.
There's no file load or save, just drawing operations.

As an experimental feature, if the C<X11::Protocol> object has the SHAPE
extension available and initialized then colour "None" means transparent and
drawing it subtracts from the window's shape to make see-though holes.  This
is fun, and makes "None" more or less work like other C<Image::Base>
subclasses, but is probably not actually very useful.

=head1 FUNCTIONS

See L<Image::Base::X11::Protocol::Drawable/FUNCTIONS> and
L<Image::Base/FUNCTIONS> for behaviour inherited from the superclasses.

=over 4

=item C<$image = Image::Base::X11::Protocol::Window-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  This requires an C<X11::Protocol>
connection object and window XID (an integer).

    $image = Image::Base::X11::Protocol::Window->new
                 (-X      => $x11_protocol_obj,
                  -window => $win_xid);

C<-colormap> is set from the window's current colormap attribute, or pass a
value to save a server round-trip if you know it already or if you want a
different colormap.

There's nothing to create a new X window since there's many settings for it
and they seem outside the scope of this wrapper.

=back

=head1 ATTRIBUTES

=over

=item C<-window> (XID integer)

The target window.  C<-drawable> and C<-window> access the same attribute.

=item C<-width> (integer)

=item C<-height> (integer)

Changing these resizes the window per C<ConfigureWindow>.  See the base
Drawable class for the way fetching uses C<GetGeometry>.

The maximum size allowed by the protocol in various places is 32767x32767,
and the minimum is 1x1.  When creating or resizing currently the sizes end
up chopped by Perl's C<pack> to a signed 16 bits, which means 32768 to 65535
results in an X protocol error (being negatives), but for instance 65546
wraps around to 10 and will seem to work.

In the current code a window size change made outside this wrapper
(including perhaps by the user through the window manager) is not noticed by
the wrapper and C<-width> and C<-height> remain as the cached values.
A C<GetGeometry> for every C<get()> would be the only way to be sure of
the right values, but a server query every time would likely be very slow
for generic image code designed for in-memory images, and of course most of
the time the window size doesn't change.

=item C<-colormap> (integer XID)

Changing this doesn't change the window's colormap attribute, it's just
where the drawing operations should allocate colours.

=back

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::X11::Protocol::Drawable>,
L<Image::Base::X11::Protocol::Pixmap>

L<X11::Protocol>,
L<X11::Protocol::Ext::SHAPE>

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

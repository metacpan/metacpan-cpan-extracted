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


# /usr/share/doc/x11proto-core-dev/x11protocol.txt.gz
#

package Image::Base::X11::Protocol::Drawable;
use 5.004;
use strict;
use Carp;
use POSIX 'floor';
use X11::Protocol 0.56; # version 0.56 for robust_req() fix
use X11::Protocol::Other 3;  # v.3 for hexstr_to_rgb()
use vars '@ISA', '$VERSION';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 14;

# uncomment this to run the ### lines
# use Smart::Comments '###';

sub new {
  my $class = shift;
  if (ref $class) {
    croak "Cannot clone base drawable";
  }
  return bless {
                # these not documented as yet
                -colour_to_pixel => {  },
                -gc_colour => '',
                -gc_pixel  => -1,

                @_ }, $class;
}

# This not working yet.  Good to CopyArea when screen,depth,colormap permit,
# is it worth the trouble though?
#
# =item C<$new_image = $image-E<gt>new_from_image ($class, key=E<gt>value,...)>
#
# Create and return a new image of type C<$class>.
#
# Target class C<Image::Base::X11::Protocol::Pixmap> is recognised and done by
# CopyArea of the C<$image> drawable into the new pixmap.  Other classes are
# left to the plain C<Image::Base> C<new_from_image>.
#
# sub new_from_image {
#   my $self = shift;
#   my $new_class = shift;
#
#   if (! ref $new_class
#       && $new_class->isa('Image::Base::X11::Protocol::Pixmap')) {
#     my %param = @_;
#     my $X = $self->{'-X'};
#     if ($param{'-X'} == $X) {
#       my ($depth, $width, $height, $colormap)
#         = $self->get('-screen','-depth','-width','-height');
#       my ($new_screen, $new_depth)
#         = $new_class->_new_params_screen_and_depth(\%params);
#       if ($new_screen == $screen
#           && $new_depth == $depth
#           && $new_colormap == $colormap) {
#
#         my $new_image = $new_class->new (%param);
#
#         ### copy to new Pixmap
#         my ($width, $height) = $self->get('-width','-height');
#         my ($new_width, $new_height) = $new_image->get('-width','-height');
#         $X->CopyArea ($self->{'-drawable'},        # src
#                       $new_image->{'-drawable'},   # dst
#                       _gc_created($self),
#                       0,0,  # src x,y
#                       min ($width,$new_width), min ($height,$new_height)
#                       0,0); # dst x,y
#         return $new_image;
#       }
#     }
#   }
#   return $self->SUPER::new_from_image ($new_class, @_);
# }
# sub _gc_created {
#   my ($self) = @_;
#   return ($self->{'-gc_created'} ||= do {
#     my $gc = $self->{'-X'}->new_rsrc;
#     ### CreateGC: $gc
#     $self->{'-X'}->CreateGC ($gc, $self->{'-drawable'});
#     $gc
#   });
# }

sub DESTROY {
  my ($self) = @_;
  ### X11-Protocol-Drawable DESTROY
  _free_gc_created ($self);
  shift->SUPER::DESTROY (@_);
}
sub _free_gc_created {
  my ($self) = @_;
  if (my $gc = delete $self->{'-gc_created'}) {
    ### FreeGC: $gc
    $self->{'-X'}->FreeGC ($gc);
  }
}

sub get {
  my ($self) = @_;
  local $self->{'_during_get'} = {};
  return shift->SUPER::get(@_);
}
my %get_geometry = (-depth         => sub{$_[1]->{'root_depth'}},
                    -root          => sub{$_[1]->{'root'}},
                    -x             => sub{0},
                    -y             => sub{0},
                    -width         => sub{$_[1]->{'width_in_pixels'}},
                    -height        => sub{$_[1]->{'height_in_pixels'}},
                    -border_width  => sub{0},

                    # and with extra crunching
                    -screen        => sub{$_[0]});

sub _get {
  my ($self, $key) = @_;
  ### X11-Protocol-Drawable _get(): $key

  if (! exists $self->{$key}
      && defined (my $rsubr = $get_geometry{$key})) {
    my $X = $self->{'-X'};
    my $drawable = $self->{'-drawable'};

    if (defined (my $screen = X11::Protocol::Other::root_to_screen ($X, $drawable))) {
      # $drawable is a root window, grab info out of $X
      &$rsubr ($screen, $X->{'screens'}->[$screen]);
    }

    my %geom = $X->GetGeometry ($self->{'-drawable'});
    foreach my $gkey (keys %get_geometry) {
      if (! defined $self->{$gkey}) {
        $self->{$gkey} = $geom{substr($gkey,1)};
      }
    }
    if (! defined $self->{'-screen'}) {
      $self->{'-screen'} = X11::Protocol::Other::root_to_screen ($X, $geom{'root'});
    }
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;

  if (exists $params{'-pixmap'}) {
    $params{'-drawable'} = delete $params{'-pixmap'};
  }
  if (exists $params{'-window'}) {
    $params{'-drawable'} = delete $params{'-window'};
  }

  if (exists $params{'-drawable'}) {
    _free_gc_created ($self);
    # purge these cached values, %params can supply new ones if desired
    delete @{$self}{keys %get_geometry}; # hash slice
  }
  if (exists $params{'-colormap'}) {
    %{$self->{'-colour_to_pixel'}} = ();  # clear
  }
  if (exists $params{'-gc'}) {
    # no longer know what colour is in the gc, or not unless included in
    # %params
    $self->{'-gc_colour'} = '';
    $self->{'-gc_pixel'} = -1;
  }

  %$self = (%$self, %params);
}

#------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### xy
  ### $x
  ### $y
  ### $colour

  if ($x < 0 || $y < 0 || $x > 0x7FFF || $y > 0x7FFF) {
    ### outside max drawable, don't overflow INT16 ...
    return undef; # fetch or store
  }

  my $X = $self->{'-X'};
  my $drawable = $self->{'-drawable'};
  if (@_ == 4) {
    # store colour
    $X->PolyPoint ($drawable, _gc_colour($self,$colour), 'Origin', $x,$y);
    return;
  }

  # fetch colour
  my @reply = $X->robust_req ('GetImage', $drawable,
                              $x, $y, 1, 1, 0xFFFFFFFF, 'ZPixmap');
  if (! ref $reply[0]) {
    if ($reply[0] eq 'Match') {
      ### Match error reading offscreen
      return '';
    }
    croak "Error reading pixel: ",join(' ',@reply);
  }
  my ($depth, $visual, $bytes) = @{$reply[0]};
  if (! defined $self->{'-depth'}) {
    $self->{'-depth'} = $depth;
  }
  ### $depth
  ### $visual

  # X11::Protocol 0.56 shows named 'LeastSiginificant' in the pod, but the
  # code gives raw number '0'.  Let num() crunch either.
  if ($X->num('Significance',$X->{'image_byte_order'}) == 0) {
    #### reverse for LSB image format
    $bytes = reverse $bytes;
  }
  ### $bytes
  my $pixel = unpack ('N', $bytes);

  # not sure what the protocol says about extra bits or bytes in the reply
  # data, have seen a freebsd server giving garbage, so mask the extras
  $pixel &= (1 << $depth) - 1;

  ### pixel: sprintf '%X', $pixel
  ### pixel_to_colour: $self->pixel_to_colour($pixel)
  if (defined ($colour = $self->pixel_to_colour($pixel))) {
    return $colour;
  }
  if (my $colormap = $self->{'-colormap'}) {
    #### query: $X->QueryColors ($self->get('-colormap'), $pixel)
    my ($rgb) = $X->QueryColors ($self->get('-colormap'), $pixel);
    #### $rgb
    return sprintf('#%04X%04X%04X', @$rgb);
  }
  return $pixel;
}
sub Image_Base_Other_xy_points {
  my $self = shift;
  my $colour = shift;
  my $gc = _gc_colour($self,$colour);
  my $X = $self->{'-X'};

  # PolyPoint is 3xCARD32 for drawable,gc,mode then room for maxlen-3 words
  # of X,Y values.  X and Y are INT16 each, hence room for (maxlen-3)*2
  # individual points.  Is there any merit sending smaller chunks though?
  # 250kbytes is a typical server limit.
  #
  my $maxpoints = 2*($X->{'maximum_request_length'} - 3);
  ### $maxpoints

  my @points;
  while (@_) {
    if (@points >= $maxpoints) {
      $X->PolyPoint ($self->{'-drawable'}, $gc, 'Origin', @points);
      $#points = -1; # empty
    }
    my $x = shift;
    my $y = shift;
    if ($x >= 0 && $y >= 0 && $x <= 0x7FFF && $y <= 0x7FFF) {
      # within max drawable ...
      push @points, $x,$y;
    }
  }
  if (@points) {
    $X->PolyPoint ($self->{'-drawable'}, $gc, 'Origin', @points);
  }
}

sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_ ;

  ($x1,$y1, $x2,$y2) = _line_clip ($x1,$y1, $x2,$y2)
    or return;  # nothing left after clipping

  $self->{'-X'}->PolySegment ($self->{'-drawable'}, _gc_colour($self,$colour),
                              $x1,$y1, $x2,$y2);
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### X11-Protocol-Drawable rectangle

  unless ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF) {
    ### entirely outside max possible drawable ...
    return;
  }

  # Don't underflow INT16 -0x8000 x,y in request.  But retain negativeness so
  # as not to bring top and left sides of an unfilled rect into view.
  if ($x1 < -1) { $x1 = -1; }
  if ($y1 < -1) { $y1 = -1; }

  # Don't overflow CARD16 width,height in request.  Together with x1,y1 >=
  # -1 this makes w,h <= 0x8002.  It doesn't bring the unfilled right and
  # bottom sides into view even if the drawable is 0 to 0x7FFF.
  if ($x2 > 0x8000) { $x2 = 0x8000; }
  if ($y2 > 0x8000) { $y2 = 0x8000; }

  if ($x1 == $x2 || $y1 == $y2) {
    # single pixel wide or high, must treat as filled since PolyRectangle()
    # draws nothing if passed width==0 or height==0
    $fill = 1;
  } else {
    $fill = !!$fill;  # 0 or 1 for arithmetic
  }
  ### coords: [ $x1, $y1, $x2-$x1, $y2-$y1 ]

  $self->{'-X'}->request ($fill ? 'PolyFillRectangle' : 'PolyRectangle',
                          $self->{'-drawable'},
                          _gc_colour($self,$colour),
                          [ $x1, $y1, $x2-$x1+$fill, $y2-$y1+$fill ]);
}

sub Image_Base_Other_rectangles {
  ### X11-Protocol-Drawable rectangles()
  ### count: scalar(@_)
  my $self = shift;
  my $colour = shift;
  my $fill = !! shift;  # 0 or 1

  my $method = ($fill ? 'PolyFillRectangle' : 'PolyRectangle');
  ### $method

  ### coords count: scalar(@_)
  ### coords: @_

  my @rects;
  my @filled;
  while (my ($x1,$y1, $x2,$y2) = splice @_,0,4) {
    ### quad: ($x1,$y1, $x2,$y2)

    unless ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF) {
      ### entirely outside max possible drawable ...
      next;
    }
    # don't underflow INT16 -0x8000 x,y in request
    # but retain negativeness so as not to bring unfilled sides into view
    if ($x1 < -1) { $x1 = -1; }
    if ($y1 < -1) { $y1 = -1; }
    # don't overflow CARD16 width,height in request
    if ($x2 > 0x8000) { $x2 = 0x8000; }
    if ($y2 > 0x8000) { $y2 = 0x8000; }

    if (! $fill && ($x1 == $x2 || $y1 == $y2)) {
      # single pixel wide or high
      push @filled, [ $x1, $y1, $x2-$x1+1, $y2-$y1+1 ];
    } else {
      push @rects, [ $x1, $y1, $x2-$x1+$fill, $y2-$y1+$fill ];
    }
  }
  ### @rects

  my $X = $self->{'-X'};
  my $gc = _gc_colour($self,$colour);

  # PolyRectangle is 3xCARD32 header,drawable,gc then room for maxlen-3
  # words of X,Y,WIDTH,HEIGHT values.  X,Y are INT16 and WIDTH,HEIGHT are
  # CARD16 each, hence room for floor((maxlen-3)/2) rectangles.  Is there
  # any value sending somewhat smaller chunks though?  250kbytes is a
  # typical server limit.  Xlib ZRCTSPERBATCH is just 256 thin line rects,
  # or WRCTSPERBATCH 10 wides.
  #
  my $maxrects = int (($X->{'maximum_request_length'} - 3) / 2);
  ### $maxrects

  foreach my $aref (\@rects, \@filled) {
    if (@$aref) {
      my $drawable = $self->{'-drawable'};
      while (@$aref > $maxrects) {
        ### splice down from: scalar(@$aref)
        $X->$method ($drawable, $gc, splice @$aref, 0,$maxrects);
      }
      ### final: $method, @$aref
      $X->$method ($drawable, $gc, @$aref);
    }
    $method = 'PolyFillRectangle';
  }
}

# The Arc requests take the bounding region at
#    left   x,       y+(h/2)
#    right  x+w,     y+(h/2)
#    top    x+(w/2), y
#    bottom x+(w/2), y+h
# with w=x2-x1, h=y2-y1.
#
# For PolyArc a 1-wide line makes each of those pixels drawn, but a
# PolyFillArc is only the inside, not the extra 0.5 around the outside,
# which means the bottom and right endmost pixels not drawn, and others a
# bit smaller than PolyArc.
#
# For now try a PolyArc on top of the PolyFillArc to get the extra 0.5
# around the outside.  Can it be done better?  Prima has this, as long as
# the drawing mode isn't xor etc where duplicated pixels are bad.
#
# One possibility would be to set line width lw=min(w/2,h/2) rounded up to
# next odd integer, and shrink the bounding box by (lw-1)/2, so a PolyLine
# centred there goes out to the very edges of the x1,y1,x2,y2 box, not just
# the centres of those pixels, and being w/2 or h/2 will extend in to cover
# the centre.  The disadvantage would be changing the line width for each
# draw, or keep another gc, and that might take away the option for the user
# to set in a '-gc' option to choose between zero-width fast lines and
# 1-width exact lines.  An advantage though would be a single draw operation
# meaning an "xor" mode in the gc would cover the right pixels.  There's
# something in the PolyArc spec about the bounding box being implementation
# dependent if width!=height, so maybe this wouldn't work always.
#
# The same bounding box centred on the pixels happens in rectangle(), but
# can be handled there by +1 on the width and height.  A +1 doesn't make a
# filled ellipse come out the same as an outlined ellipse though.
#
# same in Window.pm for shape stuff
sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Drawable ellipse(): $x1, $y1, $x2, $y2, $colour

  my $w = $x2 - $x1;
  my $h = $y2 - $y1;
  if ($w <= 1 || $h <= 1) {
    # 1 or 2 pixels wide or high
    shift->rectangle(@_);
    return;
  }

  unless ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF) {
    ### entirely outside max possible drawable ...
    return;
  }

  if ($x1 < -0x8000 || $x2 > 0x7FFF || $y1 < -0x8000 || $y2 > 0x7FFF) {
    ### coordinates would overflow, use superclass ...
    shift->SUPER::ellipse(@_);
    return;
  }

  ### PolyArc: $x1, $y1, $x2-$x1+1, $y2-$y1+1, 0, 360*64
  my @args = ($self->{'-drawable'}, _gc_colour($self,$colour),
              [ $x1, $y1, $w, $h, 0, 360*64 ]);
  my $X = $self->{'-X'};
  if ($fill) {
    $X->PolyFillArc (@args);
  }
  $X->PolyArc (@args);
}

sub diamond {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Drawable diamond(): $x1, $y1, $x2, $y2, $colour

  if ($x1==$x2 && $y1==$y2) {
    # 1x1 polygon draws nothing, do it as a point instead
    $self->xy($x1,$y1, $colour);
    return;
  }

  _diamond_drawable ($self->{'-X'},
                     $self->{'-drawable'},
                     _gc_colour($self,$colour),
                     $x1,$y1, $x2,$y2, $fill);
}

# shared by Image::Base::X11::Protocol::Window::diamond()
sub _diamond_drawable {
  my ($X, $drawable, $gc, $x1, $y1, $x2, $y2, $fill) = @_;
  ### _diamond_drawable() ...

  my $xh = int( ($x2 - $x1)/2 );
  my $yh = int( ($y2 - $y1)/2 );
  my $xmid_floor = $x1 + $xh;
  my $xmid_ceil  = $x2 - $xh;
  my $ymid_floor = $y1 + $yh;
  my $ymid_ceil  = $y2 - $yh;

  if ($fill) {
    #                   1-0
    #                  /
    #                 2     7
    #                 3     6
    #                  \   /
    #                   4-5
    my @xy =(# top
             ($xmid_floor == $xmid_ceil ? () : ($xmid_ceil, $y1)),
             $xmid_floor, $y1,

             # left
             $x1, $ymid_floor,
             ($ymid_floor == $ymid_ceil ? () : ($x1, $ymid_ceil)),

             # bottom
             $xmid_floor, $y2,
             ($xmid_floor == $xmid_ceil ? () : ($xmid_ceil, $y2)),

             # right
             ($ymid_floor == $ymid_ceil ? () : ($x2, $ymid_ceil)),
             $x2, $ymid_floor,
            );
    _convex_poly_clip(\@xy);
    ### clipped: @xy
    if (@xy) {
      push @xy, $xy[0],$xy[1];  # back to start
      $X->FillPoly ($drawable, $gc, 'Convex', 'Origin', @xy);
      $X->PolyLine ($drawable, $gc, 'Origin', @xy);
    }

  } else {
    # unfilled
    $X->PolySegment ($drawable, $gc,

                     # NW   A .
                     #     /   \
                     #    B     .
                     _line_clip ($xmid_floor, $y1,  $x1, $ymid_floor),

                     # SW B     .
                     #     \   /
                     #      A .
                     _line_clip ($xmid_floor, $y2,  $x1, $ymid_ceil),

                     # SE  .     B
                     #      \   /
                     #       . A
                     _line_clip ($xmid_ceil, $y2,  $x2, $ymid_ceil),

                     # NE    . A
                     #      /   \
                     #     .     B
                     _line_clip ($xmid_ceil, $y1,  $x2, $ymid_floor));
  }
}

#------------------------------------------------------------------------------

# not yet a documented feature ...
sub pixel_to_colour {
  my ($self,$pixel) = @_;
  my $hash = ($self->{'-pixel_to_colour'} ||= do {
    ### colour_to_pixel hash: $self->{'-colour_to_pixel'}
    ({ reverse %{$self->{'-colour_to_pixel'}} }) # force anon hash
  });
  return $hash->{$pixel};
}

# return a gc XID which is set to draw in $colour
sub _gc_colour {
  my ($self, $colour) = @_;
  if ($colour eq 'None') {
    $colour = 'black';
  }
  my $gc = $self->{'-gc'} || $self->{'-gc_created'};
  if ($colour ne $self->{'-gc_colour'}) {
    ### X11-Protocol-Drawable -gc_colour() change: $colour
    my $pixel = $self->colour_to_pixel ($colour);
    $self->{'-gc_colour'} = $colour;

    if ($pixel != $self->{'-gc_pixel'}) {
      $self->{'-gc_pixel'} = $pixel;
      my $X = $self->{'-X'};
      if ($gc) {
        ### ChangeGC to pixel: $pixel
        $X->ChangeGC ($gc, foreground => $pixel);
      } else {
        $gc = $self->{'-gc_created'} = $X->new_rsrc;
        ### CreateGC with pixel ...
        ### $gc
        ### $pixel
        $X->CreateGC ($gc, $self->{'-drawable'}, foreground => $pixel);
      }
    }
  }
  return $gc;
}

# return an allocated pixel number
# not yet a documented feature ...
sub colour_to_pixel {
  my ($self, $colour) = @_;
  ### X11-Protocol-Drawable _colour_to_pixel(): $colour
  if ($colour =~ /^^\d+$/) {
    return $colour;  # numeric pixel value
  }
  if ($colour eq 'set') {
    # ENHANCE-ME: maybe all bits set if depth > 1
    return 1;
  }
  if ($colour eq 'clear') {
    return 0;
  }
  if (defined (my $pixel = $self->{'-colour_to_pixel'}->{$colour})) {
    return $pixel;
  }
  $self->add_colours ($colour);
  return $self->{'-colour_to_pixel'}->{$colour};
}

my %colour_to_screen_field
  = ('black'         => 'black_pixel',
     '#000000'       => 'black_pixel',
     '#000000000000' => 'black_pixel',
     'white'         => 'white_pixel',
     '#FFFFFF'       => 'white_pixel',
     '#FFFFFFFFFFFF' => 'white_pixel',
     '#ffffff'       => 'white_pixel',
     '#ffffffffffff' => 'white_pixel',
    );

sub add_colours {
  my $self = shift;
  ### add_colours: @_
  my $X = $self->{'-X'};
  my $colormap = $self->get('-colormap')
    || croak 'No -colormap to add colours to';
  my $colour_to_pixel = $self->{'-colour_to_pixel'};
  my $pixel_to_colour = $self->{'-pixel_to_colour'};

  my @queued;
  my @failed_colours;

  my $old_error_handler = $X->{'error_handler'};
  my $wait_queue = sub {
    my $elem = shift @queued;
    my $seq = $elem->{'seq'};
    my $colour = $elem->{'colour'};

    my $err;
    local $X->{'error_handler'} = sub {
      my ($X, $data) = @_;
      my ($type, $err_seq) = unpack("xCSLSCxxxxxxxxxxxxxxxxxxxxx", $data);
      if ($err_seq != $seq) {
        goto &$old_error_handler;
      }
      $err = 1;
    };

    ### handle: $seq
    $X->handle_input_for ($seq);
    $X->delete_reply ($seq);
    if ($err) {
      push @failed_colours, $colour;
      return;
    }

    ### reply: $X->unpack_reply($elem->{'request_type'}, $elem->{'reply'})

    my ($pixel) = $X->unpack_reply ($elem->{'request_type'}, $elem->{'reply'});
    $colour_to_pixel->{$colour} = $pixel;
    if ($pixel_to_colour) {
      $pixel_to_colour->{$pixel} = $colour;
    }
  };

  while (@_) {
    my $colour = shift;
    next if defined $colour_to_pixel->{$colour};  # already known
    delete $self->{'-pixel_to_colour'};

    # black_pixel or white_pixel of a default colormap
    if (my $field = $colour_to_screen_field{$colour}) { # "black" or "white"
      if (my $screen_info = X11::Protocol::Other::default_colormap_to_screen_info($X,$colormap)) {
        my $pixel = $colour_to_pixel->{$colour} = $screen_info->{$field};
        if ($pixel_to_colour) {
          $pixel_to_colour->{$pixel} = $colour;
        }
        next;
      }
    }

    my $elem = { colour => $colour };
    my @req;
    # Crib: [:xdigit:] new in 5.6, so only 0-9A-F, and in any case as of
    # perl 5.12.4 [:xdigit:] matches some wide chars but hex() doesn't
    # accept them
    if (my @rgb = X11::Protocol::Other::hexstr_to_rgb($colour)) {
      @req = ('AllocColor', $colormap, map {hex} @rgb);
    } else {
      @req = ('AllocNamedColor', $colormap, $colour);
    }
    $elem->{'request_type'} = $req[0];
    my $seq = $elem->{'seq'} = $X->send(@req);
    $X->add_reply ($seq, \$elem->{'reply'});

    ### $elem
    push @queued, $elem;
    if (@queued > 256) {
      &$wait_queue();
    }
  }
  while (@queued) {
    &$wait_queue();
  }

  if (@failed_colours) {
    die "Unknown colour(s): ",join(', ', @failed_colours);
  }
}

#------------------------------------------------------------------------------
# clipping to signed 16-bit parameters

use constant _LO => -0x8000;  # -32768
use constant _HI =>  0x7FFF;  # +32767

# $x1,$y1, $x2,$y2 are the endpoints of a line.
# Return new endpoints which are clipped to within -0x8000 to +0x7FFF which is
# signed 16-bits for X protocol.
# If given line is entirely outside the signed 16-bit rectangle then return
# an empty list.
#
sub _line_clip {
  my ($x1,$y1, $x2,$y2) = @_;
  ### _line_clip_16bit(): "$x1,$y1, $x2,$y2"

  unless (_line_any_positive($x1,$y1, $x2,$y2)) {
    ### nothing positive ...
    return;
  }

  my ($x1new,$y1new) = _line_end_clip($x1,$y1, $x2,$y2)
    or do {
      ### x1,y1 end nothing in range ...
      return;
    };
  ($x2,$y2) = _line_end_clip($x2,$y2, $x1,$y1)
    or return;
  return ($x1new,$y1new, $x2,$y2);
}

# $x1,$y1, $x2,$y2 are the endpoints of a line.
# Return new values for the $x2,$y2 end which clips it to within
#     LO <= x2 <= HI
#     LO <= y2 <= HI
#
# If the line is entirely outside LO to HI then return an empty list.
# If x2,y2 is already within LO to HI then return them unchanged.
#
#                     x1,y1
#                    /
#                +--------       if x2 outside
#                | /             then
#                |/              move it to x2new=LO
#    x2new,y2new *               and y2new=corresponding pos on line
#               /|
#              / |
#        x2,y2   +--------
#               LO
#
#                +---------
#                |               if y2 outside,
#                |    x1,y1      including moved y2new outside
#                |   /           then
#                +--*-----       move it to y2new=LO
#                  /x2new,       and x2new=corresponding pos on line
#                 / y2new       
#    first y2new *
#               / 
#              /  
#        x2,y2              
#
sub _line_end_clip {
  my ($x1,$y1, $x2,$y2) = @_;
  ### _line_end_clip(): "$x1,$y1, $x2,$y2"

  my ($x2new, $y2new);
  if ($x2 < _LO || $x2 > _HI) {
    # x2 is outside LO to HI, clip to x2=LOorHI and y2 set to corresponding
    my $xlen = $x2 - $x1
      or return;   # xlen==0 means x1==x2 so entirely outside LO to HI
    $x2new = ($x2 < _LO ? _LO : _HI);
    $y2new = floor(($y2*($x2new-$x1) + $y1*($x2-$x2new)) / $xlen + 0.5);

    ### x clip: "to $x2new,$y2new   frac ".($y2*($x2new-$x1) + $y1*($x2-$x2new))." / $xlen"
  } else {
    $x2new = $x2;
    $y2new = $y2;
  }

  if ($y2new < _LO || $y2new > _HI) {
    my $ylen = $y2 - $y1
      or return;   # ylen==0 means y1==y2 so entirely outside LO to HI
    $y2new = ($y2 < _LO ? _LO : _HI);
    $x2new = floor(($x2*($y2new-$y1) + $x1*($y2-$y2new)) / $ylen + 0.5);
    ### y clip: "to $x2new,$y2new   left ".($y2new-$y1)." right ".($y2-$y2new)
    if ($x2new < _LO || $x2new > _HI) {
      ### x2new outside ...
      return;
    }
  }

  return ($x2new,$y2new);
}

#               x2,y2
#              /
#             /\
#            /  \
#           /    +---------
#      x1,y1     |
#                |
#
# perp X= -1-pos, Y=-1 -pos*(x2-x1)/(y2-y1)
#      -pos = X+1
#   Y = (X+1)*(x2-x1)/(y2-y1) - 1
#
# intersect
#   (X+1)*(x2-x1)/(y2-y1) - 1 = (X-x1)/(x2-x1)*(y2-y1) + y1
#   (X+1)*(x2-x1)/(y2-y1) = (X-x1)/(x2-x1)*(y2-y1) + (y1+1)
#   (X+1)*(x2-x1) = (X-x1)/(x2-x1)*(y2-y1)*(y2-y1) + (y1+1)*(y2-y1)
#   (X+1)*(x2-x1)*(x2-x1) = (X-x1)*(y2-y1)*(y2-y1) + (y1+1)*(y2-y1)*(x2-x1)
#   X*(x2-x1)^2 + (x2-x1)^2 = X*(y2-y1)^2 - x1*(y2-y1)^2 + (y1+1)*(y2-y1)*(x2-x1)
#   X*(x2-x1)^2 - X*(y2-y1)^2  = -(x2-x1)^2 - x1*(y2-y1)^2 + (y1+1)*(y2-y1)*(x2-x1)
# 
# line X=x1+pos, Y=y1 + pos*(y2-y1)/(x2-x1)
#   Y=y1 + (X-x1)/(x2-x1)*(y2-y1)
# eg. X=x1 Y=y1 + 0
# eg. X=x2 Y=y1 + 1*(y2-y1) = y2
#   Y-y1 = (X-x1)/(x2-x1)*(y2-y1)
#   (Y-y1)*(x2-x1) = (X-x1)*(y2-y1)
#
# line at X=0 is 
#   Y = (-x1)/(x2-x1)*(y2-y1) + y1
# for Y <= -1
#   (-x1)/(x2-x1)*(y2-y1) + y1 <= -1
#   (-x1)/(x2-x1)*(y2-y1) <= -1-y1
#   (-x1)*(y2-y1) <= (-1-y1)*(x2-x1)  would swap if x2<x1
#   x1*(y2-y1) >= (y1+1)*(x2-x1)
# eg. x1=-1;y1=-1; x2=1;y2=1  Y = 0  -2>=0
#
# eg. y1=y2=y 0 < (-1-y)*(x2-x1) 
#   (x1+1)*(y2-y1) > (y1+1)*(x2-x1)
# eg. x1=x2=5  -5*(y2-y1) > (y1+1)*0  no
#
#        | 5,-10
#       /|
# -----/----------
# -10,5  |
# eg. x1=-10;y1=5; x2=5;y2=-10; x1*(y2-y1); (y1+1)*(x2-x1)
# is 150 < 90
#
#      |   10,-5
# -------/-----
#      |/
#     /|
# -5,10|
# eg. x1=-5;y1=10; x2=10;y2=-5; x1*(y2-y1); (y1+1)*(x2-x1)
# is 75 < 165
#
# eg. x1=5;y1=-10; x2=5;y2=10; x1*(y2-y1); (y1+1)*(x2-x1)
# is 100 < 0
#
sub _line_any_positive {
  my ($x1,$y1, $x2,$y2) = @_;

  # swap ends to x1 <= x2
  ($x1,$y1, $x2,$y2) = ($x2,$y2, $x1,$y1) if $x2 < $x1;
  ### _line_any_positive() swapped to: "$x1, $y1,    $x2, $y2"

  return (# must have x2 positive, otherwise all X negative
          $x2 > -1
          &&
          (# if y2 positive then x2,y2 end both positive so line positive
           $y2 > -1
           ||
           (# else must have y1 positive, otherwise y1 and y2 both negative
            $y1 > -1
            # now        |  x2,y2        |    x2,y2    x2 pos, y2 neg
            #        ---------       ---------
            #      x1,y1 |               | x1,y1       x1 pos or neg, y1 pos
            # see if the X position corresponding to Y=0 is >= -1
            &&
            $x1*($y2-$y1) < ($y1+1)*($x2-$x1))));
}

# (xnew-xp)/(x-xp) = (ylo-yp)/(y-yp)
# xnew-xp = (ylo-yp)/(y-yp)*(x-xp)
# xnew = (ylo-yp)/(y-yp)*(x-xp) + xp
#      = x*(ylo-yp)/(y-yp) - xp*(ylo-yp)/(y-yp) + xp
#      = x*(ylo-yp)/(y-yp) + xp*(1 - (ylo-yp)/(y-yp))
#      = x*(ylo-yp)/(y-yp) + xp*(((y-yp) - (ylo-yp))/(y-yp)
#      = [ x*(ylo-yp) + xp*(y - yp - ylo + yp) ]/(y-yp)
#      = [ x*(ylo-yp) + xp*(y-ylo) ]/(y-yp)
#
#                      x,y
#                     /   \
#                    /     \
#                   /       \
# xnew,ynew=ylo  ------------------  
#                 /           \
#                /             \
#          xprev,yprev     xnext,ynext
#
#                      x,y
#                     /   \
#                    /   __* xnext,ynext
#                   /__--
# xnew,ynew=ylo  --*---------------  
#                 /     
#                /      
#          xprev,yprev     
#
#  -8,-8               7,-7   
#    *----          ----*
#    |    |        |    |  
#     ----*        *----  
#         7,7    -8,8    
#

# _convex_poly_clip() takes $aref is an arrayref of vertex coordinates
# $aref = [ $x1,$y1, $x2,$y2, ..., $xn,$yn ].
#
# The polygon is line segment $x1,$y1 to $x2,$y2, etc, and final
# $xn,$yn back to $x1,$y1 start.
#
# Modify the array contents to clip the polygon to signed 16-bit.
# This might either increase or decrease the total number of vertices.
# If the polygon is entirely outside 16-bits then leave an empty array.
#
sub _convex_poly_clip {
  my ($aref) = @_;
  ### _convex_poly_clip(): $aref

  foreach (1 .. 4) {  # each side
    ### side: $_

    for (my $i = 0; $i < $#$aref && $#$aref >= 3; ) {
      ### at: "i=$i of ".scalar(@$aref)."  ".join(', ',@$aref)
      my $y = $aref->[$i+1];
      if ($y <= _HI) {
        # This vertex is below the _HI limit, keep it unchanged.
        $i += 2;

      } else {
        # This vertex is outside the _HI limit, replace it by zero, one or
        # two new clipped points.
        my ($x,$y) = splice @$aref, $i,2;

        {
          my $yprev = $aref->[$i-1];  # with possible wrap back to $xn,$yn
          if ($yprev <= _HI) {
            my $xprev = $aref->[$i-2];
            my $xnew = int(($x*(_HI - $yprev) + $xprev*($y - _HI)) / ($y-$yprev)
                           + 0.5);
            splice @$aref, $i,0, $xnew,_HI;
            $i += 2;
          } else {
            # $yprev and $y both above _HI limit, so nothing for segment
            # $yprev to $y, just leave $yprev for the next vertex to
            # consider.  (This case only occurs when $i==0 and so $yprev is
            # wrapped back to the last vertex $yn.  Any later $i will have
            # $yprev already clipped to $yprev<=_HI.)
          }
        }

        {
          my $inext = $i % scalar(@$aref);
          my $ynext = $aref->[$inext+1];
          if ($ynext <= _HI) {
            my $xnext = $aref->[$inext];
            my $xnew = int(($x*(_HI - $ynext) + $xnext*($y - _HI)) / ($y-$ynext)
                           + 0.5);
            splice @$aref, $i,0, $xnew,_HI;
            $i += 2;
          } else {
            # $y and $ynext both above _HI limit, so nothing for segment $y
            # to $ynext
          }
        }
      }
    }

    # rotate 90
    for (my $i = 0; $i < $#$aref; $i += 2) {
      ($aref->[$i],$aref->[$i+1]) = ($aref->[$i+1], -1 - $aref->[$i]);
    }
  }
  if (@$aref == 2) {
    @$aref = ();
  }
}


1;
__END__

=for stopwords undef Ryde pixmap pixmaps colormap ie XID GC PseudoColor lookups TrueColor RGB drawables gc subclasses Drawable drawable LRU

=head1 NAME

Image::Base::X11::Protocol::Drawable -- draw into an X11::Protocol window or pixmap

=for test_synopsis my ($xid, $colormap)

=head1 SYNOPSIS

 use Image::Base::X11::Protocol::Drawable;
 my $X = X11::Protocol->new;

 my $image = Image::Base::X11::Protocol::Drawable->new
               (-X        => $X,
                -drawable => $xid,
                -colormap => $colormap);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::X11::Protocol::Drawable> is a subclass of
C<Image::Base>,

    Image::Base
      Image::Base::X11::Protocol::Drawable

=head1 DESCRIPTION

C<Image::Base::X11::Protocol::Drawable> extends C<Image::Base> to draw into
X windows or pixmaps by sending drawing requests to an X server with
C<X11::Protocol>.  There's no file load or save, just drawing operations.

The subclasses C<Image::Base::X11::Protocol::Pixmap> and
C<Image::Base::X11::Protocol::Window> have things specific to a pixmap or
window.  Drawable is the common parts.

Native X drawing does much more than C<Image::Base> but if you have some
generic pixel twiddling code for C<Image::Base> then this module lets you
point it at an X window, pixmap, etc.  Drawing directly into a window is a
good way to show slow drawing progressing, rather than drawing a pixmap or
image file and only displaying when complete.  Or see
C<Image::Base::Multiplex> for a way to do both simultaneously.

=head2 Colour Names

Colour names are the server's colour names per C<AllocNamedColor> plus
hexadecimal RGB, and set/clear for bitmaps or monochrome windows,

    AllocNamedColor    usually server's /etc/X11/rgb.txt    
    #RGB               1 to 4 digit hex
    #RRGGBB
    #RRRGGGBBB
    #RRRRGGGGBBBB
    1                  \              
    0                   |  for bitmaps and monochrome windows
    set                 |
    clear              /

Colours used are allocated in a specified C<-colormap>.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::X11::Protocol::Drawable-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  This requires an C<X11::Protocol>
connection object and a drawable XID (an integer).

    my $image = Image::Base::X11::Protocol::Drawable->new
                  (-X        => $x11_protocol_obj,
                   -drawable => $drawable_xid,
                   -colormap => $X->{'default_colormap'});

A colormap should be given if allocating colours, which means generally
means anything except a bitmap or monochrome window.

=cut

=item C<$colour = $image-E<gt>xy ($x, $y)>

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set the pixel at C<$x>,C<$y>.

Fetching a pixel is an X server round-trip so reading a big region will be
slow.  The protocol allows a big region or an entire drawable to be read in
one go, so some function for that could be made if needed.

In the current code the colour returned is either the name used to draw it,
or 4-digit hex #RRRRGGGGBBBB queried from the C<-colormap>, or otherwise a
raw pixel value.  If two colour names are the same pixel value because that
was as close as could be represented then fetching might give either name.
The hex return is 4 digit components because that's the range in the X
protocol.

If the drawable is a window then parts overlapped by another window
(including a sub-window) generally read back as an random colour.  Parts of
a window which are off-screen have no data at all and the return is
currently an empty string C<"">.  Would C<undef> or the window background
pixel be better?  (An off-screen C<GetImage> is actually a Match error
reply, but that's turned into a plain return here since that will be much
more helpful than the C<$X> connection error handler.)

=item C<$image-E<gt>add_colours ($name, $name, ...)>

Allocate colours in the C<-colormap>.  Colour names are the same as for the
drawing functions.  For example,

    $image->add_colours ('red', 'green', '#FF00FF');

Drawing automatically adds a colour if it doesn't already exist but using
C<add_colours> can do a set of pixel lookups in a single server round-trip
instead of separate individual ones.

If using the default colormap of the screen then names "black" and "white"
are taken from the screen info and don't query the server (neither in the
drawing operations nor C<add_colours>).

All colours, both named and hex, are sent to the server for interpretation.
On a static visual like TrueColor a hex RGB might be turned into a pixel
just on the client side, but the X spec allows non-linear weirdness in the
colour ramps so only the server can do it properly.

=back

=head1 ATTRIBUTES

=cut

# Not documented yet ... not sure what the effect of a wide line filled
# ellipse would be too ...
#
# Optional C<-gc> can set a GC (an integer XID) to use for drawing, otherwise
# a new one is created if/when needed and freed when the image is destroyed.
# The C<$image> will consider itself the exclusive user of the C<-gc>
# provided.

=over

=item C<-drawable> (integer XID)

The target drawable.

=item C<-colormap> (integer XID)

The colormap in which to allocate colours when drawing.

Setting C<-colormap> only affects where colours are allocated.  If the
drawable is a window then the colormap is not set into the window's
attributes (that's left to an application if/when required).

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

Width and height are read-only.  The minimum is 1 pixel, the maximum in the
protocol is 0x7FFF (a signed 16-bit value).

Fetching with C<get()> queries the server with C<GetGeometry> and then
caches.  If you already know the size then including values in the C<new()>
will record them ready for later C<get()>.  

    $image = Image::Base::X11::Protocol::Drawable->new
                 (-X        => $x11_protocol_obj,
                  -drawable => $id,
                  -width    => 200,      # known values to
                  -height   => 100,      # avoid server query
                  -colormap => $colormap);

=item C<-depth> (integer, read-only)

The depth of the drawable, meaning how many bits per pixel.

=item C<-screen> (integer, read-only)

The screen number of the C<-drawable>, for example 0 for the first screen.

=back

The depth and screen of a drawable cannot be changed, and for the purposes
of this interface the width and height are regarded as fixed too.  (Is that
a good idea?)

C<get()> of C<-width>, C<-height>, C<-depth> or C<-screen> for a root window
uses values from the C<X11::Protocol> object info without querying the
server.  For other drawables a C<GetGeometry> request is made.  If you
already know the values of some of these attributes then include them in the
C<new()> to record ready for later C<get()> and avoid that C<GetGeometry>
query.  Of course if nothing ever does such a C<get()> then there's no need.
The plain drawing operations don't need the size.

=head1 ALGORITHMS

C<ellipse()> unfilled uses the X C<PolyArc> line centred on the boundary
pixels, being the midpoints of the C<$y1> row, C<$y2> row, C<$x1> column,
etc.  The way the pixel "centre within the shape" rule works should mean
that circles are symmetric, but the X protocol spec allows the server some
implementation dependent latitude for ellipses width!=height.

C<ellipse()> filled uses the X C<FillArc>, but that means the area inside an
ellipse centred on the boundary pixels, which is effectively 1/2 pixel in
from the ellipse line edge.  The pixel "centre on the boundary drawn if
above or left" rule also means the bottom row and rightmost column aren't
drawn at all.  The current strategy is to draw a C<PolyArc> on top for the
extra 1/2 pixel radius.

For a filled circle an alternative strategy would be to set the line width
to half the radius and draw from half way in from the edges.  That means the
line width is from the centre of the box to the outer edges.  The way a line
has linewidth/2 each side makes a resolution of 1/2 pixel possible.  The
disadvantage would be changing the GC each time, which might be undesirable
if it came from the user (secret as-yet undocumented C<-gc> attribute).
Note also this is no good for an ellipse width!=height because if you draw a
fixed distance tangent to an ellipse then it's not a bigger ellipse, but a
shape fatter than an ellipse.

The C<FillArc> plus C<PolyArc> combination ends up drawing some pixels
twice, which is no good for an "XOR" gc operation.  Currently that doesn't
affect C<Image::Base::X11::Protocol::Drawable>, but if there was a user
supplied C<-gc> then more care might be wanted.  At worst the base
C<Image::Base> code could be left to handle it all, or draw onto a temporary
bitmap to make a mask of desired pixels, or something like that.

C<diamond()> uses C<PolyLine> and C<FillPoly> in similar ways to the ellipse
above.  The C<FillPoly> has the same 1/2 pixel inside as the C<FillArc> and
so a filled diamond is a C<PolyLine> on top of a C<FillPoly>.

=head1 BUGS

The pixel values for each colour used for drawing are cached for later
re-use.  This is highly desirable to avoid a server round-trip on every
drawing operation, but if you use a lot of different shades then the cache
may become big.  Perhaps some sort of least recently used discard could keep
a lid on it.  Perhaps the colour-to-pixel hash or some such attribute could
be exposed so it could be both initialized, manipulated, or set to some tied
LRU hash etc as desired.

=head1 SEE ALSO

L<Image::Base>,
L<Image::Base::X11::Protocol::Pixmap>,
L<Image::Base::X11::Protocol::Window>,
L<X11::Protocol>,
L<Image::Base::Multiplex>

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

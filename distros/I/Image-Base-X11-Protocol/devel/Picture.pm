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
# /usr/share/doc/x11proto-render-dev/renderproto.txt.gz
# /usr/include/X11/extensions/renderproto.h
# X11::Protocol::Ext::RENDER
#

package Image::Base::X11::Protocol::Picture;
use 5.004;
use strict;
use Carp;
use X11::Protocol 0.56; # version 0.56 for robust_req() fix
use X11::Protocol::Other 3;  # v.3 for hexstr_to_rgb()
use vars '@ISA', '$VERSION';

use Image::Base;
@ISA = ('Image::Base');

$VERSION = 15;

# uncomment this to run the ### lines
#use Devel::Comments '###';

sub new {
  my $class = shift;
  if (ref $class) {
    croak "Cannot clone base picture";
  }
  return bless {
                # these not documented as yet
                -colour_to_rgba => {  },
                @_ }, $class;
}

# sub _get {
#   my ($self, $key) = @_;
#   ### X11-Protocol-Picture _get(): $key
# 
#   return $self->SUPER::_get($key);
# }

sub set {
  my ($self, %params) = @_;

  if (exists $params{'-colormap'}) {
    %{$self->{'-colour_to_rgba'}} = ();  # clear
  }
  %$self = (%$self, %params);
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### xy
  ### $x
  ### $y
  ### $colour
  my $X = $self->{'-X'};
  my $picture = $self->{'-picture'};
  if (@_ == 4) {
    if ($x >= 0 && $y >= 0
        && $x <= 0x7FFF && $y <= 0x7FFF) {  # don't overflow INT16 request
      $self->{'-X'}->RenderFillRectangles
        ('Src', $self->{'-picture'},
         $self->colour_to_rgbaref($colour),
         [ $x, $y, 1, 1 ]);
    }
  } else {
    # no pixel querying through picture
    return undef;
  }
}
sub Image_Base_Other_xy_points {
  my $self = shift;
  my $colour = shift;
  my $gc = _gc_colour($self,$colour);
  my $X = $self->{'-X'};

  my $maxrects = int (($X->{'maximum_request_length'} - 7) / 2);
  while (@_) {
    my @rects;
    while (@_ && @rects < $maxrects) {
      push @rects, [shift,shift,1,1];
    }
    $X->RenderFillRectangles ('Src', $self->{'-picture'}, @rects);
  }
}

sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### X11-Protocol-Picture line()
  if ($x1 == $x1 || $y1 == $y2) {
    # 1xN vertical or Nx1 horizontal
    $self->{'-X'}->RenderFillRectangles
      ('Src', $self->{'-picture'},
       $self->colour_to_rgbaref($colour),
       [ $x1, $y1, $x2-$x1+1, $y2-$y1+1 ]);
  } else {
    shift->SUPER::line (@_);
  }
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### X11-Protocol-Picture rectangle

  # clip to 0 .. 2^15-1 possible maximum drawable, no need to find out the
  # actual size
  ($x2 >= 0 && $y2 >= 0 && $x1 <= 0x7FFF && $y1 <= 0x7FFF)
    or return;

  # don't underflow INT16 -0x8000 x,y in request
  if ($x1 < 0) { $x1 = 0; }
  if ($y1 < 0) { $y1 = 0; }

  # don't overflow CARD16 width,height in request
  if ($x2 > 0x7FFF) { $x2 = 0x7FFF; }
  if ($y2 > 0x7FFF) { $y2 = 0x7FFF; }

  my @rects;
  if (! $fill && $y2-$y1 >= 2) {
    # unfilled, line segments
    @rects = ([ $x1, $y1, $x2-$x1+1, 1 ],   # top
              [ $x1,$y1+1, 1, $y2-$y1-1 ],  # left
              [ $x2,$y1+1, 1, $y2-$y1-1 ]); # right
    $y1 = $y2;
  }
  $self->{'-X'}->RenderFillRectangles
    ('Src', $self->{'-picture'},
     $self->colour_to_rgbaref($colour),
     @rects,
     [ $x1, $y1, $x2-$x1+1, $y2-$y1+1 ]);  # fill or bottom
}

sub Image_Base_Other_rectangles {
  ### X11-Protocol-Picture rectangles()
  ### count: scalar(@_)
  my $self   = shift;
  my $colour = shift;
  my $fill   = shift;  # 0 or 1

  # RenderFillRectangles is 7xCARD32 header,op,picture,rgba then room for
  # maxlen-7 groups of X,Y,WIDTH,HEIGHT.  X,Y are INT16 and WIDTH,HEIGHT are
  # CARD16 each, hence room for floor((maxlen-7)/2) rectangles.  Is there
  # any value sending somewhat smaller chunks though?  250kbytes is a
  # typical server limit.  Xlib ZRCTSPERBATCH is just 256 thin line rects,
  # or WRCTSPERBATCH 10 wides.
  #
  my $maxrects = int (($X->{'maximum_request_length'} - 7) / 2)
    - 3;  # for unfilled extras
  ### $maxrects

  my $X = $self->{'-X'};
  my $picture = $self->{'-picture'};
  my $rgba = $self->colour_to_rgbaref ($colour);
  while (@_) {
    my @rects;
    while (@_ && @rects < $maxrects) {
      my $x1 = shift;
      my $y1 = shift;
      my $x2 = shift;
      my $y2 = shift;

      if (! $fill && $y2-$y1 >= 2) {
        push @rects, ([ $x1, $y1, $x2-$x1+1, 1 ],   # top
                      [ $x1,$y1+1, 1, $y2-$y1-1 ],  # left
                      [ $x2,$y1+1, 1, $y2-$y1-1 ]); # right
        $y1 = $y2;
      }
      push @rects, [ $x1, $y1, $x2-$x1+1, $y2-$y1+1 ];  # fill or bottom
    }
    $X->RenderFillRectangles ('Src', $picture, $rgba, @rects);
  }
  ### @rects
}

# with triangles ?
#
# sub diamond {
#   my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
#   ### Picture diamond(): $x1, $y1, $x2, $y2, $colour
# 
#   my $X = $self->{'-X'};
#   my $picture = $self->{'-picture'};
# 
# }

# return [r,g,b,a]
# not yet a documented feature ...
sub colour_to_rgbaref {
  my ($self, $colour) = @_;
  ### X11-Protocol-Picture _colour_to_rgba(): $colour
  if ($colour eq 'set' || $colour eq 'white') {
    # ENHANCE-ME: maybe all bits set if depth > 1
    return [ 255,255,255, 255 ];
  }
  if ($colour eq 'clear' || $colour eq 'black') {
    return [ 0,0,0,  255 ];
  }
  if (my @rgb = X11::Protocol::Other::hexstr_to_rgb($colour)) {
    return @rgb;
  }
  if (defined (my $pixel = $self->{'-colour_to_rgba'}->{$colour})) {
    return $pixel;
  }
  $self->add_colours ($colour);
  return $self->{'-colour_to_rgba'}->{$colour};
}

sub add_colours {
  my $self = shift;
  ### add_colours: @_
  my $X = $self->{'-X'};
  my $colormap = $self->get('-colormap')
    || croak 'No -colormap to add colours to';
  my $colour_to_rgba = $self->{'-colour_to_rgba'};

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

    ### reply: $X->unpack_reply('LookupColor', $elem->{'reply'})

    my ($pixel,
        $exact_red, $exact_green, $exact_blue,
        $visual_red, $visual_green, $visual_blue) = $X->unpack_reply ('LookupColor', $elem->{'reply'});
    $colour_to_rgba->{$colour} = [ $visual_red, $visual_green, $visual_blue,
                                   255 ];
  };

  while (@_) {
    my $colour = shift;
    next if defined $colour_to_rgba->{$colour};  # already known

    my $elem = { colour => $colour };
    my $seq = $elem->{'seq'} = $X->send('LookupColor', $colormap, $colour);
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

1;
__END__

=for stopwords undef Ryde pixmap pixmaps colormap ie XID GC PseudoColor lookups
TrueColor RGB pictures gc

=head1 NAME

Image::Base::X11::Protocol::Picture -- draw into an X11::Protocol render picture

=for test_synopsis my ($xid, $colormap)

=head1 SYNOPSIS

 use Image::Base::X11::Protocol::Picture;
 my $X = X11::Protocol->new;

 my $image = Image::Base::X11::Protocol::Picture->new
               (-X        => $X,
                -picture  => $xid,
                -colormap => $colormap);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::X11::Protocol::Picture> is a subclass of
C<Image::Base>,

    Image::Base
      Image::Base::X11::Protocol::Picture

=head1 DESCRIPTION

C<Image::Base::X11::Protocol::Picture> extends C<Image::Base> to draw into X
"RENDER" extension pictures by sending drawing requests to an X server with
C<X11::Protocol>.  There's no file load or save, just drawing operations.

Native X drawing does more than C<Image::Base> but if you have some generic
pixel twiddling code for C<Image::Base> then this module lets you point it
at a render picture.

=head2 Colour Names

Colour names are the server's colour names per C<AllocNamedColor> plus
hexadecimal RGB, and set/clear for bitmaps or monochrome windows,

    LookupColor        usually server's /etc/X11/rgb.txt    
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

=over 4

=item C<$image = Image::Base::X11::Protocol::Picture-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  This requires an C<X11::Protocol>
connection object and a picture XID (an integer).

    my $image = Image::Base::X11::Protocol::Picture->new
                  (-X        => $x11_protocol_obj,
                   -picture  => $picture_xid);

=cut

=item C<$colour = $image-E<gt>xy ($x, $y)>

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set the pixel at C<$x>,C<$y>.

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

=back

=head1 ATTRIBUTES

=over

=item C<-picture> (integer XID)

The target picture.

=item C<-width> (integer, read-only)

=item C<-height> (integer, read-only)

Width and height ...

=back

=head1 SEE ALSO

L<Image::Base>,
L<X11::Protocol::Ext::RENDER>

=cut

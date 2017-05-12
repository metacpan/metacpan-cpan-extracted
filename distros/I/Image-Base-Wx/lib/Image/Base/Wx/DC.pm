# Copyright 2011, 2012 Kevin Ryde

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

package Image::Base::Wx::DC;
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
  ### Wx-DC new(): %params

  if (ref $class) {
    die 'Cannot clone Image::Base::Wx::DC';
  }
  my $self = bless { _pen_colour => '',
                     _brush_colour => '',
                   }, $class;
  $self->set (%params);
  return $self;
}

my %attr_to_get_method = (-width  => sub { ($_[0]->GetSizeWH)[0] },
                          -height => sub { ($_[0]->GetSizeWH)[1] },
                         );
sub _get {
  my ($self, $key) = @_;

  if (my $method = $attr_to_get_method{$key}) {
    return $self->{'-dc'}->$method();
  }
  return $self->SUPER::_get($key);
}

sub set {
  my ($self, %params) = @_;
  ### Image-Base-Wx-DC set: \%params

  foreach my $key ('-width','-height') {
    if (exists $params{$key}) {
      croak "Attribute $key is read-only";
    }
  }

  if (exists $params{'-dc'}) {
    $params{'_pen_colour'} = '';
    $params{'_brush_colour'} = '';

    ### dc pen apply CAP_PROJECTING ...
    my $dc = $params{'-dc'};
    my $pen = $dc->GetPen;
    $pen->SetCap(Wx::wxCAP_PROJECTING());
    $dc->SetPen($pen);
  }

  %$self = (%$self, %params);
  ### set leaves: $self
}

#------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;
  my $dc = $self->{'-dc'};
  if (@_ >= 4) {
    ### Image-DC xy: "$x, $y, $colour"
    _dc_pen($self,$colour)->DrawPoint ($x, $y);
  } else {
    ### Image-DC xy() fetch: "$x, $y"
    my $c = $self->{'-dc'}->GetPixel ($x,$y);
    ### $c
    ### c str: $c->GetAsString(4)
    return ($c && $c->GetAsString(Wx::wxC2S_HTML_SYNTAX()));
  }
}

# sub Image_Base_Other_xy_points {
#   my $self = shift;
#   my $colour = shift;
#   ### Image_Base_Other_xy_points $colour
#   ### len: scalar(@_)
#   @_ or return;
# 
#   ### dc: $self->{'-dc'}
#   ### brush: $self->brush_for_colour($colour)
#   unshift @_, $self->{'-dc'}, $self->brush_for_colour($colour);
#   ### len: scalar(@_)
#   ### $_[0]
#   ### $_[1]
# 
#   # shift/unshift changes the first two args from self,colour to dc,brush
#   # does that save stack copying?
#   my $code = $self->{'-dc'}->can('draw_points');
#   goto &$code;
# 
#   # the plain equivalent ...
#   # $self->{'-dc'}->draw_points ($self->brush_for_colour($colour), @_);
# }

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour) = @_;
  ### Image-DC line()

  # 1x1 DrawLine() draws nothing, so use DrawPoint() for that
  my $dc = _dc_pen($self,$colour);
  if ($x1 == $x2 && $y1 == $y2) {
    $dc->DrawPoint ($x1, $y1);
  } else {
    $dc->DrawLine ($x1,$y1, $x2,$y2);
  }
}

# $x1==$x2 and $y1==$y2 on $fill==false may or may not draw that x,y point
# outline with brush line_width==0
    # or alternately $dc->draw_point ($brush, $x1,$y1);
#
sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  # ### Image-DC rectangle: "$x1, $y1, $x2, $y2, $colour, $fill"

  # Under msdos a 1x1 rectangle seems to draw no pixels, neither for filled
  # or unfilled.  Try DrawPoint() for that case.
  if ($x1==$x2 && $y1==$y2) {
    _dc_pen($self,$colour)->DrawPoint ($x1, $y1);
  } else {
    _dc_fill($self,$colour,$fill)->DrawRectangle ($x1, $y1,
                                                  $x2-$x1+1, $y2-$y1+1);
  }
}

my $ellipse_x_extra = 0;
my $ellipse_y_extra = 0;
# {
#   my $wxbitmap = Wx::Bitmap->new(20,10);
#   my $dc = Wx::MemoryDC->new;
#   $dc->SelectObject($wxbitmap);
#   {
#     my $pen = $dc->GetPen;
#     my $colour_obj = Wx::Colour->new('#FF00FF');
#     $colour_obj->IsOk or die;
#     $pen->SetColour($colour_obj);
#     $dc->SetPen($pen);
#   }
#   for ($ellipse_x_extra = -3; $ellipse_x_extra <= 2; $ellipse_x_extra++) {
#     $dc->DrawEllipse(0,0, 6+$ellipse_x_extra, 6+$ellipse_y_extra);
#     my $colour_obj = $dc->GetPixel(5,2);
#     if ($colour_obj->GetAsString(Wx::wxC2S_HTML_SYNTAX()) eq '#FF00FF') {
#       last;
#     }
#   }
#   for ($ellipse_y_extra = -3; $ellipse_y_extra <= 2; $ellipse_y_extra++) {
#     $dc->DrawEllipse(0,0, 6+$ellipse_x_extra, 6+$ellipse_y_extra);
#     my $colour_obj = $dc->GetPixel(2,5);
#     if ($colour_obj->GetAsString(Wx::wxC2S_HTML_SYNTAX()) eq '#FF00FF') {
#       last;
#     }
#   }
# }
### $ellipse_x_extra
### $ellipse_y_extra

sub ellipse {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-DC ellipse: "$x1, $y1, $x2, $y2, $colour, ".($fill||0)

  # Something fishy happens when width=0 or height=0 to DrawEllipse() where
  # the last pixel is not drawn.  Might be the usual X11 left/above rule, or
  # wx not coping with that rule.  In any case Nx1 and 1xN done as
  # rectangle() (and it in turn handles 1x1 case).
  #
  my $w = $x2-$x1;
  my $h = $y2-$y1;
  if ($w == 0 || $h == 0) {
    $self->rectangle ($x1,$y1, $x2,$y2, $colour, 1);
  } else {
    _dc_fill($self,$colour,$fill)->DrawEllipse ($x1,$y1,
                                                $w + $ellipse_x_extra,
                                                $h + $ellipse_y_extra);
  }
}

sub diamond {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-DC diamond: "$x1, $y1, $x2, $y2, $colour, ".($fill||0)

  if ($x1==$x2 && $y1==$y2) {
    # Under msdos a polygon with all points the same seems to draw no pixels.
    # Try DrawPoint() instead.
    _dc_pen($self,$colour)->DrawPoint ($x1, $y1);
    return;
  }

  my $xh = ($x2 - $x1);
  my $yh = ($y2 - $y1);
  my $xeven = ($xh & 1);
  my $yeven = ($yh & 1);
  $xh = int($xh / 2);
  $yh = int($yh / 2);
  ### assert: $x1+$xh+$xeven == $x2-$xh
  ### assert: $y1+$yh+$yeven == $y2-$yh

  _dc_fill($self,$colour,$fill)->DrawPolygon
    ([
      Wx::Point->new($x1+$xh, $y1),  # top centre

      # left
      Wx::Point->new($x1, $y1+$yh),
      ($yeven ? Wx::Point->new($x1, $y2-$yh) : ()),

      # bottom
      Wx::Point->new($x1+$xh, $y2),
      ($xeven ? Wx::Point->new($x2-$xh, $y2) : ()),

      # right
      ($yeven ? Wx::Point->new($x2, $y2-$yh) : ()),
      Wx::Point->new($x2, $y1+$yh),

      ($xeven ? Wx::Point->new($x2-$xh, $y1) : ()),
      Wx::Point->new($x1+$xh, $y1),  # back to start
     ],
     0,0);
}

#------------------------------------------------------------------------------
# colours

sub _dc_fill {
  my ($self, $colour, $fill) = @_;

  my $dc = _dc_pen($self,$colour);
  if ($fill) {
    if ($colour ne $self->{'_brush_colour'}) {
      ### _dc_fill() change brush: $colour, $fill

      my $brush = $dc->GetBrush;
      $brush->SetColour(Wx::Colour->new($colour));
      $brush->SetStyle (Wx::wxSOLID());
      $dc->SetBrush($brush);

      $self->{'_brush_colour'} = $colour;
    }
  } else {
    if ($self->{'_brush_colour'} ne 'None') {
      ### _dc_fill() change brush transparent ...

      # or ...
      # $dc->SetBrush (Wx::wxTRANSPARENT_BRUSH());

      my $brush = $dc->GetBrush;
      $brush->SetStyle (Wx::wxTRANSPARENT());
      $dc->SetBrush($brush);

      $self->{'_brush_colour'} = 'None';
    }
  }
  return $dc;
}

sub _dc_pen {
  my ($self, $colour) = @_;
  my $dc = $self->{'-dc'};
  if ($colour ne $self->{'_pen_colour'}) {
    ### _dc_pen() change: $colour

    my $pen = $dc->GetPen;
    my $colour_obj = Wx::Colour->new($colour);
    $colour_obj->IsOk
      or croak "Unrecognised colour ",$colour;
    $pen->SetColour($colour_obj);
    $dc->SetPen($pen);

    $self->{'_pen_colour'} = $colour;
  }
  return $dc;
}

1;
__END__

=for stopwords resized filename Ryde bitmap Image-Base-Wx-DC

=head1 NAME

Image::Base::Wx::DC -- draw into a Wx::DC

=for test_synopsis my $dc

=head1 SYNOPSIS

 use Image::Base::Wx::DC;
 my $image = Image::Base::Wx::DC->new
                 (-dc => $dc);
 $image->line (0,0, 99,99, '#FF00FF');
 $image->rectangle (10,10, 20,15, 'white');

=head1 CLASS HIERARCHY

C<Image::Base::Wx::DC> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Wx::DC

=head1 DESCRIPTION

C<Image::Base::Wx::DC> extends C<Image::Base> to draw into a
C<Wx::DC>.

Native C<Wx::DC> does much more than C<Image::Base> but if you have some
generic pixel twiddling code for C<Image::Base> then this class can point it
at Wx for a window or printer paint, etc.

See C<Image::Base::Wx::Bitmap> for a subclass drawing into C<Wx::Bitmap>
with file loading and saving too.

=head2 Colour Names

Colour names are anything recognised by C<< Wx::Colour->new() >>, which as
per its C<Set()> method means

    "pink"            names per wxColourDatabase
    "#RRGGBB"         2 digit hex
    "RGB(r,g,b)"      decimal 0 to 255

1,3 or 4 digit hex are platform dependent.  They work under Gtk, but not
under MS-Windows.

The colour is applied to the "pen" in the C<-dc>, and for filling to the
"brush" too.  The pen is also set to C<wxCAP_PROJECTING> to ensure the last
pixel is drawn for C<line()>.  That might be an artifact of the X11 pixel
rule "on the boundary above or left", but in any case gets the right effect.

If the colour etc in the C<-dc> is changed elsewhere then what
C<Image::Base::Wx::DC> thinks it has set will be invalid.  Set C<-dc> into
the C<$image> again to reset.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::Wx::DC-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A C<-dc> parameter must be
given,

    $image = Image::Base::Wx::DC->new
                 (-dc => $dc);

Further parameters are applied per C<set> (see L</ATTRIBUTES> below).

=item C<$image-E<gt>xy ($x, $y, $colour)>

Get or set the pixel at C<$x>,C<$y>.

Getting a pixel is per C<Wx::DC> C<GetPixel()>.  In the current code colours
are returned in "#RRGGBB" form (C<wxC2S_HTML_SYNTAX> of C<Wx::Colour>).

=back

=head1 ATTRIBUTES

=over

=item C<-dc> (C<Wx::DC> object)

The target dc.

=item C<-width>, C<-height> (read-only)

The size of the DC's target, as per C<$dc-E<gt>GetSize()>.

=back

=head1 SEE ALSO

L<Wx>,
L<Image::Base>,
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

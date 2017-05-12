# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Dashes;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util qw(min max);
use POSIX ();

# uncomment this to run the commented-out ### lines
#use Smart::Comments;

our $VERSION = 2;

use Glib::Object::Subclass
  'Gtk2::Misc',
  signals => { size_request      => \&_do_size_request,
               expose_event      => \&_do_expose_event,
               style_set         => \&_do_style_or_direction,
               direction_changed => \&_do_style_or_direction,
             },
  properties => [ Glib::ParamSpec->enum
                  ('orientation',
                   'orientation',
                   'Horizontal or vertical line draw.',
                   'Gtk2::Orientation',
                   'horizontal',
                   Glib::G_PARAM_READWRITE),
                ];

# Multiplied by $widget->style->ythickness.
# For default theme thickness 2 pixels this gives dash segments 5 pixels
# same as Gtk2::TearoffMenuItem.
use constant _DASH_FACTOR => 2.5;

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_flags('no-window');
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->get($pname);
  $self->{$pname} = $newval;

  # if ($pname eq 'orientation')   # the only property
  #
  if ($oldval ne $newval) {
    $self->queue_resize;
    $self->queue_draw;
  }
}

# 'size-request' class closure
sub _do_size_request {
  my ($self, $req) = @_;

  my ($width, $height) = $self->get_padding;
  $width *= 2;
  $height *= 2;
  if ($self->get('orientation') eq 'horizontal') {
    $height += $self->style->ythickness;
  } else {
    $width += $self->style->xthickness;
  }
  ### size_request: "$width x $height"
  $req->width ($width);
  $req->height ($height);
}

sub _do_expose_event {
  my ($self, $event) = @_;
  my $clip = $event->area;  # Gtk2::Gdk::Rectangle
  ### expose: $self->get_name, $clip->values

  my $horizontal = ($self->get('orientation') eq 'horizontal');
  my $style      = $self->style;
  my $state      = $self->state;
  my $win        = $self->window;
  my $thickness  = ($horizontal ? $style->ythickness : $style->xthickness);
  my $dash_len   = POSIX::ceil (_DASH_FACTOR * $thickness);
  ### $dash_len
  my $dash_step  = 2 * $dash_len;

  my ($alloc_x, $alloc_y, $alloc_width, $alloc_height)
    = $self->allocation->values;  # Gtk2::Gdk::Rectangle
  ### alloc: "$alloc_x,$alloc_y ${alloc_width}x$alloc_height"

  my ($xalign, $yalign) = $self->get_alignment;
  if ($self->get_direction eq 'rtl') { $xalign = 1 - $xalign; }
  ### align: $xalign, $yalign

  {
    my ($xpad, $ypad) = $self->get_padding;
    ### padding: $xpad, $ypad
    if ($xpad || $ypad) {
      # apply padding by pretending allocation is that much smaller
      ### rect shrink from: $clip->values

      $alloc_x += $xpad;
      $alloc_y += $ypad;
      if (($alloc_width -= 2*$xpad) <= 0
          || ($alloc_height -= 2*$ypad) <= 0
          || ! ($clip = $clip->intersect (Gtk2::Gdk::Rectangle->new
                                          ($alloc_x, $alloc_y,
                                           $alloc_width, $alloc_height)))) {
        ### expose of the pad border region, or allocation smaller than padding
        ### nothing to draw
        return 0; # Gtk2::EVENT_PROPAGATE
      }
      ### to: $clip->values
    }
  }

  if ($horizontal) {
    my $clip_x = $clip->x;

    # vertically according to yalign
    my $y = $alloc_y + POSIX::floor
      (($alloc_height - $thickness) * $yalign
       + 0.5); # round
    ### $y

    # ENHANCE-ME: if $y puts the line entirely above or below the clip
    # region then skip the loop.  What can be assumed about how $ythickness
    # affects how much above and below $y the paint_hline() will go?

    # horizontal beginning according to xalign
    my $x = $clip_x
      + ((POSIX::floor (($alloc_width - $dash_len)  * $xalign
                        + 0.5) # round
          + $alloc_x
          - $clip_x)
         % -$dash_step); # at or just before $clip_x
    ### $x

    my $end = $clip_x + $clip->width; # clip rect
    for ( ; $x < $end; $x += $dash_step) {
      $style->paint_hline ($win, $state, $clip, $self, __PACKAGE__,
                           $x, $x+$dash_len, $y);
    }
  } else {
    my $clip_y = $clip->y;

    # horizontally according to xalign
    my $x = $alloc_x + POSIX::floor
      (($alloc_width - $thickness) * $xalign
       + 0.5); # round

    # vertical beginning according to yalign
    my $y = $clip_y
      + ((POSIX::floor (($alloc_height - $dash_len)  * $yalign
                        + 0.5) # round
          + $alloc_y
          - $clip_y)
         % -$dash_step); # at or just before $clip_y

    my $end = $clip_y + $clip->height; # clip rect
    for ( ; $y < $end; $y += $dash_step) {
      $style->paint_vline ($win, $state, $clip, $self, __PACKAGE__,
                           $y, $y+$dash_len, $x);
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'style-set' and 'direction-changed' class closure handler
# Sharing style-set and direction-changed saves a little code.
#
# queue_resize() is not wanted for direction-changed, but does no harm.  As
# of Gtk 2.18 the GtkWidget code in gtk_widget_real_direction_changed()
# (previously gtk_widget_direction_changed()) in fact does a queue_resize()
# itself.  Could avoid it by not chaining up, but perhaps GtkWidget will do
# something important there in the future.  Either way a direction change
# should be infrequent so it doesn't matter much.
#
sub _do_style_or_direction {
  my ($self) = @_;
  ### Dashes _do_style_or_direction(): @_
  $self->queue_resize;
  $self->queue_draw;
  return shift->signal_chain_from_overridden(@_);
}

1;
__END__

=head1 NAME

Gtk2::Ex::Dashes -- widget displaying row of dashes

=head1 SYNOPSIS

 use Gtk2::Ex::Dashes;
 my $dashes = Gtk2::Ex::Dashes->new;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Dashes> is a subclass of C<Gtk2::Misc>.

    Gtk2::Widget
      Gtk2::Misc
        Gtk2::Ex::Dashes

=head1 DESCRIPTION

A C<Gtk2::Ex::Dashes> widget displays a line of dashes, either horizontally
or vertically.

    +--------------------------------+
    |                                |
    |  ====  ====  ====  ====  ====  |
    |                                |
    +--------------------------------+

It's similar to C<Gtk2::Separator>, but a dashed line, and the
C<Gtk2::Ex::Dashes::MenuItem> subclass is similar to
C<Gtk2::TearoffMenuItem>, but a plain item not driving the menu.

Line segments are drawn per the widget style (see L<Gtk2::Style>) and
positioned in the widget area per the C<Gtk2::Misc> properties described
below.  There's nothing to control the length and spacing of the line
segments, currently they just scale with the line thickness to keep the
display sensible.

=head1 FUNCTIONS

=over 4

=item C<< $dashes = Gtk2::Ex::Dashes->new (key=>value,...) >>

Create and return a new Dashes widget.  Optional key/value pairs can be given
to set initial properties, as per C<< Glib::Object->new >>.

    my $dashes = Gtk2::Ex::Dashes->new
                   (xalign => 0, direction => 'vertical');

=back

=head1 PROPERTIES

=over 4

=item C<orientation> (C<Gtk2::Orientation> enum, default "horizontal")

Whether to draw a horizontal line or a vertical line.

=item C<xalign> (float, default 0.5)

=item C<yalign> (float, default 0.5)

These C<Gtk2::Misc> properties control positioning of the line within its
allocated area.  The default 0.5 means centre it.

C<xalign> for a horizontal line can be thought of as positioning one dash
segment somewhere between the left and right ends, and then then further
segments drawn each way from there to fill the window.  Similarly C<yalign>
when vertical.

If the widget text direction (see C<set_direction> in L<Gtk2::Widget>) is
C<rtl> then the sense of C<xalign> is reversed, so 0 means the right edge
instead of the left.

=back

=head1 SEE ALSO

L<Gtk2::Ex::Dashes::MenuItem>,
L<Gtk2::Misc>, L<Gtk2::Separator>, L<Gtk2::TearoffMenuItem>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-dashes/index.html>

=head1 LICENSE

Gtk2-Ex-Dashes is Copyright 2010 Kevin Ryde

Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Dashes.  If not, see L<http://www.gnu.org/licenses/>.

=cut

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::QuadButton;
use 5.008;
use strict;
use warnings;
use List::Util 'min', 'max';
use Gtk2 1.220;
use Gtk2::Ex::WidgetBits 40; # v.40 for pixel_size_mm()
use Gtk2::Ex::Units 13; # initial v.13

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 1;

use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  signals => { size_request        => \&_do_size_request,
               expose_event        => \&_do_expose,
               style_set           => \&_do_style_set,
               hierarchy_changed   => \&_do_hierarchy_changed,
               motion_notify_event => \&_do_motion_or_enter,
               enter_notify_event  => \&_do_motion_or_enter,
               leave_notify_event  => \&_do_leave_notify,
               button_press_event  => \&_do_button_press,
               scroll_event        => \&_do_scroll_event,
               clicked => { param_types => [ 'Gtk2::ScrollType' ],
                            flags => ['run-first','action'],
                          },
               # GtkWidget "direction-changed" does a queue_draw() which is
               # enough for the xalign "rtl" bit
             },
  properties => [
                 Glib::ParamSpec->double
                 ('xalign',
                  (do {
                    my $str = 'Horizontal alignment';
                    eval { require Locale::Messages;
                           Locale::Messages::dgettext('gtk20-properties',$str)
                           } || $str }),
                  'Blurb.',
                  0, 1.0, # min,max
                  0.5,    # default
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->double
                 ('yalign',
                  (do {
                    my $str = 'Vertical alignment';
                    eval { require Locale::Messages;
                           Locale::Messages::dgettext('gtk20-properties',$str)
                           } || $str }),
                  'Blurb.',
                  0, 1.0, # min,max
                  0.5,    # default
                  Glib::G_PARAM_READWRITE),
                ];

# priority level "gtk" treating this as widget level default, for overriding
# by application or user RC
Gtk2::Rc->parse_string (<<'HERE');
binding "Gtk2__Ex__QuadButton_keys" {
  bind "Up"          { "clicked" (step-up) }
  bind "Down"        { "clicked" (step-down) }
  bind "<Ctrl>Up"    { "clicked" (page-up) }
  bind "<Ctrl>Down"  { "clicked" (page-down) }
  bind "Left"        { "clicked" (step-left) }
  bind "Right"       { "clicked" (step-right) }
  bind "<Ctrl>Left"  { "clicked" (page-left) }
  bind "<Ctrl>Right" { "clicked" (page-right) }
  bind "Page_Up"     { "clicked" (page-up) }
  bind "Page_Down"   { "clicked" (page-down) }
}
class "Gtk2__Ex__QuadButton" binding:gtk "Gtk2__Ex__QuadButton_keys"
HERE

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'drawn_dir'} = '';
  $self->can_focus(1);
  $self->add_events (['button-press-mask',
                      'pointer-motion-mask',
                      'enter-notify-mask',
                      'leave-notify-mask']);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  ### Enum SET_PROPERTY: $pname, $newval

  # xalign,yalign
  $self->queue_draw;
}

# 'size-request' class handler
sub _do_size_request {
  my ($self, $req) = @_;
  ### QuadButton _do_size_request(): @_
  my $size = max (5, 2.2 * Gtk2::Ex::Units::em($self));
  $req->width (int ($size + .5));
  if (defined (my $ratio = Gtk2::Ex::WidgetBits::pixel_aspect_ratio($self))) {
    # ratio = pixwidth/pixheight
    $size /= $ratio;
  }
  $req->height (int ($size + .5));
}

# 'style-set' class handler
sub _do_style_set {
  my ($self) = @_;
  ### QuadButton _do_style_set(): @_
  shift->signal_chain_from_overridden(@_);

  $self->queue_draw;    # new colours
  $self->queue_resize;  # size request in new font
}

# 'hierarchy-changed' class handler
sub _do_hierarchy_changed {
  my ($self) = @_;
  ### QuadButton _do_hierarchy_changed(): @_
  shift->signal_chain_from_overridden(@_);

  $self->queue_resize;  # size request new aspect ratio
}

sub _use_rect {
  my ($self) = @_;
  my (undef,undef, $width, $height) = $self->allocation->values;
  my ($xsize,$ysize);
  my $ratio = Gtk2::Ex::WidgetBits::pixel_aspect_ratio($self);  # width/height
  ### $ratio
  my $width_from_height = int ($height * $ratio + .5);
  if ($width >= $width_from_height) {
    $xsize = $width_from_height;
    $ysize = $height;
  } else {
    $xsize = $width;
    $ysize = min ($height, int ($width / $ratio + .5));
  }
  ### xsize/ysize: $xsize/$ysize
  my $xalign = $self->get('xalign');
  if ($self->get_direction eq 'rtl') {
    $xalign = 1 - $xalign;
  }
  return (int (($width - $xsize) * $xalign + .5),
          int (($height - $ysize) * $self->get('yalign') + .5),
          $xsize,
          $ysize);
}

sub _do_expose {
  my ($self, $event) = @_;
  ### QuadButton _do_expose()

  my $win = $self->window;
  my $state = $self->state;
  my $style = $self->get_style;
  my (undef,undef, $width, $height) = $self->allocation->values;
  my ($xpos,$ypos,$xsize,$ysize) = _use_rect($self);

  my $dir = _xy_to_direction ($self, $self->{'x'}, $self->{'y'},
                              $xpos,$ypos,$xsize,$ysize);
  $self->{'drawn_dir'} = $dir;

  ### $dir
  ### $state
  ### fg: $self->style->fg($state)->to_string, $self->style->fg('prelight')->to_string
  ### bg: $self->style->bg($state)->to_string, $self->style->bg('prelight')->to_string
  ### $xpos
  ### $ypos

  my $xc = $xpos + int($xsize/2);
  my $yc = $ypos + int($ysize/2);

  # clear background
  {
    my $gc = $style->bg_gc($state);
    foreach my $rect ($event->region->get_rectangles) {
      $win->draw_rectangle ($gc,
                            1, # filled
                            $rect->values);
    }
  }

  # prelight background for armed direction
  if ($dir) {
    my @points_bg = (0,0,                 # top left
                     ($dir eq 'up' || $dir eq 'down'
                      ? ($xsize-1,0)       # top right
                      : (0,$ysize-1)),     # bottom left
                     $xsize/2,$ysize/2,  # centre
                     0,0);               # top left again
    if ($dir eq 'down') {
      for (my $i = 1; $i < @points_bg; $i+=2) {
        $points_bg[$i] = $ysize-1-$points_bg[$i]; # invert
      }
    }
    if ($dir eq 'right') {
      for (my $i = 0; $i < @points_bg; $i+=2) {
        $points_bg[$i] = $xsize-1-$points_bg[$i]; # mirror
      }
    }
    for (my $i = 0; $i < @points_bg; $i+=2) {
      $points_bg[$i] += $xpos;
      $points_bg[$i+1] += $ypos;
    }
    my $gc = $style->bg_gc('prelight');
    $gc->set_clip_region ($event->region);
    ### prelight bg: @points_bg
    ### $gc
    $win->draw_polygon ($gc, 0, @points_bg);
    $win->draw_polygon ($gc, 1, @points_bg);
    $gc->set_clip_region (undef);
  }

  my $xmid = $xc - int(.28 * $xsize);
  my $ymid = $yc - int(.28 * $ysize);
  my $xbase_size = int(.2 * $xsize);
  my $ybase_size = int(.2 * $ysize);
  my $xshaft_size = max(1,int($xsize*.05));
  my $yshaft_size = max(1,int($ysize*.05));
  my $xshaft = $xc - $xshaft_size;
  my $yshaft = $yc - $yshaft_size;
  my $xshaft_end = $xc - $yshaft_size;
  my $yshaft_end = $yc - $xshaft_size;
  ### $xshaft_size
  ### $yshaft_size

  my $gc = Gtk2::Gdk::GC->new ($win);
  my $copied_gc = 0;

  # up/down arrows
  {
    # up arrow
    my @points_fg = ($xc, $ypos,                       # top centre
                     $xc - $xbase_size, $ymid,         # base left
                     $xc - $xshaft_size, $ymid,
                     $xc - $xshaft_size, $yshaft_end,  # shaft end
                     $xc + $xshaft_size, $yshaft_end,  # shaft end
                     $xc + $xshaft_size, $ymid,
                     $xc + $xbase_size, $ymid,         # base right
                     $xpos+int(($xsize+1)/2), $ypos,   # top centre, rounded
                     $xc, $ypos);                      # top centre again

    my $this_dir = 'up';
    foreach (0, 1) {
      {
        my $want_gc = $style->fg_gc($dir eq $this_dir ? 'prelight' : $state);
        if ($want_gc != $copied_gc) {
          $copied_gc = $want_gc;
          $gc->copy($want_gc);
          $gc->set_clip_region ($event->region);
          # line width 1 to have the outline pixels correct
          $gc->set_line_attributes (1,'solid','butt','miter');
          ### copy gc: $dir eq $this_dir && $state
          ### copied fg: $copied_gc->get_values->{'foreground'}->pixel
        }
      }
      ### arrow fg: $gc->get_values->{'foreground'}->pixel
      $win->draw_polygon ($gc, 0, @points_fg);
      $win->draw_polygon ($gc, 1, @points_fg);

      # invert
      $this_dir = 'down';
      for (my $i = 1; $i < @points_fg; $i+=2) {
        $points_fg[$i] = $ypos+$ysize-1-($points_fg[$i]-$ypos);
      }
    }
  }

  # left/right arrows
  {
    # left
    my @points_fg = ($xpos,       $yc,                # left centre
                     $xmid,       $yc - $ybase_size,  # base upper
                     $xmid,       $yc - $yshaft_size,
                     $xshaft_end, $yc - $yshaft_size,   # shaft end
                     $xshaft_end, $yc + $yshaft_size,
                     $xmid,       $yc + $yshaft_size,
                     $xmid,       $yc + $ybase_size,   # base lower
                     $xpos,       $yc);
    my $this_dir = 'left';
    foreach (0, 1) {
      {
        my $want_gc = $style->fg_gc($dir eq $this_dir ? 'prelight' : $state);
        if ($want_gc != $copied_gc) {
          $copied_gc = $want_gc;
          $gc->copy($want_gc);
          $gc->set_clip_region ($event->region);
          # line width 1 to have the outline pixels correct
          $gc->set_line_attributes (1,'solid','butt','miter');
        }
      }
      $win->draw_polygon ($gc, 0, @points_fg);
      $win->draw_polygon ($gc, 1, @points_fg);

      # mirror left/right
      $this_dir = 'right';
      for (my $i = 0; $i < @points_fg; $i+=2) {
        $points_fg[$i] = $xpos+$xsize-1-($points_fg[$i]-$xpos);
      }
    }
  }

  # focus dashed line, if focused
  if ($self->has_focus) {
    $style->paint_focus ($win,   # window
                         $state,  # state
                         $event->area,
                         $self,        # widget
                         __PACKAGE__,  # detail
                         0,0,
                         $width,$height);
  }

  return Gtk2::EVENT_PROPAGATE;
}

#              x <= 1-y off diagonal is left or up
#              |      x > 1-y is down or right
#              |      |
my @table = ('left','down',    # x <= y so left or down
             'up',  'right');  # x > y so up or right

sub _xy_to_direction {
  my ($self, $x, $y, $xpos,$ypos,$xsize,$ysize) = @_;
  if (@_ < 4) {
    ($xpos,$ypos,$xsize,$ysize) = _use_rect($self);
  }
  if (defined $x && defined $y) {
    $x = ($x - $xpos) / $xsize;   # 0.0 to 1.0
    if ($x >= 0 && $x < 1) {
      $y = ($y - $ypos) / $ysize;   # 0.0 to 1.0
      if ($y >= 0 && $y < 1) {

        return $table[(($x>$y)<<1) + ($x > 1-$y)];
      }
    }
  }
  return '';
}

sub _do_motion_or_enter {
  my ($self, $event) = @_;
  my $x = $self->{'x'} = $event->x;
  my $y = $self->{'y'} = $event->y;
  if ($self->{'drawn_dir'} ne _xy_to_direction ($self, $x, $y)) {
    $self->queue_draw;
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _do_leave_notify {
  my ($self, $event) = @_;
  ### QuadButton _do_leave()
  undef $self->{'x'};
  undef $self->{'y'};
  if ($self->{'drawn_dir'}) {
    $self->queue_draw;
  }
  return Gtk2::EVENT_PROPAGATE;
}

my $modifiers_for_page
  = Gtk2::Gdk::ModifierType->new(['control-mask','shift-mask']);

sub _do_button_press {
  my ($self, $event) = @_;
  ### QuadButton _do_button_press(): $event->x.','.$event->y
  ### dir: _xy_to_direction ($self, $event->x, $event->y)

  if ($event->button == 1
      && (my $dir = _xy_to_direction ($self, $event->x, $event->y))) {
    $self->signal_emit ('clicked',
                        ($event->state & $modifiers_for_page
                         ? 'page-' : 'step-')
                        . $dir);
  }
  return $self->signal_chain_from_overridden ($event);
}

sub _do_scroll_event {
  my ($self, $event) = @_;
  ### QuadButton _do_scroll_event(): $event->direction, $event->state
  $self->signal_emit ('clicked',
                      ($event->state & $modifiers_for_page
                       ? 'page-' : 'step-')
                      . $event->direction);
  return $self->signal_chain_from_overridden ($event);
}

1;
__END__

=for stopwords Gtk2-Ex-QuadButton Ryde QuadButton ScrollType prelight eg focusable scrollbars ie Gtk

=head1 NAME

Gtk2::Ex::QuadButton -- button for up, down, left or right

=head1 SYNOPSIS

 use Gtk2::Ex::QuadButton;
 my $qb = Gtk2::Ex::QuadButton->new;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::QuadButton> is a subclass of
C<Gtk2::DrawingArea>, but don't rely on more than C<Gtk2::Widget> for now.

    Gtk2::Widget
      Gtk2::DrawingArea
        Gtk2::Ex::QuadButton

=head1 DESCRIPTION

A QuadButton button presents up, down, left and right arrows for the user to
click within a single button,

    +-------------------+
    |         /\        |
    |        /  \       |
    |         ||        |
    |  / -----  ----- \ |
    |  \ -----  ----- / |
    |         ||        |
    |        \  /       |
    |         \/        |
    +-------------------+

A C<clicked> signal is emitted with a C<Gtk2::ScrollType> like C<step-up>,
C<page-right> etc.  A normal click is a "step" and if the control key is
held down then a "page".

ScrollType is oriented towards stepping or paging something in the display.
See C<Gtk2::Ex::QuadButton::Scroll> to act on
C<Gtk2::Adjustment> objects.  The ScrollType reaches a Perl code signal
handler as a string, so it's easy to strip the C<step-> or C<page-> part if
only interested in the direction.

Moving the mouse pointer across the QuadButton shows the prospective
direction as "prelight".  In the Gtk default "Raleigh" theme prelight
foreground colour is the same as normal foreground, so only the background
is highlighted.  This can make it a little hard to see, but doesn't affect
clicking of course.

=head2 Key Bindings

The following mouse buttons and keystrokes are recognised

    Button1             step-up,down,left,right per arrow
    <Ctrl>Button1       page-up,down,left,right per arrow
    Mouse-Wheel         step-up,down,left,right 
    <Ctrl>Mouse-Wheel   page-up,down,left,right 

    Up              step-up
    Down            step-down
    Left            step-left
    Right           step-right
    <Ctrl>Up        page-up
    <Ctrl>Down      page-down
    <Ctrl>Left      page-left
    <Ctrl>Right     page-right
    Page_Up         page-up
    Page_Down       page-down

Other key bindings can be set to emit C<clicked> in the usual ways, eg. per
L<Gtk2::Rc>.  The mouse buttons are hard-coded.  The mouse wheel is from the
usual widget C<scroll-event> and can go left and right too if you have a
second wheel or setup for that.

The QuadButton is focusable by default.  If you don't want keyboard
operation then turn off C<can_focus> in the usual way (see L<Gtk2::Widget>)
to be mouse-only,

    $qb->can_focus(0);

=head2 Size Request

The default size request is small but enough to be visible and to click on.
Currently it's based on the font size, but that might change.

If the QuadButton is to go somewhere like the lower right corner of an
application between vertical and horizontal scroll bars then the default
might be bigger than the space normally there.  To have it use only that
space, ie. not have the container widen the scrollbars just for the button,
then apply a C<set_size_request()> to something small, perhaps just 1x1.
The usual C<width-request> and C<height-request> properties can do that in
the creation,

    my $qb = Gtk2::Ex::QuadButton->new
               (width_request  => 1,    # 1x1 no minimum size
                height_request => 1);

In all cases the QuadButton uses whatever space is provided by the parent
and centres itself in a square area within that allocation.  See the
C<xalign> and C<yalign> properties below to control the positioning.

=head1 FUNCTIONS

=over 4

=item C<< $qb = Gtk2::Ex::QuadButton->new (key=>value,...) >>

Create and return a new C<QuadButton> widget.  Optional key/value pairs set
initial properties per C<< Glib::Object->new >>.

    my $qb = Gtk2::Ex::QuadButton->new;

=back

=head1 SIGNALS

=over

=item C<clicked> action signal (parameters: C<Gtk2::ScrollType>)

Emitted when the user clicks on the button with the mouse pointer or presses
a key.

This is an "action signal" and can be emitted both from C<Gtk2::Rc> key
bindings and from program code.

=back

=head1 PROPERTIES

=over

=item C<xalign> (float, default 0.5)

=item C<yalign> (float, default 0.5)

The positioning of the quad arrow within the allocated area.

If the allocated area is wider than needed then the arrow is positioned
according to C<xalign>.  0.0 is the left edge, 1.0 the right edge.  The
default 0.5 means centre it.  Similarly C<yalign> if the allocated area is
higher than needed, with 0.0 for the top, 1.0 for the bottom.

If the widget text direction (see C<set_direction> in L<Gtk2::Widget>) is
C<"rtl"> then the sense of C<xalign> is reversed, so 0.0 is the right edge
and 1.0 is the left edge.

These properties are the same as the C<Gtk2::Misc>, but QuadButton doesn't
inherit from that class (currently).

=back

=head1 SEE ALSO

L<Gtk2::Ex::QuadButton::Scroll>,
L<Gtk2::Button>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-quadbutton/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-QuadButton.  If not, see L<http://www.gnu.org/licenses/>.

=cut

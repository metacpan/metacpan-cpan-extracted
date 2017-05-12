# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::CrossHair;
use 5.008;
use strict;
use warnings;
use Carp;
use List::Util;
use Scalar::Util 1.18 'refaddr'; # 1.18 for pure-perl refaddr() fix
use POSIX ();

# 1.200 for Gtk2::GC auto-release
use Gtk2 1.200;
use Glib::Ex::SignalIds;
use Gtk2::Ex::Xor;
use Gtk2::Ex::WidgetBits 31; # v.31 for xy_root_to_widget()

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 19;

# The _pw() func gives a hash of per-widget data.  Its fields are
#
#   static_ids
#       Glib::Ex::SignalIds of signal connections made for as long as the
#       widget is in the crosshair.
#   dynamic_ids
#       Glib::Ex::SignalIds of signal connections made only while the
#       crosshair is active.
#   gc
#       A Gtk2::GC shared gc to draw with.  Created by the _draw() code when
#       needed, deleted by style-set etc for colour changes etc.
#   x,y
#       Position in widget coordinates at which the crosshair is drawn in
#       the widget.  'x' doesn't exist in the hash if the position is not
#       yet decided.  'x' is undef if the cross is entirely outside the
#       widget and thus there's nothing to draw.
#
# The per-widget data could be in a Tie::RefHash or inside-out thingie or
# similar to keep out of the target widgets.  Would that be worthwhile?  The
# widget already has a handy hash to put things in, may as well use that
# than load extra code.
#

use Glib::Object::Subclass
  'Glib::Object',
  signals => { moved => { param_types => ['Gtk2::Widget',
                                          'Glib::Scalar',
                                          'Glib::Scalar'],
                          return_type => undef },
             },
  properties => [ Glib::ParamSpec->object
                  ('widget',
                   'widget',
                   'Single widget to act on.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('drawn',
                   'drawn',
                   'Whether to display the crosshair.',
                   0,
                   'readable'),

                  Glib::ParamSpec->object
                  ('crosshair',
                   'crosshair',
                   '', # Blurb
                   'Gtk2::Widget', # actually 'Gtk2::Ex::CrossHair'
                   'writable'),
                ];


# sub INIT_INSTANCE {
#   my ($self) = @_;
#   ### CrossHair-PerWidget INIT_INSTANCE
# }

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  $self->undraw;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### CrossHair SET_PROPERTY: $pname

  if ($pname eq 'widget' || $pname eq 'crosshair') {
    my $old_draw = $self->undraw;
    delete $self->{'gc'};

    # per default GET_PROPERTY
    Scalar::Util::weaken ($self->{$pname} = $newval);

    if ($pname eq 'widget') {
      my $widget = $self->{'widget'};
      $self->{'static_ids'} = $widget && Glib::Ex::SignalIds->new
        ($widget,
         $widget->signal_connect (style_set => \&_do_style_set,
                                  Gtk2::Ex::Xor::_ref_weak($self)));

      # These are events needed in button drag mode, ie. when start() is
      # called with a button event.  The alternative would be to turn them
      # on by a new Gtk2::Gdk->pointer_grab() to change the implicit grab,
      # though 'button-release-mask' is best turned on in advance in case
      # we're lagged and it happens before we change the event mask.
      #
      # 'exposure-mask' is not here since if nothing else is drawing then
      # there's no need for the crosshair to redraw over its changes.
      #
      require Gtk2::Ex::WidgetEvents;
      $self->{'wevents'} = $widget && Gtk2::Ex::WidgetEvents->new
        ($widget, ['button-motion-mask',
                   'button-release-mask',
                   'pointer-motion-mask',
                   'enter-notify-mask',
                   'leave-notify-mask']);
    }

    if (my $crosshair = $self->{'crosshair'}) {
      _maybe_move ($self, $crosshair->{'root_x'}, $crosshair->{'root_y'});
    }
    if ($old_draw) {
      $self->draw;
    }

  } else {
    $self->{$pname} = $newval;  # per default GET_PROPERTY
  }
}

sub start {
  my ($self) = @_;
  ### CrossHair _pw_start(): "$widget"

  my $widget = $self->{'widget'};
  my $ref_weak_self = Gtk2::Ex::Xor::_ref_weak ($self);
  $self->{'dynamic_ids'} = $widget && Glib::Ex::SignalIds->new
    ($widget,
     $widget->signal_connect (motion_notify_event => \&_do_motion_notify,
                              $ref_weak_self),
     $widget->signal_connect (button_release_event => \&_do_button_release,
                              $ref_weak_self),
     $widget->signal_connect (enter_notify_event => \&_do_enter_notify,
                              $ref_weak_self),
     $widget->signal_connect (leave_notify_event => \&_do_leave_notify,
                              $ref_weak_self),
     $widget->signal_connect_after (expose_event => \&_do_expose_event,
                                    $ref_weak_self),
     $widget->signal_connect_after (size_allocate => \&_do_size_allocate,
                                    $ref_weak_self));
  $self->draw;
}

sub end {
  my ($self) = @_;
  delete $self->{'dynamic_ids'};
}


#-----------------------------------------------------------------------------

# 'motion-notify-event' on a target widget
sub _do_motion_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_motion_notify(): "$widget ".$event->x_root.",".$event->y_root
  if (my $self = $$ref_weak_self) {
    if (my $crosshair = $self->{'crosshair'}) {
      if ($crosshair->{'active'}) {
        $crosshair->_maybe_move ($self, $event);
      }
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'size-allocate' signal on a widget
sub _do_size_allocate {
  my ($widget, $alloc, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### CrossHair _do_size_allocate: "$widget"

  # if the widget position has changed then must draw lines at new spots
  $self->redraw;
}

# 'enter-notify-event' signal on the widgets
sub _do_enter_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_enter_notify(): "$widget ".$event->x_root.",".$event->y_root
  if (my $self = $$ref_weak_self) {
    if (my $crosshair = $self->{'crosshair'}) {
      if (! $crosshair->{'button'}) {
        # not button drag mode
        $crosshair->_maybe_move ($self, $event);
      }
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'leave-notify-event' signal on one of the widgets
sub _do_leave_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_leave_notify(): "$widget " . $event->x_root . "," . $event->y_root
  if (my $self = $$ref_weak_self) {
    if (my $crosshair = $self->{'crosshair'}) {
      if (! $crosshair->{'button'}) {
        # not button drag mode
        $crosshair->_maybe_move ($self, $event);
      }
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'button-release-event' signal on one of the widgets
sub _do_button_release {
  my ($widget, $event, $ref_weak_self) = @_;
  if (my $self = $$ref_weak_self) {
    if (my $crosshair = $self->{'crosshair'}) {
      if ($event->button == $crosshair->{'button'}) {
        $crosshair->end ($event);
      }
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

sub _do_expose_event {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair-PerWidget _do_expose_event()
  if (my $self = $$ref_weak_self) {
    $self->draw ($self, $event->region);
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'style-set' signal handler on each widget
# A style change normally provokes a full redraw.  Think it's enough to rely
# on that for redrawing the crosshair against a possible new background, so
# just refresh the gc.
sub _do_style_set {
  my ($widget, $prev_style, $ref_weak_self) = @_;
  ### PerWidget _do_style_set: "$widget"
  my $self = $$ref_weak_self || return;
  delete $self->{'gc'}; # possible new colours
}

sub change_gc {
  my ($self) = @_;
  $self->undraw;
  delete $self->{'gc'};
  $self->draw;
}

sub redraw {
  my ($self) = @_;
  if ($self->undraw) {
    $self->draw;
  }
}

sub undraw {
  my ($self) = @_;
  my $old = $self->{'drawn'};
  if ($old) {
    _draw ($self);
    $self->{'drawn'} = 0;
    # position undetermined as well as undrawn
    delete $self->{'x'};
  }
  ### PerWidget undraw() done
  return $old;
}

# $widgets is an arrayref of widgets to draw, or undef for all
sub draw {
  my ($self, $clip_region) = @_;
  ### PerWidget draw(): "$self->{'widget'}"

  my $crosshair = $self->{'crosshair'} || return;
  $crosshair->{'active'} || return;

  my $widget = $self->{'widget'} || return;
  my $win = $widget->Gtk2_Ex_Xor_window || return; # perhaps unrealized

  my $root_x = $crosshair->{'root_x'};
  my $root_y = $crosshair->{'root_y'};
  $self->{'drawn'} = 1;

  if (! exists $self->{'x'}) {
    ### establish draw position: "$widget", $root_x, $root_y
    @{$self}{'x','y'}
      = (defined $root_x
         ? Gtk2::Ex::WidgetBits::xy_root_to_widget ($widget, $root_x, $root_y)
         : ());
    ### at: $self->{'x'}, $self->{'y'}
  }

  my $x = $self->{'x'};
  defined $x || return;
  my $y = $self->{'y'};

  my $gc = ($self->{'gc'} ||= do {
    ### create gc
    my $line_width = $crosshair->get('line_width');
    my $line_style = $crosshair->{'line_style'} || 'double-dash';
    Gtk2::Ex::Xor::shared_gc
        (widget         => $widget,
         foreground_xor => $crosshair->{'foreground'},
         background     => 0,  # no change
         line_width     => $line_width,
         line_style     => $line_style,
         fill           => 'stippled',
         cap_style      => 'projecting',
         ($line_style eq 'solid' ? ()
          : (dash_list => [ ($line_width || 1) * 4 ])),
         # subwindow_mode => 'include_inferiors',
        );
  });

  if ($win != $widget->window) {
    # if the operative Gtk2_Ex_Xor_window is not the main widget window,
    # then adjust from widget coordinates to the $win subwindow
    my ($wx, $wy) = $win->get_position;
    ### subwindow offset: "$wx,$wy"
    $x -= $wx;
    $y -= $wy;
  }

  my ($x_lo, $y_lo, $x_hi, $y_hi);
  if ($widget->get_flags & 'no-window') {
    my $alloc = $widget->allocation;
    $x_lo = $alloc->x;
    $x_hi = $alloc->x + $alloc->width - 1;
    $y_lo = $alloc->y;
    $y_hi = $alloc->y + $alloc->height - 1;
    $x += $x_lo;
    $y += $y_lo;
  } else {
    ($x_hi, $y_hi) = $win->get_size;
    $x_lo = 0;
    $y_lo = 0;
  }

  if ($clip_region) { $gc->set_clip_region ($clip_region); }
  $win->draw_segments
    ($gc,
     $x_lo,$y, $x_hi,$y,  # horizontal
     $x,$y_lo, $x,$y_hi); # vertical
  if ($clip_region) { $gc->set_clip_region (undef); }
}


#------------------------------------------------------------------------------

1;
__END__

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Dragger;
use 5.008;
use strict;
use warnings;
use Carp;
use POSIX ();
use Glib 1.220; # 1.220 for Glib::SOURCE_REMOVE
use Gtk2 1.220; # 1.220 for Gtk2::EVENT_PROPAGATE
use List::Util qw(min max);
use Scalar::Util;

use Glib::Ex::SignalIds;
use Gtk2::Ex::WidgetEvents;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 10;

use constant DELAY_MILLISECONDS => 250;

BEGIN {
  Glib::Type->register_enum ('Gtk2::Ex::Dragger::UpdatePolicy',
                             'default',
                             'continuous',
                             'delayed',
                             'discontinuous',
                            );
}

use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->object
                  ('widget',
                   'Target widget',
                   'The target widget whose contents are to be moved around.  (For a widget inside a Gtk2::ViewPort this property should be the ViewPort.)',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('hadjustment',
                   (do {
                     my $str = 'Horizontal adjustment';
                     # translation if available
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Horizontal adjustment to change, or undef for no horizontal drag.',
                   'Gtk2::Adjustment',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('vadjustment',
                   (do {
                     my $str = 'Vertical adjustment';
                     # translation if available
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'Vertical adjustment to change, or undef for no vertical drag.',
                   'Gtk2::Adjustment',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('hinverted',
                   'Horizontal inverted',
                   'Whether to invert horizontal movement, for hadjustment valuess increasing to the left (ie. decreasing X coordinate).',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('vinverted',
                   'Vertical inverted',
                   'Whether to invert vertical movement, for vadjustment values increasing up the screen (ie. decreasing Y coordinate).',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('confine',
                   'Confine pointer',
                   'Confine the mouse pointer to the draggable extent per upper/lower range of the adjustments.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('update-policy',
                   'Update policy',
                   'How often to update the hadjustment and vadjustment objects for drag movement.',
                   'Gtk2::Ex::Dragger::UpdatePolicy',
                   'default',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('cursor',
                   'Cursor',
                   'Cursor to show while dragging, as any name or object accepted by Gtk2::Ex::WidgetCursor.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('cursor-name',
                   'Cursor name',
                   'Cursor to show while dragging, as cursor type enum nick, or "invisible".',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boxed
                  ('cursor-object',
                   'Cursor object',
                   'Cursor to show while dragging, as cursor object.',
                   'Gtk2::Gdk::Cursor',
                   Glib::G_PARAM_READWRITE),

                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'h'} = {};
  $self->{'v'} = {};
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  $self->stop;
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### Dragger GET_PROPERTY(): $pname

  if ($pname eq 'cursor_name') {
    my $cursor = $self->{'cursor'};
    if (Scalar::Util::blessed($cursor)) {
      $cursor = $cursor->type;
      # think prefer undef over cursor-is-pixmap for the get()
      if ($cursor eq 'cursor-is-pixmap') {
        undef $cursor;
      }
    }
    return $cursor;
  }
  if ($pname eq 'cursor_object') {
    my $cursor = $self->{'cursor'};
    return (Scalar::Util::blessed($cursor)
            && $cursor->isa('Gtk2::Gdk::Cursor')
            && $cursor);
  }

  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Dragger SET_PROPERTY(): $pspec->get_name
  my $pname = $pspec->get_name;

  my $pname_is_cursor = ($pname =~ s/^(cursor).*/$1/);
  my $oldval = $self->{$pname};
  $self->{$pname} = $newval;

  if ($pname_is_cursor) {
    # copy boxed GdkCursor in case the caller frees it, and in particular
    # for $pname eq 'cursor_object' it might be freed immediately by the
    # GValue call-out stuff
    # if (blessed($newval) && $newval->isa('Gtk2::Gdk::Cursor')) {
    #   $self->{$pname} = $newval->copy;
    # }
    _widget_cursor($self);
    $self->notify('cursor');
    $self->notify('cursor-name');
    $self->notify('cursor-object');

  } elsif ($pname eq 'widget') {
    my $widget = $newval;
    if (! $newval
        || ($oldval && $newval != $oldval)) {
      # ENHANCE-ME: might be able to switch to an active grab on the new
      # widget and continue
      $self->stop;
    }
    if ($widget) {
      Scalar::Util::weaken ($self->{'widget'});
    }
    $self->{'wevents'} = $widget && Gtk2::Ex::WidgetEvents->new
      ($widget, ['button-press-mask',
                 'button-motion-mask',
                 'button-release-mask']);
    _widget_signals($self);

  } elsif ($pname =~ /([hv])(adjustment|inverted)/) {
    my $axis = $self->{$1};
    my $field = $2;
    $axis->{$field} = $newval;

    if ($field eq 'adjustment') {
      $axis->{'last_value'} = $newval && $newval->value;
      _axis_signals($self,$axis);
      _do_adjustment_changed ($newval, \$self);
    }

  } elsif ($pname eq 'confine') {
    _resize_confine_win ($self);
  }
}

# create or update WidgetCursor according to $self->{'cursor'}
# doesn't load WidgetCursor until drag active
sub _widget_cursor {
  my ($self) = @_;
  $self->{'wcursor'} = ($self->{'active'}
                        && $self->{'cursor'}
                        && do {
                          require Gtk2::Ex::WidgetCursor;
                          Gtk2::Ex::WidgetCursor->new
                              (widget => $self->{'widget'},
                               cursor => $self->{'cursor'},
                               active => 1);
                        });
}

# update $self->{'h'}->{'adjustment_ids'} or $self->{'v'}->... signal handlers
# handlers only applied while 'active'
sub _axis_signals {
  my ($self, $axis) = @_;
  my $adj;
  $axis->{'adjustment_ids'} =
    ($self->{'active'}
     && ($adj = $axis->{'adjustment'})
     && do {
       my $ref_weak_self = _ref_weak ($self);

       ### _axis_signals() connect
       Glib::Ex::SignalIds->new
           ($adj,
            $adj->signal_connect (changed => \&_do_adjustment_changed,
                                  $ref_weak_self),
            $adj->signal_connect (value_changed => \&_do_adjustment_value_changed,
                                  $ref_weak_self))
         });
}

# make signal handler connections on $self->{'widget'} if active
sub _widget_signals {
  my ($self) = @_;
  my $widget;
  $self->{'widget_ids'} =
    ($self->{'active'}
     && ($widget = $self->{'widget'})
     && do {
       my $ref_weak_self = _ref_weak ($self);

       ### _widget_signals() connect
       Glib::Ex::SignalIds->new
           ($widget,
            $widget->signal_connect (motion_notify_event => \&_do_motion_notify,
                                     $ref_weak_self),
            $widget->signal_connect (button_release_event => \&_do_button_release,
                                     $ref_weak_self),
            $widget->signal_connect (configure_event => \&_do_configure_event,
                                     $ref_weak_self),
            $widget->signal_connect (grab_broken_event => \&_do_grab_broken,
                                     $ref_weak_self))
         });
}

sub start {
  my ($self, $event) = @_;
  ### Dragger start()

  # maybe a second start() call could transition to a different button, but
  # for now disallow it
  if ($self->{'active'}) {
    croak __PACKAGE__.'->start(): drag already active';
  }
  (Scalar::Util::blessed($event) && $event->isa('Gtk2::Gdk::Event::Button'))
    or croak __PACKAGE__.'->start(): must have button press event';

  my $widget = $self->{'widget'};
  my $win = $widget->Gtk2_Ex_Dragger_window
    or croak __PACKAGE__.'->start(): widget not realized';

  $self->{'active'} = 1;
  _widget_cursor($self);
  _widget_signals($self);

  foreach my $axis ($self->{'h'}, $self->{'v'}) {
    my $adj = $axis->{'adjustment'} or next;
    $axis->{'unapplied'} = 0;
    $axis->{'pending'} = 0;
    $axis->{'last_value'} = $adj->value;
    _axis_signals ($self, $axis);
  }

  $self->{'button'} = $event->button;
  ($self->{'h'}->{'last_pixel'}, $self->{'v'}->{'last_pixel'})
    = $event->get_root_coords;

  if ($self->{'confine'}) {
    my $confine_win = ($self->{'confine_win'} ||= Gtk2::Gdk::Window->new
                       ($widget->get_root_window,
                        { window_type       => 'temp',
                          wclass            => 'GDK_INPUT_ONLY',
                          override_redirect => 1 }));
    ### confine_win: "$confine_win"
    _resize_confine_win ($self);
    $confine_win->show;

    # ENHANCE-ME: $win->get_events is a server round-trip, maybe fetch only
    # the first time, or fetch once and then mask in the widget 'events'
    # property subsequently; or something cooperating with WidgetEvents ...
    #
    ### widget events: $widget->get_events.''
    ### window events: $widget->window->get_events.''
    my $event_mask
      = ($win->get_events & ['button-press-mask',
                             'pointer-motion-hint-mask',
                             'structure-mask',
                             'property-change-mask' ])
        + ['button-motion-mask', 'button-release-mask'];
    ### events: "$event_mask"
    ### grab to           : $widget->window.''
    ### cf button press on: $event->window.''
    ### cf size win       : "$win"

    my $status = Gtk2::Gdk->pointer_grab ($widget->window,
                                          0,      # owner events
                                          $event_mask,
                                          $confine_win,
                                          undef,  # cursor inherited
                                          $event->time);
    ### grab: "$status time ".$event->time
    if ($status eq 'success') {
      $self->{'grabbed'} = 1;
    } else {
      carp __PACKAGE__."->start(): cannot grab: $status";
    }
  }
}

# 'grab-broken-event' signal on the target widget
#
# This event is a client-side invention of gdk, we listen to it to know when
# gdk's grab tracking says we lost the grab due to a window unmap or another
# grab by a different part of the program.  This (almost certainly) means we
# should stop dragging.
#
# Gtk2::Gdk->pointer_grab() above will itself enqueue a grab broken event if
# the $widget->window we supply there is different from the one the implicit
# grab of the button press was in.  That can happen when there's multiple
# GdkWindows within $widget, with all of their events dispatched to $widget.
# For example if you put a no-window child into a Gtk2::Viewport then a
# button press on it goes to the "view_window" sub-window of the Viewport,
# which is the large moving subwindow of $widget->window (in fact
# sub-sub-window, since there's a "bin_window" in between too).
#
# The code here checks if $event->window is our pointer_grab()
# $widget->window losing the grab.  (A pointer_grab() call asking for the
# same window as currently holding the grab doesn't produce a grab broken
# event, so that test is safe against a button press and grab to the same
# child window.)
#
# It'd also be possible to look at $event->grab_window to see who has the
# current grab window, to see if it's our desired $widget->window.  That'd
# be a kind of more positive test, but $event->grab_window is not wrapped
# until Gtk2-Perl 1.190.
#
sub _do_grab_broken {
  my ($widget, $event, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return Gtk2::EVENT_PROPAGATE;
  ### Dragger _do_grab_broken()
  ### event window : $event->window.''
  ### widget window: $widget->window.''

  if ($self->{'grabbed'} && $event->window == $widget->window) {
    $self->{'grabbed'} = 0;
    $self->stop ($event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

# 'button-release-event' signal on the target widget
sub _do_button_release {
  my ($widget, $event, $ref_weak_self) = @_;
  ### Dragger _do_button_release()
  my $self = $$ref_weak_self || return Gtk2::EVENT_PROPAGATE;

  if ($event->button == $self->{'button'}) {
    _do_motion_notify ($widget, $event, \$self); # final position
    $self->stop ($event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub stop {
  my ($self, $event) = @_;
  ### Dragger stop()

  if (! delete $self->{'active'}) { return; }

  if (delete $self->{'grabbed'}) {
    Gtk2::Gdk->pointer_ungrab (defined $event
                               ? $event->time : Gtk2::GDK_CURRENT_TIME);
  }
  if (my $confine_win = $self->{'confine_win'}) {
    $confine_win->hide;
  }
  if (my $id = delete $self->{'idle_id'}) {
    Glib::Source->remove ($id);
  }
  if (my $id = delete $self->{'timer_id'}) {
    Glib::Source->remove ($id);
  }
  delete $self->{'widget_ids'};
  delete $self->{'wcursor'};
  delete $self->{'h'}->{'adjustment_ids'};
  delete $self->{'v'}->{'adjustment_ids'};
  _emit_pending ($self);
}

# 'configure-event' signal on the target widget
sub _do_configure_event {
  my ($widget, $event, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return Gtk2::EVENT_PROPAGATE;

  # new window size changes the scale factor and hence how many pixels to
  # the adjustable limits
  _resize_confine_win ($self);
  return Gtk2::EVENT_PROPAGATE;
}

# 'changed' signal on either hadjustment or vadjustment
sub _do_adjustment_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### Dragger _do_adjustment_changed(): "$adj"

  # new page size changes the scale factor and hence how many pixels to the
  # adjustable limits
  _resize_confine_win ($self);
}

# 'value-changed' signal on either hadjustment or vadjustment
#
# If the value we see is what we set then no action.  If it's something
# different then it's a change made by the keyboard or something else
# external.
#
# We must reset any 'unapplied' amount because we can't have a non-zero
# unapplied when the value is somewhere not at the upper or lower limits,
# because unapplied is essentially how far beyond those limits the mouse is.
# (The effect of leaving an 'unapplied' is for the value to jump down or up
# unnaturally on the next drag update.)
#
sub _do_adjustment_value_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my $axis = ($adj == ($self->{'h'}->{'adjustment'} || 0)
              ? $self->{'h'}
              : $self->{'v'});

  if ($adj->value == $axis->{'last_value'}) { return; }

  ### Dragger value changed externally to: $adj->value
  $axis->{'last_value'} = $axis->{'adjustment'}->value;
  $axis->{'unapplied'} = 0;

  # new positions for the limits relative to the mouse position
  _resize_confine_win ($self);
}

sub _resize_confine_win {
  my ($self) = @_;
  my $confine_win = $self->{'confine_win'} || return;

  my $widget = $self->{'widget'};
  my $win = $widget->Gtk2_Ex_Dragger_window;
  my ($win_width, $win_height) = $win->get_size;

  my $root = $widget->get_root_window;
  my ($root_width, $root_height) = $root->get_size;

  # default full root window, no confine
  my $confine_x = 0;
  my $confine_y = 0;
  my $confine_width = $root_width;
  my $confine_height = $root_height;

  # The x position is so a move that far to the left would hit the limit of
  # the adjustment.  For normal direction a mouse move to the left increases
  # adjustment value, so look at how far "value" is from "upper - page".
  # For inverted a move to the left decreases adjustment value, so look at
  # how far "value" is from "lower".
  #
  if (my $hadj = $self->{'h'}->{'adjustment'}) {
    if (my $page_size = $hadj->page_size) {
      $confine_x = $self->{'h'}->{'last_pixel'} -
        ($win_width / $page_size)
          * ($self->{'h'}->{'inverted'}
             ? $hadj->value - $hadj->lower
             : $hadj->upper - $hadj->page_size - $hadj->value);
      $confine_width = $win_width
        * ($hadj->upper - $hadj->lower - $hadj->page_size) / $hadj->page_size;
    }
  }
  if (my $vadj = $self->{'v'}->{'adjustment'}) {
    if (my $page_size = $vadj->page_size) {
      $confine_y = $self->{'v'}->{'last_pixel'} -
        ($win_height / $page_size)
          * ($self->{'v'}->{'inverted'}
             ? $vadj->value - $vadj->lower
             : $vadj->upper - $vadj->page_size - $vadj->value);
      $confine_height = $win_height
        * ($vadj->upper - $vadj->lower - $vadj->page_size) / $vadj->page_size;
    }
  }

  # round x,y down to integers, increasing width,height by what's subtracted
  {
    my $frac;
    ($confine_x, $frac) = _floor_and_frac ($confine_x);
    $confine_width += $frac;
    ($confine_y, $frac) = _floor_and_frac ($confine_y);
    $confine_height += $frac;
  }

  # round up width,height to integers
  $confine_width  = POSIX::ceil ($confine_width);
  $confine_height = POSIX::ceil ($confine_height);

  # allow an extra pixel left,right,top and bottom just in case the rounding
  # is a bit off, or whatever
  $confine_x--;
  $confine_y--;
  $confine_width += 2;
  $confine_height += 2;

  # Bring any negative top-left X,Y into range of the screen.  This is in
  # case X,Y are big negatives that overflow the signed 16-bit value in the
  # X protocol.
  if ($confine_x < 0) {
    $confine_width += $confine_x;  # reduce width accordingly
    $confine_x = 0;
  }
  if ($confine_y < 0) {
    $confine_height += $confine_y;  # reduce height accordingly
    $confine_y = 0;
  }

  # If the X,Y position is off the right or bottom of the screen then go to
  # a single pixel at that right or bottom.  Suspect this shouldn't occur,
  # because the confine window will contain the current mouse position, and
  # that's certainly somewhere on-screen.
  #
  if ($confine_x >= $root_width) {
    $confine_x = $root_width - 1;
    $confine_width = 1;
  }
  if ($confine_y >= $root_height) {
    $confine_y = $root_height - 1;
    $confine_height = 1;
  }

  # Chop off any width/height exceeding the screen.  This is in case
  # width,height are big values which overflow the 16-bit integers in the X
  # protocol.
  $confine_width  = min ($confine_width,  $root_width  - $confine_x);
  $confine_height = min ($confine_height, $root_height - $confine_y);

  ### confine to: "$confine_x,$confine_y   ${confine_width}x${confine_height}"
  $confine_win->move_resize ($confine_x, $confine_y,
                             $confine_width, $confine_height);
}

# 'motion-notify-event' on widget, and also called for button release.
#
# The basic operation is simply to look at how many pixels the new x,y in
# $event has moved from our last_x,last_y and apply those amounts to the
# "value" in the adjustments.  But with attention to the following:
#
# * Scale factor $value_per_pixel converts between a window worth of pixels
#   equivalent to a page size amount in the adjust.
#
# * last_x and last_y are kept in root window coordinates.  This makes no
#   difference to each "delta" calculated, but means we're safe against any
#   changes to the widget window position; and also makes the confine_win
#   calculation a little easier.
#
# * The hinverted/vinverted settings are tricky to get the right way around.
#   In normal state a move to the right reduces the value, and when inverted
#   it's the other way around.
#
# * An "unapplied" amount of value is maintained horizontally and vertically
#   if the prospective value would be outside the adjustment upper/lower
#   bounds.  It gets added back each time, with the effect of keeping the
#   same widget contents position under the mouse if you go beyond the limit
#   and then come back.
#
sub _do_motion_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  #### Dragger _do_motion_notify()
  my $self = $$ref_weak_self || return Gtk2::EVENT_PROPAGATE;

  # Believe no need for Gtk 2.12 $event->request_motions here since our
  # device is only ever the mouse, so $win->get_pointer is enough.  Besides,
  # request_motions() looks pretty slack -- surely if you're going to do a
  # server round trip (as $disp->get_pointer or $device->get_state) then you
  # should use the position obtained, not throw it away.
  #
  # test can('is_hint') to allow for final $event a Gtk2::Gdk::Event::Button
  # release; such an event doesn't have an is_hint field.
  #
  my ($x, $y);
  if ($event->can('is_hint') && $event->is_hint) {
    (undef, $x, $y) = $widget->get_root_window->get_pointer;
  } else {
    ($x, $y) = $event->get_root_coords;
  }

  my $win = $widget->Gtk2_Ex_Dragger_window;
  my ($win_width, $win_height) = $win->get_size;
  _set_value ($self, $self->{'h'}, $win_width, $x);
  _set_value ($self, $self->{'v'}, $win_height, $y);
  return Gtk2::EVENT_PROPAGATE;
}

sub _set_value {
  my ($self, $axis, $win_size, $pixel) = @_;
  ##### Dragger _set_value(): "pixel $pixel", $axis

  my $adj = $axis->{'adjustment'} || return;

  my $delta_pixel = $pixel - $axis->{'last_pixel'};
  if ($delta_pixel == 0) { return; }
  $axis->{'last_pixel'} = $pixel;
  if ($axis->{'inverted'}) { $delta_pixel = - $delta_pixel; }

  my $page_size = $adj->page_size;
  my $value_per_pixel = $page_size / $win_size;
  my $old_value = $adj->value;
  my $new_value
    = $old_value + $axis->{'unapplied'} - $delta_pixel * $value_per_pixel;
  my $unapplied = 0;

  my $lower = $adj->lower;
  if ($new_value < $lower) {
    $unapplied = $new_value - $lower; # negative
    $new_value = $lower;
  }
  my $upper = $adj->upper - $page_size;
  if ($new_value > $upper) {
    $unapplied = $new_value - $upper; # positive
    $new_value = $upper;
  }
  $axis->{'unapplied'} = $unapplied;

  ### set value: $new_value
  $adj->value ($new_value);
  $new_value = $axis->{'last_value'} = $adj->value; # refetch in case rounding
  ### rounded from NV: $new_value
  if ($old_value == $new_value) {
    ### unchanged, no signals
    return;
  }

  $adj->notify ('value');

  my $update_policy = $self->{'update_policy'} || 'default';
  if ($update_policy eq 'continuous') {
    # emit on every set
    $adj->value_changed;
    return;
  }

  $axis->{'pending'} = 1;

  if ($update_policy eq 'discontinuous') {
    # don't emit at all until stop
    return;
  }

  if ($update_policy eq 'delayed') {
    $self->{'timer_id'} ||= Glib::Timeout->add
      (DELAY_MILLISECONDS, \&_do_timer_delayed, _ref_weak ($self));
    return;
  }

  # default policy
  require Gtk2::Ex::SyncCall;
  if (! $self->{'sync_obj'} && ! $self->{'timer_id'}) {
    #### Dragger SyncCall send
    my $ref_weak_self = _ref_weak ($self);
    $self->{'sync_obj'} = Gtk2::Ex::SyncCall->sync
      ($self->{'widget'}, \&_do_sync, $ref_weak_self);
    $self->{'timer_id'} = Glib::Timeout->add
      (DELAY_MILLISECONDS, \&_do_timer_sync, $ref_weak_self);
  }
}

# timer expiry for 'delayed' policy
# emit 'value-changed' when the timer expires
#
sub _do_timer_delayed {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self || return Glib::SOURCE_REMOVE;
  #### Dragger _do_timer_delayed()

  $self->{'timer_id'} = 0;
  _emit_pending ($self);
  return Glib::SOURCE_REMOVE;
}

# sync response for 'default' policy
#
# At this point we wait for the timer or for idle, whichever comes first.
# It's possible the timer has already gone off (zeroing 'timer_id'), if
# that's the case them we emit immediately; otherwise start an idle.
#
sub _do_sync {
  my ($ref_weak_self) = @_;
  #### Dragger _do_sync()
  my $self = $$ref_weak_self || return;

  $self->{'sync_obj'} = 0;
  if ($self->{'timer_id'}) {
    $self->{'idle_id'} ||= Glib::Idle->add
      (\&_do_idle, _ref_weak ($self), Gtk2::GDK_PRIORITY_REDRAW - 1);
  } else {
    _emit_pending ($self);
  }
}

# timer expiry for 'default' policy
#
# If the sync response hasn't yet been received then we do nothing, instead
# wait for that.  If it has been received then we can emit now, and cancel
# the idle that was running.
#
sub _do_timer_sync {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self || return Glib::SOURCE_REMOVE;
  #### Dragger _do_timer_sync() with sync: "$self->{'sync_obj'}"

  if (my $id = $self->{'idle_id'}) {
    $self->{'idle_id'} = 0;
    Glib::Source->remove ($id);
  }
  $self->{'timer_id'} = 0;

  if (! $self->{'sync_obj'}) {
    _emit_pending ($self);
  }
  return Glib::SOURCE_REMOVE;
}

# idle handler for 'default' policy
sub _do_idle {
  my ($ref_weak_self) = @_;
  #### Dragger _do_idle() after sync
  my $self = $$ref_weak_self || return Glib::SOURCE_REMOVE;

  if (my $id = $self->{'timer_id'}) {
    $self->{'timer_id'} = 0;
    Glib::Source->remove ($id);
  }
  $self->{'idle_id'} = 0;
  _emit_pending ($self);
  return Glib::SOURCE_REMOVE;
}

sub _emit_pending {
  my ($self) = @_;
  foreach my $axis ($self->{'h'}, $self->{'v'}) {
    if ($axis->{'pending'}) {
      $axis->{'pending'} = 0;
      $axis->{'adjustment'}->value_changed;
    }
  }
}

#------------------------------------------------------------------------------
# $widget->Gtk2_Ex_Dragger_window() returns the window in $widget which the
# dragger should operate on (the size to page conversion).
#
# Crib notes:
#
# GtkLayout, and subclasses like GnomeCanvas
#     Plain $widget->window is the visible extent, so nothing special
#     needed.  The scrolls move the bin_window subwindow, but how scrolling
#     is drawn doesn't matter to us.
#

sub Gtk2::Widget::Gtk2_Ex_Dragger_window {
  my ($widget) = @_;
  if (exists $widget->{'Gtk2_Ex_Dragger_window'}) {
    # user override -- but this not (yet) a documented feature as such
    return $widget->{'Gtk2_Ex_Dragger_window'};
  }
  # default
  return $widget->window;
}

# for TextView the "text" window is the visible extent
sub Gtk2::TextView::Gtk2_Ex_Dragger_window {
  my ($textview) = @_;
  return $textview->get_window ('text');
}

# for TreeView the "bin" window is the visible extent
*Gtk2::TreeView::Gtk2_Ex_Dragger_window
  = \&Gtk2::TreeView::get_bin_window;

# For Viewport there's $widget->window then within that a "view_window"
# which is smaller by the border size.  This view_window is the scrollable
# part we're interested in, but it's not a documented feature, so this is a
# nasty hack to pick it out.
#
# The $viewport->get_bin_window is a sub-window of the view_window.  It
# contains the viewport children.  (In the gtk manual in gtk 2.20 but not
# explained as such.)
#
sub Gtk2::Viewport::Gtk2_Ex_Dragger_window {
  my ($viewport) = @_;
  my $win;
  return (($win = $viewport->window) # if realized
          && ($win->get_children)[0]);
}


#------------------------------------------------------------------------------
# generic helpers

# Return two values ($floor, $frac).
# $floor is $x rounded down to an integer towards negative infinity
# $frac is the fractional part subtracted from $x to get to $floor,
# so $floor+$frac == $x
#
sub _floor_and_frac {
  my ($x) = @_;
  my $f = POSIX::floor ($x);
  return ($f, $x - $f);
}

sub _ref_weak {
  my ($self) = @_;
  Scalar::Util::weaken ($self);
  return \$self;
}


#------------------------------------------------------------------------------

1;
__END__

=for stopwords Gtk2-Ex-Dragger Dragger scrollbars WidgetCursor natively viewport dragger scrollbar timestamp Gdk ungrab Viewport TextView pixmap Ryde WidgetEvents boolean enum UpdatePolicy mozilla

=head1 NAME

Gtk2::Ex::Dragger -- drag to move adjustment position

=for test_synopsis my ($widget)

=head1 SYNOPSIS

 use Gtk2::Ex::Dragger;
 Gtk2::Ex::Dragger->new (widget => $widget,
                         hadjustment => $widget->get_hadjustment);

=head1 DESCRIPTION

C<Gtk2::Ex::Dragger> implements mouse pointer dragging to move the contents
of a widget horizontally, vertically, or both.  It works on any windowed
widget which has C<Gtk2::Adjustment> objects controlling the visible part.

The width or height of the widget corresponds to the "page" in the
adjustment.  Dragger scales pixel movement onto the adjustment "value"
accordingly.  It's then up to the usual widget drawing to follow
C<value-changed> signals from the adjustment for redraws, the same as for
scrollbars etc.  The effect for the user is that the contents are pulled
around with the mouse.

                 Adjustment
                      +--+ --upper
                      |  |
     Window           |  |
    +-------------+ \ |  |
    |             |  \|  |
    |             |   +--+ \_ page size
    |             |   |  | /
    |             |   +--+ ___ value
    |             |  /|  |
    +-------------+ / |  |
                      |  |
                      |  |
                      +--+ --lower

If you've got scrollbars then they move with the dragging too.  It can be
good to have both ways of moving since the scrollbars give visual feedback
but dragging allows finer movements if the visible page is a very small part
of the total adjustable extent.

The "confine" option lets you to restrict mouse movement to screen positions
corresponding to the adjustment upper/lower, so the user gets an obvious
feedback at the limits.

The "cursor" option changes the mouse pointer cursor while dragging.  This
is good if it's not clear for a given widget which button press etc
activates a drag.  The cursor is set through WidgetCursor (see
L<Gtk2::Ex::WidgetCursor>) and so cooperates with other uses of that.  See
F<examples/heart.pl> in the Gtk2-Ex-Dragger sources, or F<examples/busy.pl>
for the global "busy" indication.

Dragger can work on both natively scrollable widgets and widgets put into a
C<Gtk2::Viewport>.  For a viewport it's the viewport widget which is passed
to the dragger since that's the widget showing a portion of a larger
underlying thing.  (Eg. F<examples/textview.pl> natively or
F<examples/label.pl> and F<examples/layout.pl> in a Viewport or Layout, and
F<examples/vruler.pl> with separately jigged up adjusters.)

Changes to the adjustment value, upper/lower, page size, or the widget
window size are all allowed during a drag.  A change to the value could come
from a keyboard page-up etc.  In all cases the Dragger continues relative to
the new position and will update any "confine" window limits.

=head2 Event Mask

The dragger adds the following events mask bits to the target widget.  It
uses the WidgetEvents mechanism (see L<Gtk2::Ex::WidgetEvents>) so they're
cleaned up if the dragger is destroyed.

    button-press-mask
    button-motion-mask
    button-release-mask

The dragger doesn't itself have a button press handler (at present), rather
an application is expected to start the drag for some button/modifier
combination.  The dragger adds the press mask in readiness for that.

If you want to defer dragger creation until actually needed in a button
press then you must explicitly select the motion and release events
beforehand.  For example,

    # events selected beforehand
    $widget->add_events (['button-press-mask',
                          'button-motion-mask',
                          'button-release-mask']);

    # dragger not created until actually wanted
    sub my_button_press_handler {
      my ($widget, $event) = @_;
      if (some_thing()) {
        require Gtk2::Ex::Dragger;
        $dragger = Gtk2::Ex::Dragger->new (...);
        $dragger->start ($event);
      }
    }

The motion and release masks beforehand are important if the application is
lagged.  It's possible the user has already released when the application
receives the press.  If the release mask wasn't already on then the release
event is not generated.  If you forget those masks then currently the
dragger turns on but then doesn't work and won't turn off (either all the
time, or when lagged, or the first use).

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::Dragger->new (key=>value, ...) >>

Create and return a new dragger.  Key/value pairs set the following various
parameters,

    widget         the widget to drag
    hadjustment    Gtk2::Adjustment
    vadjustment    Gtk2::Adjustment
    hinverted      boolean
    vinverted      boolean
    cursor         cursor name per Gtk2::Ex::WidgetCursor
    confine        boolean
    update_policy  string (see UPDATE POLICY below)

The target C<widget> and at least one of C<hadjustment> or C<vadjustment>
are mandatory, the rest are options.

The C<hinverted> or C<vinverted> flags swap the direction the adjustments
are moved.  Normally C<hadjustment> increases to the left and C<vadjustment>
increases upwards.  Inverting goes instead to the right or downwards.  This
is the same sense as inverted on C<Gtk2::Scrollbar>, so if you set
C<inverted> on the scrollbar then do the same to the dragger.

C<cursor> is any cursor name or object accepted by the WidgetCursor
mechanism (see L<Gtk2::Ex::WidgetCursor>).  If unset or C<undef> (the
default) then the cursor is unchanged and you don't need WidgetCursor
installed in that case.

=item C<< $dragger->start ($event) >>

Begin a drag.  C<$event> must be a C<Gtk2::Gdk::Event::Button> object; it
gives the button doing the drag and the server timestamp.

=item C<< $dragger->stop () >>

=item C<< $dragger->stop ($event) >>

Stop C<$dragger>, if it's active.  Normally a dragger stops by itself when
the dragging button is released, but this method can be do it sooner.

If you stop in response to a C<Gtk2::Gdk::Event> then pass that so its
timestamp can be used.  This matters when the dragger uses an active grab.
If application event processing is a bit lagged the timestamp ensures the
ungrab doesn't kill a later passive grab on a button press or an explicit
grab by another client.

=back

=head1 PROPERTIES

=over

=item C<widget> (C<Gtk2::Widget>, default C<undef>)

The widget whose contents are to be dragged around.

Currently if C<widget> is changed while a drag is in progress then the drag
is stopped.  In the future it may be possible to switch, though doing so
would be a bit unusual.

=item C<hadjustment> (C<Gtk2::Adjustment> object, default C<undef>)

=item C<vadjustment> (C<Gtk2::Adjustment> object, default C<undef>)

The adjustment objects representing the current position and range of
movement in the respective directions.  Nothing will move until at least one
of these two is set.

=item C<hinverted> (boolean, default false)

=item C<vinverted> (boolean, default false)

Swap the direction the respective adjustments are moved.  Normally
C<hadjustment> increases to the left and C<vadjustment> increases upwards.
Inverting goes instead to the right or downwards.  These are the same way
around as the C<Gtk2::Scrollbar> C<inverted> property so if you set
C<inverted> on the scrollbar then do the same to the dragger.

=item C<cursor> (scalar, default C<undef>)

=item C<cursor-name> (string, cursor enum nick or "invisible", default C<undef>)

=item C<cursor-object> (C<Gtk2::Gdk::Cursor>, default C<undef>)

C<cursor> is any cursor name or object accepted by the WidgetCursor
mechanism (see L<Gtk2::Ex::WidgetCursor>).  If unset or C<undef> (the
default) then the cursor is unchanged and you don't need WidgetCursor
installed in that case.

The C<cursor-name> and C<cursor-object> properties access the same
underlying C<cursor> setting but with respective string or cursor object
type.  They can be used from a C<Gtk2::Builder> specification.

=item C<confine> (boolean, default false)

Whether to confine the user's mouse movement to the screen area
corresponding to the adjustment upper/lower ranges.

=item C<update-policy> (UpdatePolicy enum, default "sync")

See L</UPDATE POLICY> above.

=back

=head1 UPDATE POLICY

The C<update_policy> option (a string) controls how often C<value-changed>
signals are emitted on the adjustments.  The dragger always stores updated
values in the adjustments immediately (and emits C<notify>), but it can be
configured to defer the C<value-changed> signal.  This is similar to the way
scrollbars work (see L<Gtk2::Scrollbar>) and the possible settings are
similar.

=over 4

=item C<"continuous">

C<value-changed> is emitted on every motion event.

=item C<"delayed">

C<value-changed> is emitted 250 milliseconds after a change.

=item C<"discontinuous">

C<value-changed> is not emitted at all during the drag, only at the end
(button release or C<stop> function).

=item secret default policy

C<value-changed> is emitted after a sync with the server (implemented
without blocking, see L<Gtk2::Ex::SyncCall>) followed by reaching idle in
the main loop, or at a 250 ms timeout if idle is not reached.

This is designed to be a compromise between smoothness and excessive
drawing.  The sync avoids hammering the server, then the idle waits to avoid
excessive work on the client side, but with the timeout cutting it short to
guarantee updates are not deferred indefinitely.

=back

Choosing a policy is a matter of how good the drawing in your target widget
is.  You can see the difference in the example programs included in the
sources which draw a big block of text in a C<Gtk2::TextView> versus a
Viewport plus C<Gtk2::Label>.  The TextView goes very close to coping with
C<continuous> update policy, but the same on the Label's simple-minded
drawing floods the server to the point of being unusable.

Dragger recognises C<pointer-motion-hint-mask> on the target widget (or
rather the motion event C<is_hint>) and knows to do a
C<< $widget->get_pointer >> for current position and further events.  That's
a deliberate server round-trip on each move, with the effect that each
motion waits until the drawing etc from the previous one has finished.
Generally you can set C<update_policy> to C<continuous> in this case.  Give
it a try if you're having trouble with excessive drawing or excessive
network traffic with full motion events.  For the drawing, the Dragger
default C<update_policy> is meant to achieve the same effect asynchronously.

It's a bit unfortunate that an update policy is part of a controller like a
scrollbar or dragger.  It'd be better if redraw frequency were left to the
widgets which are actually redrawing; or at least to an adaptor like a
Viewport for those without their own understanding.

=head1 OTHER NOTES

Some good choices for the C<cursor> while dragging are

    fleur                4-way arrow
    double-arrow         horizontal 2-way
    sb-h-double-arrow    horizontal 2-way
    sb-v-double-arrow    vertical 2-way

There's not much in the standard cursors for a grasping hand so you probably
have to make something like that from a pixmap.

Currently only a weak reference is kept to the target widget, so the fact
there's a dragger feature doesn't keep it alive forever.  This means in
particular it's safe to hold the dragger object in the widget instance data
without creating a circular reference.  But strong references are kept to
the adjustment objects since they probably should stay alive as long as the
widget and dragger do.  But perhaps this will change.

Having the C<button-motion-mask> and C<button-release-mask> set before the
drag won't normally cost very many extra events.

A missed release event can't be properly handled after the fact.
A C<get_pointer> can say whether the button is now down, but it may be the
user pressing elsewhere, and the x,y position of the drag release has been
completely lost.  That final release position is quite important.  If the
application is lagged you still want press/drag/release to move the widget
contents by the corresponding distance.  It's wrong and quite annoying if
the contents jump to where the mouse has gone after release.  The scrollbars
in some versions of mozilla for instance do that wrongly.

It'd be possible for the dragger to turn on C<button-motion-mask> when
starting the drag, if not already on, using an active grab and a
C<< $display->get_pointer >> to check for any missed movement.  But for now
that doesn't seem worthwhile, not while the release mask can't be similarly
adapted.

=head1 BUILDABLE

C<Gtk2::Ex::Dragger> can be built in a C<Gtk2::Builder> spec the same as any
other C<Glib::Object>.  The class name is "Gtk2__Ex__Dragger" as usual for
Perl-Gtk package name to class name conversion.  The target C<widget>,
C<hadjustment> and C<vadjustment> properties can be set to objects created
in the spec, for example

  <object class="Gtk2__Ex__Dragger" id="dragger">
    <property name="widget">viewport</property>
    <property name="hadjustment">hadjustment</property>
    <property name="vadjustment">vadjustment</property>
  </object>

See F<examples/builder.pl> in the Gtk2-Ex-Dragger sources for a complete
program.  Or F<examples/builder-internal.pl> shows how to connect up to
adjustment objects offered as "internal children" of a widget (which is a
handy way to expose what a widget creates, though no Gtk core widgets do
it).

=head1 SEE ALSO

L<Gtk2::Adjustment>, L<Gtk2::Ex::WidgetCursor>, L<Gtk2::Viewport>,
L<Gtk2::ScrolledWindow>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-dragger/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Dragger.  If not, see L<http://www.gnu.org/licenses/>.

=cut

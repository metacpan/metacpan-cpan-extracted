# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

our $VERSION = 22;

# In each CrossHair the private fields are
#
#   xy_widget
#       The widget to report in the 'moved' signal, or undef.
#
#   root_x,root_y
#       The current or pending x,y of the crosshair in root coordinates.
#       root_x is undef if the crosshair is outside any widget and therefore
#       not to be drawn (in "keyboard" mode rather than implicit-grab button
#       mode).
#
#       xy_widget and root_x,root_y are set immediately by _maybe_move() for
#       a mouse motion etc, but the actual drawing of them is later in the
#       sync_call_handler().
#
#   wcursor
#       Gtk2::Ex::WidgetCursor object putting an invisible cursor in the
#       crosshair widgets.
#
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
  properties => [ Glib::ParamSpec->scalar
                  ('widgets',
                   'Widgets',
                   'Arrayref of widgets to act on.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('widget',
                   'Widget',
                   'Single widget to act on.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('add-widget',
                   'Add widget',
                   'Add a widget to act on.',
                   'Gtk2::Widget',
                   'writable'),

                  Glib::ParamSpec->boolean
                  ('active',
                   'Active',
                   'Whether to display the crosshair.',
                   0,
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('foreground',
                   (do { # translation from Gtk2::TextTag
                     my $str = 'Foreground colour';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'The colour to draw the crosshair, either a string name (including hex RGB), a Gtk2::Gdk::Color, or undef for the widget\'s style foreground.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('foreground-name',
                   (do { # translation from Gtk2::TextTag
                     my $str = 'Foreground colour name';
                     eval { require Locale::Messages;
                            Locale::Messages::dgettext('gtk20-properties',$str)
                            } || $str }),
                   'The colour to draw the crosshair, as a string colour name.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boxed
                  ('foreground-gdk',
                   'Foreground colour object',
                   'The colour to draw the crosshair, as a Gtk2::Gdk::Color object with red,greed,blue fields set (a pixel is looked up on each target widget).',
                   'Gtk2::Gdk::Color',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('line-width',
                   'Line width',
                   'The width of the cross lines drawn.',
                   0, POSIX::INT_MAX(),  # limits
                   0,                    # default
                   Glib::G_PARAM_READWRITE),
                ];


sub INIT_INSTANCE {
  my ($self) = @_;
  ### CrossHair INIT_INSTANCE
  $self->{'button'} = 0;
  $self->{'widgets'} = [];
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### CrossHair finalize: "$self"
  $self->end;
}

sub _pw_list {
  my ($self) = @_;
  return values %{$self->{'perwidget'}};
}
sub _pw {
  my ($self, $widget) = @_;
  ### _pw: "@{[$widget||'[undef]']}"
  return $self->{'perwidget'}->{refaddr($widget)};
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### CrossHair GET_PROPERTY: $pname

  if ($pname eq 'widget') {
    my $widgets = $self->{'widgets'};
    if (@$widgets > 1) {
      croak 'Cannot get single \'widget\' property when using multiple widgets';
    }
    return $widgets->[0];
  }
  if ($pname eq 'foreground_name') {
    my $foreground = $self->{'foreground'};
    if (Scalar::Util::blessed($foreground)
        && $foreground->isa('Gtk2::Gdk::Color')) {
      $foreground = $foreground->to_string; # string "#RRRRGGGGBBBB"
    }
    return $foreground;
  }
  if ($pname eq 'foreground_gdk') {
    my $foreground = $self->{'foreground'};
    ### $foreground
    if (defined $foreground
        && ! Scalar::Util::blessed($foreground)) {
      # Perl-Glib 1.220 doesn't copy a boxed return like Gtk2::Gdk::Color,
      # must keep the block of memory in a field
      $foreground = $self->{'_foreground_gdk'}
        = Gtk2::Gdk::Color->parse($foreground);
    }
    return $foreground;
  }
  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};
  ### CrossHair SET_PROPERTY: $pname

  if ($pname eq 'widget') {
    $pname = 'widgets';
    $newval = [ $newval ];
    $self->notify ('widgets');
  } elsif ($pname eq 'add_widget') {
    $pname = 'widgets';
    $newval = [ @{$self->{'widgets'}}, $newval ];
    $self->notify ('widget');
    $self->notify ('widgets');
  }

  if ($pname eq 'widgets') {
    my $widgets = $newval;
    ### old widgets: "$self->{'widgets'}   @{$self->{'widgets'}}"
    ### new widgets: "$widgets   @$widgets"

    _undraw ($self);

    my $old_perwidget = $self->{'perwidget'};
    my %new_perwidget;
    $self->{'perwidget'} = \%new_perwidget;

    foreach my $widget (@$widgets) {
      my $key = refaddr($widget);
      ### perwidget key: refaddr($widget)
      unless ($new_perwidget{$key} = $old_perwidget->{$key}) {
        _pw_new($self,$widget);
      }
    }
    undef $old_perwidget; # discard pw's of old widgets
    ### perwidget keys now: keys %{$self->{'perwidget'}}

    @{$self->{'widgets'}} = @$newval;  # copy contents

    my $xy_widget = $self->{'xy_widget'};
    my $root_x = $self->{'root_x'};
    my $root_y = $self->{'root_y'};
    if ($xy_widget && ! _pw($self,$xy_widget)) {
      ### xy_widget removed
      unless ($self->{'xy_widget'} = $xy_widget = List::Util::first
              {_widget_contains_root_xy ($_, $root_x, $root_y)} @$widgets) {
        # no drawing when not in any widget, per _do_leave_notify()
        undef $root_x;
        undef $root_y;
      }
    }
    _maybe_move ($self, $xy_widget, $root_x, $root_y);
    _wcursor_update ($self); # new widget set
    $self->notify ('widget');

    ### now widgets: "$self->{'widgets'}   @{$self->{'widgets'}}"
    return;
  }

  if ($pname eq 'active') {
    # the extra '$self->notify' calls by running 'start' and 'end' here are
    # ok, Glib suppresses duplicates while in SET_PROPERTY
    if ($newval && ! $oldval) {
      $self->start;
    } elsif ($oldval && ! $newval) {
      $self->end;
    }

  } elsif ($pname =~ /^foreground/ || $pname eq 'line_width') {
    if ($pname =~ /^foreground/) {
      # must copy if 'foreground_gdk' since $newval points to a malloced
      # copy or something, copy scalar 'foreground' too just in case
      if (Scalar::Util::blessed($newval)
          && $newval->isa('Gtk2::Gdk::Color')) {
        $newval = $newval->copy;
      }
      $pname = 'foreground';
      $self->notify('foreground');
      $self->notify('foreground-name');
      $self->notify('foreground-gdk');
    }
    _undraw ($self);
    foreach my $pw (_pw_list($self)) {
      delete $pw->{'gc'}; # new gc's for colour or width
    }
    $self->{$pname} = $newval;
    _draw ($self);
  }

  $self->{$pname} = $newval;  # per default GET_PROPERTY
}

sub _pw_new {
  my ($self, $widget) = @_;
  ### _pw_new(): "$widget"

  # These are events needed in button drag mode, ie. when start() is called
  # with a button event.  The alternative would be to turn them on by a new
  # Gtk2::Gdk->pointer_grab() to change the implicit grab, though
  # 'button-release-mask' is best turned on in advance in case we're lagged
  # and it happens before we change the event mask.
  #
  # 'exposure-mask' is not here since if nothing else is drawing then
  # there's no need for the crosshair to redraw over its changes.

  require Gtk2::Ex::WidgetEvents;
  my $wevents = Gtk2::Ex::WidgetEvents->new
    ($widget, ['button-motion-mask',
               'button-release-mask',
               'pointer-motion-mask',
               'enter-notify-mask',
               'leave-notify-mask']);

  my $ref_weak_self = Gtk2::Ex::Xor::_ref_weak ($self);
  $self->{'perwidget'}->{refaddr($widget)}
    = { wevents => $wevents,
        static_ids => Glib::Ex::SignalIds->new
        ($widget, $widget->signal_connect (style_set => \&_do_style_set,
                                           $ref_weak_self)),
      };

  if ($self->{'active'}) {
    _pw_start ($self, $widget);
    _draw ($self, [$widget]);
  }
}

sub start {
  my ($self, $event) = @_;
  ### CrossHair start()

  my $button = $self->{'button'} = (ref $event && $event->can('button')
                                    ? $event->button : 0);
  if ($self->{'active'}) { return; }

  $self->{'active'} = 1;
  my $widgets = $self->{'widgets'};
  _wcursor_update ($self);

  # initial root_x,root_y from event if given, or by round trip on the first
  # realized of $widgets otherwise
  #
  my ($root_x, $root_y);
  if (ref $event) {
    ($root_x, $root_y) = $event->root_coords;
  } else {
    foreach my $widget (@$widgets) {
      my $root_window = $widget->get_root_window || next;
      ### root_window: "$root_window"
      (undef, $root_x, $root_y) = $root_window->get_pointer;
      last;
    }
  }
  ### root x,y: $root_x, $root_y

  my $xy_widget;
  if ($button) {
    # button mode, use reported event widget as $xy_widget, if it's one of
    # ours
    my $eventwidget = Gtk2->get_event_widget ($event);
    $xy_widget = List::Util::first {$_ == $eventwidget} @$widgets;

  } elsif (defined $root_x) {
    # Non-button mode, initial $xy_widget as whichever of $widgets contains
    # the pointer, if any.  After this enter and leave events maintain.
    $xy_widget = List::Util::first
      {_widget_contains_root_xy ($_, $root_x, $root_y)} @$widgets;
    if (! defined $xy_widget) {
      # no drawing when not in any widget, per _do_leave_notify()
      undef $root_x;
      undef $root_y;
    }
  }

  $self->{'xy_widget'} = $xy_widget;
  $self->{'root_x'} = $root_x;
  $self->{'root_y'} = $root_y;

  foreach my $widget (@$widgets) {
    _pw_start ($self, $widget);
  }

  $self->notify('active');
  _sync_call_handler (\$self); # initial drawing immediately
}

sub _wcursor_update {
  my ($self) = @_;
  ### CrossHair _wcursor_update(): "$self"
  $self->{'wcursor'} = $self->{'active'} && do {
    require Gtk2::Ex::WidgetCursor;
    Gtk2::Ex::WidgetCursor->new
        (widgets => $self->{'widgets'},
         cursor  => 'invisible',
         active  => 1)
      };
}

sub _pw_start {
  my ($self, $widget) = @_;
  ### CrossHair _pw_start(): "$widget"

  my $ref_weak_self = Gtk2::Ex::Xor::_ref_weak ($self);
  _pw($self,$widget)->{'dynamic_ids'} = Glib::Ex::SignalIds->new
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
}

sub end {
  my ($self) = @_;
  if (! $self->{'active'}) { return; }

  $self->signal_emit ('moved', undef, undef, undef);
  _undraw ($self);
  foreach my $pw (_pw_list($self)) {
    delete $pw->{'dynamic_ids'};
  }
  $self->{'active'} = 0;
  _wcursor_update ($self);
  $self->notify('active');
}


#-----------------------------------------------------------------------------

# 'motion-notify-event' on a target widget
sub _do_motion_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_motion_notify(): "$widget " . $event->x_root . "," . $event->y_root
  if (my $self = $$ref_weak_self) {
    if ($self->{'active'}) {
      _maybe_move ($self, $widget, _event_root_coords ($event));
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
  _undraw ($self, [$widget]);
  _draw ($self, [$widget]);
}

# 'enter-notify-event' signal on the widgets
sub _do_enter_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_enter_notify(): "$widget " . $event->x_root . "," . $event->y_root
  if (my $self = $$ref_weak_self) {
    if (! $self->{'button'}) {
      # not button drag mode
      _maybe_move ($self, $widget, $event->root_coords);
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'leave-notify-event' signal on one of the widgets
sub _do_leave_notify {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_leave_notify(): "$widget " . $event->x_root . "," . $event->y_root
  if (my $self = $$ref_weak_self) {
    if (! $self->{'button'}) {
      # not button drag mode
      _maybe_move ($self, undef, undef, undef);
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'button-release-event' signal on one of the widgets
sub _do_button_release {
  my ($widget, $event, $ref_weak_self) = @_;
  if (my $self = $$ref_weak_self) {
    if ($event->button == $self->{'button'}) {
      $self->end ($event);
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

sub _maybe_move {
  my ($self, $widget, $root_x, $root_y) = @_;
  #### _maybe_move: "@{[$widget||'[undef]']}", $root_x, $root_y

  $self->{'xy_widget'} = $widget;
  $self->{'root_x'} = $root_x;
  $self->{'root_y'} = $root_y;

  $self->{'sync_call'} ||= do {
    require Gtk2::Ex::SyncCall;
    ### new SyncCall on: "$self->{'widgets'}->[0]"
    if (my $widget = List::Util::first {$_->realized} @{$self->{'widgets'}}) {
      Gtk2::Ex::SyncCall->sync ($widget,
                                \&_sync_call_handler,
                                Gtk2::Ex::Xor::_ref_weak ($self));
    } else {
      $self->signal_emit ('moved', undef, undef, undef);
      undef;
    }
  };
}
sub _sync_call_handler {
  my ($ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### CrossHair _sync_call_handler()

  $self->{'sync_call'} = undef;
  if (! $self->{'active'}) { return; }  # turned off before sync returned

  _undraw ($self);  # erase old
  _draw ($self);    # draw new

  my ($xy_widget, $x, $y);
  if ($xy_widget = $self->{'xy_widget'}) {
    ($x, $y) = @{_pw($self,$xy_widget)}{'x','y'};
  }
  $self->signal_emit ('moved', $xy_widget, $x, $y);
}

sub _do_expose_event {
  my ($widget, $event, $ref_weak_self) = @_;
  ### CrossHair _do_expose_event()
  if (my $self = $$ref_weak_self) {
    _draw ($self, [$widget], $event->region);
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

sub _undraw {
  my ($self, $widgets) = @_;
  $widgets ||= $self->{'widgets'};
  ### _undraw(): "@$widgets"

  my @widgets = grep { exists(_pw($self,$_)->{'x'}) } @$widgets;
  _draw ($self, \@widgets);
  foreach my $widget (@widgets) {
    # position undetermined as well as undrawn
    delete _pw($self,$widget)->{'x'};
  }
  ### _undraw() done
}

# $widgets is an arrayref of widgets to draw, or undef for all
sub _draw {
  my ($self, $widgets, $clip_region) = @_;
  $self->{'active'} || return;
  $widgets ||= $self->{'widgets'};
  my $root_x = $self->{'root_x'};
  my $root_y = $self->{'root_y'};

  foreach my $widget (@$widgets) {
    ### _draw(): "$widget"
    my $pw = _pw($self,$widget);
    my $win = $widget->Gtk2_Ex_Xor_window || next; # perhaps unrealized

    if (! exists $pw->{'x'}) {
      ### establish draw position: "$widget", $root_x, $root_y
      @{$pw}{'x','y'}
        = (defined $root_x
           ? Gtk2::Ex::WidgetBits::xy_root_to_widget ($widget, $root_x, $root_y)
           : ());
      ### at: $pw->{'x'}, $pw->{'y'}
    }

    my $x = $pw->{'x'};
    if (! defined $x) { next; }
    my $y = $pw->{'y'};

    my $gc = ($pw->{'gc'} ||= do {
      ### create gc
      my $line_width = $self->get('line_width');
      my $line_style = $self->{'line_style'} || 'double-dash';
      Gtk2::Ex::Xor::shared_gc
          (widget         => $widget,
           foreground_xor => $self->{'foreground'},
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
}

# 'style-set' signal handler on each widget
# A style change normally provokes a full redraw.  Think it's enough to rely
# on that for redrawing the crosshair against a possible new background, so
# just refresh the gc.
sub _do_style_set {
  my ($widget, $prev_style, $ref_weak_self) = @_;
  ### CrossHair _do_style_set: "$widget"
  my $self = $$ref_weak_self || return;
  delete _pw($self,$widget)->{'gc'}; # possible new colour
}


#------------------------------------------------------------------------------
# generic helpers

sub _event_root_coords {
  my ($event) = @_;

  # Do a get_pointer() to support 'pointer-motion-hint-mask'.
  # Maybe should use $display->get_state here instead of just get_pointer,
  # but crosshair and lasso at present only work with the mouse, not an
  # arbitrary input device.
  if ($event->can('is_hint')
      && $event->is_hint
      && (my $window = $event->window)) {
    return ($window->get_screen->get_root_window->get_pointer)[1,2];
  } else {
    return $event->root_coords;
  }
}

# Return true if $x,$y in root window coordinates is within $widget's
# allocated rectangle.
# FIXME: Would like to exclude parts of $widget which are overlapped by
# other widgets and/or windows.
#
sub _widget_contains_root_xy {
  my ($widget, $root_x, $root_y) = @_;
  my ($wx, $wy) = Gtk2::Ex::WidgetBits::xy_root_to_widget ($widget, $root_x, $root_y)
    or return 0;  # $widget unrealized
  return _widget_contains_xy ($widget, $wx, $wy);
}

# Return true if $x,$y in widget coordinates is within $widget's allocated
# rectangle.  The rectangle $widget->allocation gives the size (its x,y
# position relative to the windowed parent is ignored).
#
sub _widget_contains_xy {
  my ($widget, $x, $y) = @_;
  ### _widget_contains_xy(): $x,$y
  return ($x >= 0 && $y >= 0
          && do {
            my $alloc = $widget->allocation;
            $x < $alloc->width && $y < $alloc->height });
}

# sub _rect_contains_xy {
#   my ($rect, $x) = @_;
#   return ($rect->x <= $x
#           && $rect->y <= $y
#           && $rect->x + $rect->width  >= $x
#           && $rect->y + $rect->height >= $y);
# }

# sub _xy_widget_to_root {
#   my ($widget, $x, $y) = @_;
#   my ($root_x, $root_y) = Gtk2::Ex::WidgetBits::get_root_position ($widget);
#   if (! defined $root_x) {
#     return;  # if $widget unrealized
#   } else {
#     return ($root_x + $x, $root_y + $y);
#   }
# }

# _widget_translate_coordinates_toplevel() is the same as
# gtk_widget_translate_coordinates, but allows widgets $src and $dst to be
# under different toplevels.
#
# sub _widget_translate_coordinates_toplevel {
#   my ($src, $dst, $x, $y) = @_;
#   if (my @ret = $src->translate_coordinates ($dst, $x, $y)) {
#     return @ret;
#   }
#   require Gtk2::Ex::WidgetBits;
#   my ($src_x, $src_y) = Gtk2::Ex::WidgetBits::get_root_position ($src);
#   if (! defined $src_x) {
#     # $src not realized
#     return;
#   }
#   my ($dst_x, $dst_y) = Gtk2::Ex::WidgetBits::get_root_position ($dst);
#   if (! defined $dst_x) {
#     # $dst not realized
#     return;
#   }
#   return ($src_x + $x - $dst_x,
#           $src_y + $y - $dst_y);
# }


#------------------------------------------------------------------------------


# Not sure about these yet:
#
#                   Glib::ParamSpec->enum
#                   ('line-style',
#                    'line-style',
#                    'blurb',
#                    'Gtk2::Gdk::LineStyle',
#                    DEFAULT_LINE_STYLE,
#                    Glib::G_PARAM_READWRITE),
#
# =item C<line_style> (default C<on-off-dash>)
#
# Attributes for the graphics context (C<Gtk2::Gdk::GC>) used to draw.  New
# settings here only take effect on the next C<start>.  For example,
#
#     $crosshair->{'line_style'} = 'solid';



1;
__END__

=for stopwords crosshair CrossHair WidgetCursor xors Gtk2-Ex-Xor Eg keypress boolean arrayref toplevel userdata eg BUILDABLE colormap crosshaired Ryde

=head1 NAME

Gtk2::Ex::CrossHair -- crosshair lines drawn following the mouse

=for test_synopsis my ($w1, $w2, $event)

=head1 SYNOPSIS

 use Gtk2::Ex::CrossHair;
 my $crosshair = Gtk2::Ex::CrossHair->new (widgets => [$w1,$w2]);
 $crosshair->signal_connect (moved => sub { print_pos() });

 $crosshair->start ($event);
 $crosshair->end ();

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::CrossHair> is a subclass of C<Glib::Object>.

    Glib::Object
      Gtk2::Ex::CrossHair

=head1 DESCRIPTION

A CrossHair object draws a horizontal and vertical line through the mouse
pointer position on top of one or more widgets' existing contents.  This is
intended as a visual guide for the user.

        +-----------------+
        |         |       | +-----------------+
        |         | mouse | |                 |
        |         |/      | |                 |
        | --------+------ | | --------------- |
        |         |       | |                 |
        |         |       | |                 |
        |         |       | +-----------------+
        |         |       |
        +-----------------+

The idea is to help see relative positions.  For example in a graph the
horizontal line helps you see which of two peaks is the higher, and the
vertical line can extend down to (or into) an X axis scale to see where
exactly a part of the graph lies.

The C<moved> callback lets you update a text status line with a position in
figures, etc (if you don't already display something like that following the
mouse all the time).

When the crosshair is active the mouse cursor is set invisible in the target
windows since the cross is enough feedback and a cursor tends to obscure the
lines.  This is done with the WidgetCursor mechanism (see
L<Gtk2::Ex::WidgetCursor>) and so cooperates with other module or
application uses of that.

The crosshair is drawn using xors in the widget window (see
L<Gtk2::Ex::Xor>).  See the F<examples> directory in the Gtk2-Ex-Xor sources
for some variously contrived complete programs.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::CrossHair->new (key => value, ...) >>

Create and return a new CrossHair object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.  Eg.

    my $ch = Gtk2::Ex::CrossHair->new (widgets => [ $widget ],
                                       foreground => 'orange');

=item C<< $crosshair->start () >>

=item C<< $crosshair->start ($event) >>

=item C<< $crosshair->end () >>

Start or end crosshair display.

For C<start> the optional C<$event> is a C<Gtk2::Gdk::Event>.  If C<$event>
is a mouse button press then the crosshair is active as long as that button
is pressed.  If C<$event> is a keypress, or C<undef>, or omitted, then the
crosshair is active until explicitly stopped with an C<end> call.

=back

=head1 PROPERTIES

=over 4

=item C<active> (boolean)

True when the crosshair is to be drawn, moved, etc.  Turning this on or off
is the same as calling C<start> or C<end> above, except you can't pass a
button press event.

=item C<widgets> (array of C<Gtk2::Widget>)

An arrayref of widgets to draw on.  Often this will be just one widget, but
multiple widgets can be given to draw in all of them at the same time.

The widgets can be under different toplevel windows, but they should be all
on the same screen (L<C<Gtk2::Gdk::Screen>|Gtk2::Gdk::Screen>) since mouse
pointer movement in any of them is taken to be a position to draw through
all of them (with coordinates translated appropriately).

=item C<widget> (C<Gtk2::Widget> or C<undef>)

A single widget to operate on.  The C<widget> and C<widgets> properties
access the same underlying set of widgets to operate on, you can set or get
whichever best suits.  But if there's more than one widget you can't get
from the single C<widget>.

=item C<add-widget> (C<Gtk2::Widget>, write-only)

Add a widget to those in the crosshair.  This is good for use from
C<Gtk2::Builder> where a C<widgets> arrayref cannot be set.

=item C<foreground> (colour scalar, default C<undef>)

=item C<foreground-name> (string, default C<undef>)

=item C<foreground-gdk> (C<Gtk2::Gdk::Color> object, default C<undef>)

The colour for the crosshair.  This can be

=over 4

=item *

C<undef> (the default) for the widget style C<fg> foreground colour in each
widget (see L<Gtk2::Style>).

=item *

A string colour name or #RGB form per C<< Gtk2::Gdk::Color->parse >> (see
L<Gtk2::Gdk::Color>).

=item *

A C<Gtk2::Gdk::Color> object with C<red>, C<green>, C<blue> fields set.
(A pixel value will be looked up in each widget.)

=back

All three C<foreground>, C<foreground-name> and C<foreground-gdk> access the
same underlying setting.  C<foreground-name> and C<foreground-gdk> exist for
use with C<Gtk2::Builder> where the generic scalar C<foreground> property
can't be set.

In the current code, if the foreground is a C<Gtk2::Gdk::Color> object then
C<foreground-name> reads as its C<to_string> like "#11112222333", or if
foreground is a string name then C<foreground-gdk> reads as parsed to a
C<Gtk2::Gdk::Color>.  Is this a good idea?  Perhaps it will change in the
future.

=item C<line-width> (integer, default 0)

The width in pixels of the crosshair lines.  The default 0 means a 1-pixel
"fast" line.  Usually 1 pixel is enough but 2 or 3 may make the lines more
visible on a high resolution screen.

=back

=head1 SIGNALS

=over 4

=item moved (parameters: crosshair, widget, x, y, userdata)

Emitted when the crosshair moves to the given C<$widget> and at X,Y
coordinates within that widget (widget relative coordinates).  C<$widget> is
C<undef> if the mouse moves outside any of the crosshair widgets.

It's worth noting a subtle difference in C<moved> reporting when a crosshair
is activated from a button or from the keyboard.  A button press causes an
implicit grab and all events are reported to that widget's window.  C<moved>
then gives that widget and an X,Y position which might be outside the window
area (eg. negative).  But for a keyboard or programmatic start C<moved>
reports the widget currently containing the mouse, or C<undef> when not in
any.  Usually the button press grab is good thing, it means a dragged button
keeps reporting about the original window.

=back

=head1 BUILDABLE

CrossHair can be created from C<Gtk2::Builder> the same as other objects.
The class name is C<Gtk2__Ex__CrossHair> and it will normally be a top-level
object with the C<widget> property telling it what to act on.

    <object class="Gtk2__Ex__CrossHair" id="mycross">
      <property name="widget">drawingwidget</property>
      <property name="foreground-name">orange</property>
      <signal name="moved" handler="do_cross_moved"/>
    </object>

See F<examples/cross-builder.pl> in the Gtk2-Ex-Xor sources for a complete
program.

The C<foreground-name> property is the best way to control the colour.  The
generic C<foreground> can't be used because it's a Perl scalar type.  The
C<foreground-gdk> works since C<Gtk2::Builder> knows how to parse a colour
name to a C<Gtk2::Gdk::Color> object, but in that case the Builder also
allocates a pixel in the default colormap, which is unnecessary since the
CrossHair will do that itself on the target widget's colormap.

=head1 BUGS

C<no-window> widgets don't work properly, but instead should be put in a
C<Gtk2::EventBox> or similar windowed widget and that passed to the
crosshair.

Parent window movement, including toplevel window movement, isn't noticed
immediately, leaving the drawn crosshair away from the mouse.  The next
mouse movement updates all widgets though, and often parent widget moves
provoke a redraw which will update the crosshair anyway.

If a crosshair widget's window is partly overlapped by another window then a
keyboard mode start with the pointer in that other window isn't recognised
as outside the crosshair window.  This results in an initial draw but then
no updating until the pointer moves into the crosshaired window.  It should
be possible to do this correctly.

=head1 SEE ALSO

L<Gtk2::Ex::Lasso>, L<Gtk2::Ex::Xor>, L<Glib::Object>,
L<Gtk2::Ex::WidgetCursor>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-xor/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Xor.  If not, see L<http://www.gnu.org/licenses/>.

=cut

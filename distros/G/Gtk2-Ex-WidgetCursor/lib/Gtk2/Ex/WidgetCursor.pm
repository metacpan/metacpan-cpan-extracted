# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::WidgetCursor;
use 5.006;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util;
use POSIX ();
use Scalar::Util 1.18; # 1.18 for pure-perl refaddr() fix

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 15;

# Gtk 2.2 for get_display()
# could work without it, but probably not worth bothering
Gtk2->CHECK_VERSION(2,2,0)
  or die "WidgetCursor requires Gtk 2.2 or higher";


#------------------------------------------------------------------------------
# Cribs on widgets using gdk_window_set_cursor directly:
#
# GtkAboutDialog  [not handled]
#     Puts "email" and "link" tags on text in the credits GtkTextView and
#     then does set_cursor on entering or leaving those.
#
# GtkCombo        [ok mostly, with a hack]
#     Does a single set_cursor for a 'top-left-arrow' on a GtkEventBox in
#     its popup when realized.  We dig that out for include_children,
#     primarily so a busy() shows the watch on the popup window if it
#     happens to be open.  Of course GtkCombo is one of the ever-lengthening
#     parade of working and well-defined widgets which Gtk says you're not
#     meant to use any more.
#
# GtkCurve        [not handled]
#     Multiple set_cursor calls according to mode and motion.  A rarely used
#     widget so ignore it for now.
#
# GtkEntry        [ok, with a hack]
#     An Entry uses a private GdkWindow subwindow 4 pixels smaller than the
#     main and sets a GDK_CURSOR_XTERM there when sensitive.  That window
#     isn't presented in the public fields/functions but can be dug out from
#     $win->get_children.  We set the cursor on both the main window and the
#     subwindow then have a hack to restore the insertion point cursor on
#     the latter when done.  Getting the subwindow is fast since Gtk
#     maintains the list of children for gdk_window_get_children() itself
#     (as opposed to the way plain Xlib queries the server).
#
#     The Entry can be made to restore the insertion cursor by toggling
#     'sensitive'.  Hard to know which is worse: toggling sensitive
#     needlessly, or forcibly setting the cursor back.  The latter is needed
#     for the SpinButton subclass below, so it's easier to do that.
#
# GtkFileChooser  [probably ok]
#     Sets a GDK_CURSOR_WATCH temporarily when busy.  That probably kills
#     any WidgetCursor setting, but probably GtkFileChooser isn't something
#     you'll manipulate externally.
#
# GtkLabel        [not handled]
#     Puts GDK_XTERM on a private selection window when sensitive and
#     selectable text, or something.  This misses out on include_children
#     for now.
#
# GtkLinkButton   [not very good]
#     A GtkButton subclass which does 'hand' set_cursor on its windowed
#     parent for enter and leave events on its input-only event window.
#
#     The cursor applied to the event window (per GtkButton above) trumps
#     the hand on the parent, so that gets the right effect.  But any
#     WidgetCursor setting on the parent is lost when LinkButton turns off
#     its hand under a leave-event.  Might have to make a hack connecting to
#     leave-event and re-applying the parent window.
#
# GtkPaned        [not handled]
#     Puts a cursor on its GdkWindow handle when sensitive.  Not covered by
#     include_children for now.
#
# GtkRecentChooser  [probably ok]
#     A GDK_WATCH when busy, similar to GtkFileChooser above.  Hopefully ok
#     most of the time with no special attention.
#
# GtkSpinButton   [imperfect]
#     Subclass of GtkEntry, but adds a "panel" window of arrows.  In Gtk
#     2.12 it was overlaid on the normal Entry widget window, ie. the main
#     outer one.  In Gtk 2.14 it's a child of that outer window.
#
#     For 2.12 it can be dug out by looking for sibling windows with events
#     directed to the widget.  Then it's a case of operating on three
#     windows: the Entry main, the Entry 4-pixel smaller subwindow and the
#     SpinButton panel.
#
#     As of Gtk 2.12 toggling sensitive doesn't work to restore the
#     insertion point cursor for a SpinButton, unlike its Entry superclass.
#     Something not chaining up presumably, so the only choice is to
#     forcibly put the cursor back.
#
# GtkStatusBar    [not handled]
#     A cursor on its private grip GdkWindow.
#
# GtkTextView     [ok]
#     Sets a GDK_XTERM insertion point cursor on its get_window('text')
#     sub-window when sensitive.  We operate on the get_window('widget') and
#     get_window('text') both.
#
#     Toggling sensitive will put back the insertion point cursor, like for
#     a GtkEntry above, and like for the Entry it's hard to know whether
#     it's worse to toggle sensitive or forcibly set back the cursor.  For
#     now the latter can share code with Entry and SpinButton and thus is
#     what's used.
#


#------------------------------------------------------------------------------

use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->object
                  ('widget',
                   'widget',
                   'The widget to show the cursor in, if just one widget.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('widgets',
                   'widgets',
                   'An arrayref of widgets to show the cursor in.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('add-widget',
                   'add-widget',
                   'Pseudo-property to add a widget to the cursor in.',
                   'Gtk2::Widget',
                   ['writable']),

                  Glib::ParamSpec->scalar
                  ('cursor',
                   'cursor',
                   'Cursor to use while dragging, as any name or object accepted by Gtk2::Ex::WidgetCursor.',
                   Glib::G_PARAM_READWRITE),
                  #
                  # when glib 1.240 has fix for this pspec/get/set style
                  # {
                  #  pspec => ...,
                  #  get => \&cursor,
                  #  set => \&cursor,
                  # }

                  Glib::ParamSpec->string
                  ('cursor-name',
                   'cursor-name',
                   'Cursor to use while dragging, as cursor type enum nick plus "invisible".',
                   '',  # FIXME: default is undef when gtk2-perl allows that
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boxed
                  ('cursor-object',
                   'cursor-object',
                   'Cursor to use while dragging, as cursor object.',
                   'Gtk2::Gdk::Cursor',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('active',
                   'active',
                   'Whether to show this cursor.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),
                  # when glib 1.240 has fix for this pspec/get/set style
                  # {
                  #  pspec => '',
                  #  get => \&active,
                  #  set => \&active,
                  # }

                  Glib::ParamSpec->double
                  ('priority',
                   'priority',
                   'The priority of this cursor among multiple WidgetCursors on a given widget.  Higher numbers are higher priority.',
                   - POSIX::DBL_MAX(), # min
                   POSIX::DBL_MAX(),   # max
                   0,                  # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('include-children',
                   'include-children',
                   'Whether to apply the cursor to child widgets too.',
                   0, # default no
                   Glib::G_PARAM_READWRITE),

                ];

# @wobjs is all the WidgetCursor objects which currently exist, sorted from
# highest to lowest priority, and from newest to oldest among those of equal
# priority
#
# Elements are weakened so they don't keep the objects alive.  The DESTROY
# method strips elements and undefs from here, but not sure if undef could
# still be seen in here by certain funcs at certain times.
#
my @wobjs = ();

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'installed_widgets'} = [];
  _wobjs_insert ($self);
}
sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### FINALIZE_INSTANCE: "$self"
  _splice_out (\@wobjs, $self);
  if (delete $self->{'active'}) {
    _wobj_deactivated ($self);
  }
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  ### WidgetCursor GET_PROPERTY(): $pspec->get_name
  my $pname = $pspec->get_name;

  if ($pname eq 'cursor_name') {
    my $cursor = $self->{'cursor'};
    if (Scalar::Util::blessed($cursor)) {
      $cursor = $cursor->type;
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
  ### WidgetCursor SET_PROPERTY(): $pspec->get_name
  my $pname = $pspec->get_name;

  if ($pname eq 'active') {
    $self->active($newval);
    return;
  }
  if ($pname =~ /^cursor/) {
    $self->cursor($newval);
    return;
  }
  if ($pname eq 'add_widget') {
    $self->add_widgets ($newval);
    return;
  }

  if ($pname eq 'widget') {
    $pname = 'widgets';
    $newval = [ $newval ];
  }
  if ($pname eq 'widgets') {
    my @array;
    push @array, @$newval;
    foreach (@array) { Scalar::Util::weaken ($_); }
    $self->{'widgets'} = \@array;
    if ($self->{'active'}) {
      _wobj_activated ($self);
    }
    return;
  }

  $self->{$pname} = $newval;

  if ($pname eq 'priority') {
    _wobjs_insert ($self);
    if ($self->{'active'}) {
      _wobj_activated ($self);
    }
  }
}

# insert $self into @wobjs according to $self->{'priority'}
sub _wobjs_insert {
  my ($self) = @_;

  my $priority = ($self->{'priority'}||0);
  my $pos = 0;
  while ($pos < @wobjs) {
    # FINALIZE_INSTANCE removes on destroy, but beware of undef just in case
    if (my $wobj = $wobjs[$pos]) {
      if ($wobj == $self) {
        splice @wobjs,$pos,1;  # remove from old position
        next;
      }
      if ($priority >= ($wobj->{'priority'}||0)) {
        last;
      }
    }
    $pos++;
  }
  splice @wobjs,$pos,0, $self;
  Scalar::Util::weaken ($wobjs[$pos]);
}

# get or set "active"
sub active {
  my ($self, $newval) = @_;
  if (@_ < 2) { return $self->{'active'}; }  # get

  # set
  $newval = ($newval ? 1 : 0);  # don't capture arbitrary input
  my $oldval = $self->{'active'};
  $self->{'active'} = $newval;
  if ($oldval && ! $newval) {
    _wobj_deactivated ($self);
    $self->notify('active');
  } elsif ($newval && ! $oldval) {
    _wobj_activated ($self);
    $self->notify('active');
  }
}

# newly turned off or destroyed
sub _wobj_deactivated {
  my ($self) = @_;
  ### _wobj_deactivated()
  my $aref = $self->{'installed_widgets'};
  ### $aref
  $self->{'installed_widgets'} = [];
  foreach my $widget (@$aref) {
    _update_widget ($widget);
  }
}

# newly turned on or created on
sub _wobj_activated {
  my ($self) = @_;
  ### _wobj_activated()

  if ($self->{'include_children'}) {
    # go through widgets in other wobjs as well as ourselves since they may
    # be affected if they're children of one of ours (%done skips duplicates
    # among the lists)
    ### include_children other wobjs
    my %done;
    foreach my $wobj (@wobjs) {
      foreach my $widget (@{$wobj->{'widgets'}}) {
        if (! $widget) { next; } # possible undef by weakening
        $done{Scalar::Util::refaddr($widget)}
          ||= do { _update_widget ($widget); 1 };
      }
    }

    # special handling for children of certain types that might be present
    # deep in the tree
    ### include_children special TextView etc
    foreach my $widget (@{$self->{'widgets'}}) {
      if (! $widget) { next; } # possible undef by weakening

      foreach my $widget (_container_recursively ($widget)) {
        if ($widget->isa('Gtk2::Entry')
            || $widget->isa('Gtk2::TextView')
            || _widget_is_combo_eventbox ($widget)) {
          $done{Scalar::Util::refaddr($widget)}
            ||= do { _update_widget ($widget); 1 };
        }
      }
    }

  } else {
    # simple non-include-children for this wobj, look only at its immediate
    # widgets
    foreach my $widget (@{$self->{'widgets'}}) {
      _update_widget ($widget);
    }
  }
}

sub _update_widget {
  my ($widget) = @_;
  if (! $widget) { return; }  # possible undef from weakening
  ### _update_widget: "$widget", $widget->get_name

  # find wobj with priority on this $widget
  my $wobj = List::Util::first
    { $_->{'active'} && _wobj_applies_to_widget($_,$widget)} @wobjs;

  my $old_wobj = $widget->{__PACKAGE__.'.installed'};
  ### wobj was: defined $old_wobj && $old_wobj->{'cursor'}
  ### now:      defined $wobj     && $wobj->{'cursor'}
  ### window:   "@{[$widget->window||'undef']}"

  if (($wobj||0) == ($old_wobj||0)) { return; } # unchanged

  # forget this widget under $old_wobj
  if ($old_wobj) {
    _splice_out ($old_wobj->{'installed_widgets'}, $widget);
  }

  if (! $wobj) {
    # no wobj applies to this widget any more
    delete $widget->{__PACKAGE__.'.installed'};
    delete $widget->{__PACKAGE__.'.realize_ids'};

    my ($hack_win, $hack_cursor) = $widget->Gtk2_Ex_WidgetCursor_hack_restore;
    $hack_win ||= 0; # avoid undef
    foreach my $win ($widget->Gtk2_Ex_WidgetCursor_windows) {
      $win || next;
      my $cursor = ($win == $hack_win
                    ? Gtk2::Gdk::Cursor->new_for_display ($widget->get_display,
                                                          $hack_cursor)
                    : undef);
      ### set_cursor back to: "$win", $cursor && $cursor->type
      $win->set_cursor ($cursor);
    }
    return;
  }

  # install wobj on this widget

  # remember this widget under wobj
  # this is when unrealized too, so remember to cleanup realize handler
  { my $aref = $wobj->{'installed_widgets'};
    push @$aref, $widget;
    Scalar::Util::weaken ($aref->[-1]);
    ### gives installed_widgets: join(' ',@$aref)
  }

  # note this wobj under the widget
  $widget->{__PACKAGE__.'.installed'} = $wobj;
  Scalar::Util::weaken ($widget->{__PACKAGE__.'.installed'});

  my @windows = $widget->Gtk2_Ex_WidgetCursor_windows;
  if (! defined $windows[0]) {
    ### not realized, defer setting
    $widget->{__PACKAGE__.'.realize_ids'} ||= do {
      require Glib::Ex::SignalIds;
      Glib::Ex::SignalIds->new
          ($widget,
           $widget->signal_connect (realize => \&_do_widget_realize))
        };
    return;
  }

  # and finally actually set the cursor
  my $cursor = _resolve_cursor ($wobj, $widget);
  foreach my $win (@windows) {
    $win or next;
    ### set_cursor: "$win", $cursor && $cursor->type
    $win->set_cursor ($cursor);
  }
}

# 'realize' signal handler on a WidgetCursor affected widget
sub _do_widget_realize {
  my ($widget) = @_;
  ### _do_widget_realize(): "$widget"
  delete $widget->{__PACKAGE__.'.realize_ids'};
  _update_widget ($widget);
}


# Return true if $wobj is applicable to $widget, either because $widget is
# in its widgets list or is a child of one of them for "include_children".
# Note $w->is_ancestor($w) is false, ie. it doesn't include itself.
#
sub _wobj_applies_to_widget {
  my ($wobj, $widget) = @_;
  return List::Util::first
    { defined $_ # possible weakening during destroy
        && ($_ == $widget
            || ($wobj->{'include_children'} && $widget->is_ancestor($_))) }
      @{$wobj->{'widgets'}};
}

# get or set "cursor"
sub cursor {
  my ($self, $newval) = @_;
  if (@_ < 2) { return $self->{'cursor'}; }  # get

  # set
  if (_cursor_equal ($self->{'cursor'}, $newval)) { return; }
  $self->{'cursor'} = $newval;

  if ($self->{'active'}) {
    foreach my $widget (@{$self->{'installed_widgets'}}) {
      foreach my $win ($widget->Gtk2_Ex_WidgetCursor_windows) {
        $win || next;  # only if realized
        $win->set_cursor (_resolve_cursor ($self, $widget));
      }
    }
  }

  $self->notify('cursor');
  $self->notify('cursor-name');
  $self->notify('cursor-object');
}

# return true if two cursor settings $x and $y are the same
sub _cursor_equal {
  my ($x, $y) = @_;
  return ((! defined $x && ! defined $y)      # undef == undef
          || (ref $x && ref $y && $x == $y)   # objects identical address
          || (defined $x && defined $y && $x eq $y));  # strings by value
}

# get widgets in wobj
sub widgets {
  my ($self) = @_;
  return grep {defined} @{$self->{'widgets'}};
}

sub add_widgets {
  my ($self, @widgets) = @_;
  my $aref = $self->{'widgets'};

  # only those not already in our list
  @widgets = grep { my $widget = @_;
                    ! List::Util::first {defined $_ && $_==$widget}
                      @$aref } @widgets;
  if (! @widgets) { return; }

  foreach my $widget (@widgets) {
    push @$aref, $widget;
    Scalar::Util::weaken ($aref->[-1]);
  }

  if ($self->{'include_children'}) {
    # for include_children must have a deep look down through the new
    # widgets, let the full code of _wobj_activated() do that (though it's a
    # little wasteful to look again at the previously covered widgets)
    _wobj_activated ($self);

  } else {
    # for ordinary only the newly added widgets might change
    foreach my $widget (@widgets) {
      _update_widget ($widget);
    }
  }
  $self->notify('widget');
  $self->notify('widgets');
}

# return an actual Gtk2::Gdk::Cursor from what may be only a string setting
# in $wobj->{'cursor'}
sub _resolve_cursor {
  my ($wobj, $widget) = @_;
  my $cursor = $wobj->{'cursor'};

  if (! defined $cursor || ref $cursor) {
    # undef or cursor object
    return $cursor;

  } elsif ($cursor eq 'invisible') {
    # call through $wobj in case of subclassing
    return $wobj->invisible_cursor ($widget);

  } else {
    # string cursor name -- only ever call to resolve here when widget is
    # realized, so get_display() isn't undef
    if ($widget->can('get_display')) {
      # gtk 2.2 up
      my $display = $widget->get_display;
      return Gtk2::Gdk::Cursor->new_for_display ($display, $cursor);
    } else {
      # gtk 2.0.x
      return Gtk2::Gdk::Cursor->new ($cursor);
    }
  }
}

# Return $widget and all its contained children, grandchildren, etc.
# Iterative avoids deep recursion warning for the unlikely case of nesting
# beyond 100 deep.
#
sub _container_recursively {
  my @pending = @_;
  my @ret;
  while (@pending) {
    my $widget = pop @pending;
    push @ret, $widget;
    if (my $func = $widget->can('get_children')) {
      push @pending, $widget->$func;
    }
  }
  return @ret;
}

#------------------------------------------------------------------------------
# operative windows hacks
#
# $widget->Gtk2_Ex_WidgetCursor_windows() returns a list of windows in
# $widget to act on, with hacks to pickup multiple windows on core classes.
#
# $widget->Gtk2_Ex_WidgetCursor_hack_restore() returns ($win, $cursor).
# $cursor is a string cursor name to put back on $win when there's no more
# WidgetCursor objects.  Or the return is an empty list or $win undef when
# nothing to hack (in which case all windows go back to "undef" cursor).
#

# default to operate on $widget->window alone
*Gtk2::Widget::Gtk2_Ex_WidgetCursor_windows = \&Gtk2::Widget::window;
sub Gtk2::Widget::Gtk2_Ex_WidgetCursor_hack_restore { return (); }

# GtkEventBox under a GtkComboBox popup window has a 'top-left-arrow'.  It
# gets overridden by a special case in the recursive updates above, and
# hack_restore() here puts it back.
#
sub Gtk2::EventBox::Gtk2_Ex_WidgetCursor_hack_restore {
  my ($widget) = @_;
  return _widget_is_combo_eventbox($widget)
    && ($widget->window, 'top-left-arrow');
}

# GtkTextView operate on 'text' subwindow to override its insertion point
# cursor there, plus the main 'widget' window to cover the entire widget
# extent.  The 'text' subwindow insertion point is supposed to be on when
# the widget is sensitive, so hack_restore() that.
#
sub Gtk2::TextView::Gtk2_Ex_WidgetCursor_windows {
  my ($widget) = @_;
  return ($widget->get_window ('widget'),
          $widget->get_window ('text'));
}
sub Gtk2::TextView::Gtk2_Ex_WidgetCursor_hack_restore {
  my ($widget) = @_;
  return $widget->sensitive && ($widget->get_window('text'), 'xterm');
}

# GtkEntry's extra subwindow is included here.  And when sensitive it should
# be put back to an insertion point.  For a bit of safety use list context
# etc to allow for no subwindows, since it's undocumented.
#
# In Gtk 2.14 the SpinButton sub-class has the arrow panel as a subwindow
# too (instead of an overlay in Gtk 2.12 and earlier).  So look for the
# smaller height one among multiple subwindows.
#
sub Gtk2::Entry::Gtk2_Ex_WidgetCursor_windows {
  my ($widget) = @_;
  my $win = $widget->window || return; # if unrealized
  return ($win, $win->get_children);
}
sub Gtk2::Entry::Gtk2_Ex_WidgetCursor_hack_restore {
  my ($widget) = @_;
  $widget->sensitive or return;
  my $win = $widget->window || return; # if unrealized
  my @children = $win->get_children;
  # by increasing height
  @children = sort {($a->get_size)[1] <=> ($b->get_size)[1]} @children;
  return ($children[0], 'xterm');
}
# GtkSpinButton's extra "panel" overlay window either as a "sibling" (which
# also finds the main window) for Gtk 2.12 or in the get_children() for Gtk
# 2.13; plus the GtkEntry subwindow as per GtkEntry above.  hack_restore()
# inherited from GtkEntry above.
#
sub Gtk2::SpinButton::Gtk2_Ex_WidgetCursor_windows {
  my ($widget) = @_;
  my $win = $widget->window || return; # if unrealized
  return (_widget_sibling_windows ($widget),
          $win->get_children);
}

# GtkButton secret input-only "event_window" overlay found as a "sibling".
#
sub Gtk2::Button::Gtk2_Ex_WidgetCursor_windows {
  my ($widget) = @_;
  return _widget_sibling_windows ($widget);
}

# _widget_sibling_windows() returns a list of the "sibling" windows of
# $widget.  This means all the windows which are under $widget's parent and
# have their events directed to $widget.  If $widget is a windowed widget
# then this will include its main $widget->window (or should do).
#
# The search works by seeing where a dummy expose event is directed by
# gtk_get_event_widget().  It'd also be possible to inspect
# gdk_window_get_user_data(), but Gtk2-Perl only returns an "unsigned" for
# that so it'd need some nasty digging for the widget address.
#
# In the past the code here cached the result against the widget (what was
# then just GtkButton's "event_window" sibling), with weakening of course so
# unrealize would destroy the windows as normal.  But don't bother with that
# now, on the basis that cursor changes hopefully aren't so frequent as to
# need too much trouble, and that it's less prone to mistakes if not cached
# :-).
#
sub _widget_sibling_windows {
  my ($widget) = @_;
  my $parent_win = ($widget->flags & 'no-window'
                    ? $widget->window
                    : $widget->get_parent_window)
    || return; # if unrealized

  my $event = Gtk2::Gdk::Event->new ('expose');
  return grep { $event->window ($_);
                ($widget == (Gtk2->get_event_widget($event) || 0))
              } $parent_win->get_children;
}

# Return true if $widget is the Gtk2::EventBox child of a Gtk2::Combo popup
# window (it's a child of the popup window, not of the Combo itself).
#
sub _widget_is_combo_eventbox {
  my ($widget) = @_;
  my $parent;
  return ($widget->isa('Gtk2::EventBox')
          && ($parent = $widget->get_parent)  # might not have a parent
          && $parent->get_name eq 'gtk-combo-popup-window');
}


#------------------------------------------------------------------------------

# Could think about documenting this idle level to the world, maybe like the
# following, but would it be any use?
#
# =item C<$Gtk2::Ex::WidgetCursor::busy_idle_priority>
#
# The priority level of the (C<< Glib::Idle->add >>) handler installed by
# C<busy>.  This is C<G_PRIORITY_DEFAULT_IDLE - 10> by default, which is
# designed to stay busy through Gtk resizing and redrawing at around
# C<G_PRIORITY_HIGH_IDLE>, but end the busy before ordinary "default idle"
# tasks.
#
# You can change this depending what things you set running at what idle
# levels and where you consider the application no longer busy for user
# purposes.  But note changing this variable only affects future C<busy>
# calls, not any currently active one.
#
use constant BUSY_IDLE_PRIORITY => Glib::G_PRIORITY_DEFAULT_IDLE - 10;

my $busy_wc;
my $busy_id;
my $realize_id;

sub busy {
  my ($class) = @_;
  my @widgets = Gtk2::Window->list_toplevels;
  ### busy on toplevels: join(' ',@widgets)

  if ($busy_wc) {
    $busy_wc->add_widgets (@widgets);
  } else {
    ### new busy with class: $class
    $busy_wc = $class->new (widgets          => \@widgets,
                            cursor           => 'watch',
                            include_children => 1,
                            priority         => 1000,
                            active           => 1);
  }
  _flush_mapped_widgets (@widgets);

  # This is a hack to persuade Gtk2-Perl 1.160 and 1.181 to finish loading
  # Gtk2::Widget.  Without this if no Gtk2::Widget has ever been created the
  # signal_add_emission_hook() fails.  1.160 needs the combination of isa()
  # and find_property().  1.181 is ok with find_property() alone.  Either
  # way these can be removed when ready to depend on 1.200 and up.
  Gtk2::Widget->isa ('Gtk2::Widget');
  Gtk2::Widget->find_property ('name');
  
  $realize_id ||= Gtk2::Widget->signal_add_emission_hook
    (realize => \&_do_busy_realize_emission);

  $busy_id ||= Glib::Idle->add
    (\&_busy_idle_handler, undef, BUSY_IDLE_PRIORITY);
}

# While busy notice extra toplevels which have been realized.
# The cursor setting is applied at the realize so it's there ready for when
# the map is done.
sub _do_busy_realize_emission {
  my ($invocation_hint, $param_list) = @_;
  my ($widget) = @$param_list;
  ### WidgetCursor _do_busy_realize_emission(): "$widget"
  if ($widget->isa ('Gtk2::Window')) {
    $busy_wc->add_widgets (Gtk2::Window->list_toplevels);
    ### _do_busy_realize_emission() flush
    $widget->get_display->flush;
  }
  return 1; # stay connected
}

# Call unbusy() through $busy_wc to allow for possible subclassing.
# Using unbusy does a flush, which is often unnecessary but will ensure that
# if there's lower priority idles still to run then our cursors go out
# before the time they take.
#
sub _busy_idle_handler {
  ### _busy_idle_handler finished
  $busy_id = undef;
  if ($busy_wc) { $busy_wc->unbusy; }
  return 0; # Glib::SOURCE_REMOVE, one run only
}

sub unbusy {
  # my ($class_or_self) = @_;
  ### WidgetCursor unbusy()

  # Some freaky stuff can happen during perl "global destruction" with
  # classes being destroyed and disconecting emission hooks on their own,
  # provoking warnings from code like the following that does a cleanup
  # itself.  Fairly confident that doesn't apply to Gtk2::Widget because
  # that class probably, hopefully, maybe, never gets destroyed, or at least
  # not until well after any Perl code might get a chance to call unbusy().
  #
  if ($realize_id) {
    Gtk2::Widget->signal_remove_emission_hook (realize => $realize_id);
    undef $realize_id;
  }

  if ($busy_id) {
    Glib::Source->remove ($busy_id);
    $busy_id = undef;
  }
  if ($busy_wc) {
    my @widgets = $busy_wc->widgets;
    $busy_wc = undef;
    # flush to show new cursors immediately, per busy() below
    _flush_mapped_widgets (@widgets);
  }
}

# flush the Gtk2::Gdk::Display's of all the given widgets, if they're mapped
# (with the idea being if they're unmapped then there's nothing to see so no
# need to flush)
#
sub _flush_mapped_widgets {
  my @widget_list = @_;
  my %done;
  ### _flush_mapped_widgets
  foreach my $widget (@widget_list) {
    if ($widget->mapped) {
      my $display = $widget->get_display;
      $done{Scalar::Util::refaddr($display)} ||= do {
        ### flush display: "$display"
        $display->flush;
        1
      };
    }
  }
}


#------------------------------------------------------------------------------

# list_values() creates a slew of hash records, so don't want to do that on
# every invisible_cursor() call.  Doing it once at BEGIN time also allows
# the result to be inlined and the unused code discarded.
#
use constant _HAVE_BLANK_CURSOR
  => (!! List::Util::first
      {$_->{'nick'} eq 'blank-cursor'}
      Glib::Type->list_values('Gtk2::Gdk::CursorType'));
### _HAVE_BLANK_CURSOR: _HAVE_BLANK_CURSOR()

sub invisible_cursor {
  my ($class, $target) = @_;
  my $display;

  if (! defined $target) {
    $display = Gtk2::Gdk::Display->get_default
      || croak 'invisible_cursor(): no default display';

  } elsif ($target->isa('Gtk2::Gdk::Display')) {
    $display = $target;

  } else {
    $display = $target->get_display
      || croak "invisible_cursor(): get_display undef on $target";
  }

  if (_HAVE_BLANK_CURSOR) {
    # gdk_cursor_new_for_display() returns same object each time so no need
    # to cache, though being a Glib::Boxed it's a new perl object every time
    return Gtk2::Gdk::Cursor->new_for_display ($display,'blank-cursor');
  } else {
    return ($display->{__PACKAGE__.'.invisible_cursor'}
            ||= do {
              ### invisible_cursor() new for: "$display"
              my $window = $display->get_default_screen->get_root_window;
              my $mask = Gtk2::Gdk::Bitmap->create_from_data ($window,"\0",1,1);
              my $color = Gtk2::Gdk::Color->new (0,0,0);
              Gtk2::Gdk::Cursor->new_from_pixmap ($mask,$mask,$color,$color,0,0);
            });
  }
}


#------------------------------------------------------------------------------
# generic helpers

sub _splice_out {
  my ($aref, $target) = @_;
  for (my $i = 0; $i < @$aref; $i++) {
    if (! defined $aref->[$i] || $aref->[$i] == $target) {
      splice @$aref, $i,1;
    }
  }
}

#------------------------------------------------------------------------------
1;
__END__

=head1 NAME

Gtk2::Ex::WidgetCursor -- mouse pointer cursor management for widgets

=for test_synopsis my ($mywidget)

=head1 SYNOPSIS

 use Gtk2::Ex::WidgetCursor;
 my $wc = Gtk2::Ex::WidgetCursor->new (widget => $mywidget,
                                       cursor => 'fleur',
                                       active => 1);

 # show wristwatch everywhere while number crunching
 Gtk2::Ex::WidgetCursor->busy;

 # bonus invisible cursor creator
 my $cursor = Gtk2::Ex::WidgetCursor->invisible_cursor;

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::WidgetCursor> is a subclass of C<Glib::Object>.

    Glib::Object
      Gtk2::Ex::WidgetCursor

=head1 DESCRIPTION

WidgetCursor manages the mouse pointer cursor shown in widget windows as per
C<Gtk2::Gdk::Window> C<set_cursor>.  A "busy" mechanism can display a
wristwatch in all windows when the whole application is blocked.

With the plain window C<set_cursor> it's difficult for widget add-ons or
independent parts of an application to cooperate with what should be shown
at different times or in different modes.

A C<Gtk2::Ex::WidgetCursor> object represents a desired cursor in one or
more widgets.  When "active" and when it's the newest or highest priority
then the specified cursor is set onto those widget window(s).  If the
WidgetCursor object is later made inactive or destroyed then the next
remaining highest WidgetCursor takes effect, etc.

The idea is to have say a base WidgetCursor for an overall mode, then
something else temporarily while dragging, and perhaps a wristwatch "busy"
indication trumping one or both (like the global "busy" mechanism below).

=for me -- becomes /usr/share/doc/... in the deb

The F<examples> subdirectory in the WidgetCursor sources has some variously
contrived sample programs.

=head1 WIDGETCURSOR OBJECTS

=head2 Construction

=over

=item C<< $wc = Gtk2::Ex::WidgetCursor->new (key => value, ...) >>

Create and return a new C<WidgetCursor> object.  Optional key/value
parameters set initial properties as per C<< Glib::Object->new >> (see
L<Glib::Object>).

    $wc = Gtk2::Ex::WidgetCursor->new (widget => $mywidget,
                                       cursor => 'fleur',
                                       active => 1);

Note that C<active> is false by default and the WidgetCursor does nothing to
the widgets until made C<active> by the property or the method call below.

WidgetCursor objects can be applied to unrealized widgets.  The cursor
settings take effect if/when the widgets are realized.

=back

=head2 Methods

=over

=item C<< $bool = $wc->active () >>

=item C<< $wc->active ($newval) >>

Get or set the "active" state of C<$wc>.  This is the C<active> property.

=item C<< $cursor = $wc->cursor () >>

=item C<< $wc->cursor ($cursor) >>

Get or set the cursor of C<$wc>.  This is the C<cursor> property, see
L</PROPERTIES> below for possible values.  Eg.

    $wc->cursor ('umbrella');

=item C<< @widgets = $wc->widgets () >>

Return a list of the widgets currently in C<$wc>.  Eg.

    my @array = $wc->widgets;

or if you know you're only acting on one widget then say

    my ($widget) = $wc->widgets;

=item C<< $wc->add_widgets ($widget, $widget, ...) >>

Add widgets to C<$wc>.  Any widgets given which are already in C<$wc> are
ignored.

=back

=head1 PROPERTIES

=over 4

=item C<widget> (C<Gtk2::Widget>, default C<undef>)

=item C<widgets> (scalar arrayref of C<Gtk2::Widget>, default C<undef>)

The widget or widgets to act on.

A WidgetCursor object only keeps weak references to its widget(s), so the
mere fact there's a desired cursor won't keep a widget alive forever.
Garbage collected widgets drop out of the widgets list.  In particular this
means it's safe to hold a WidgetCursor within a widget's own hash without
creating a circular reference.  Eg.

    my $widget = Gtk2::DrawingArea->new;
    $widget->{'base_cursor'} = Gtk2::Ex::WidgetCursor->new
                                 (widget => $widget,
                                  cursor => 'hand1',
                                  active => 1,
                                  priority => -10);

=item C<add-widget> (C<Gtk2::Widget>, write-only)

Add a widget to those to act on.  This is a write-only pseudo-property
calling C<add_widget> above.  It's good for C<Gtk2::Builder> where the
C<widgets> property can't be used since it's a Perl scalar type.

=item C<cursor> (scalar string name or C<Gtk2::Gdk::Cursor> object)

The cursor to show in the widgets.  This can be

=over

=item *

A string cursor type nick from the C<Gtk2::Gdk::CursorType> enum, such as
C<"hand1">.  See L<Gtk2::Gdk::Cursor> for the full list of cursor types.

=item *

Special string name C<"invisible"> to have no cursor at all.  In Gtk 2.16 up
this is the same as "blank-cursor", or in earlier versions gives a "no
pixels set" pixmap cursor.

=item *

A C<Gtk2::Gdk::Cursor> object.

If your program uses multiple displays then remember the cursor object must
be on the same display (ie. C<Gtk2::Gdk::Display>) as the widget(s).  If you
have more than one widget then they must be all on the same display in this
case.  (For a named cursor they don't have to be.)

=item *

C<undef> to inherit the parent window's cursor, which may be the default
little pointing arrow or whatever from the root window.

=back

=item C<cursor-name> (string, default C<undef>)

=item C<cursor-object> (C<Gtk2::Gdk::Cursor>, default C<undef>)

The cursor to show in the widgets, as a plain Glib string or object
property.  These are designed for use from C<Gtk2::Builder> where the scalar
type C<cursor> property can't be set.

Reading from C<cursor-name> when a cursor object has been set gives the type
nick if it has one, or if it's a pixmap then currently C<undef>.

Reading from C<cursor-object> when a cursor name string has been set gives
C<undef> currently.  It'd be possible to make or return the cursor object in
use (or which will be used when realized) but that doesn't seem worth
bothering with as yet.

=item C<active> (boolean, default false)

Whether to apply the cursor to the widgets.  This can be set before widgets
are added or before they're realized, in which case the cursor is applied
later as soon as they're realized.

=item C<priority> (number, default 0)

The priority level of this WidgetCursor among multiple WidgetCursors acting
on a widget.

Higher values are higher priority.  A low value (perhaps negative) can act
as a fallback, or a high value can trump other added cursors.

=item C<include-children> (boolean, default false)

Whether to apply the cursor to child widgets of the given widgets too.
Normally the cursor in a child widget overrides its parents (as
C<set_cursor> does at the window level).  But with C<include-children> a
setting in a parent applies to the children too, with priority+newest
applied as usual.

=back

=head1 APPLICATION BUSY

The C<busy> mechanism sets a "watch" cursor on all windows to tell the user
the program is doing CPU-intensive work and might not run the main loop to
draw or interact for a while.

=for me -- examples/timebusy.pl becomes /usr/share/doc/... in the deb

If your busy state isn't CPU-intensive, but instead perhaps a Glib timer or
an I/O watch on a socket, then this is not what you want, it'll turn off too
soon.  (Instead simply make a C<WidgetCursor> with a C<"watch"> and turn it
on or off at your start and end points.  See F<examples/timebusy.pl> in the
sources for an example of that sort of thing.)

=over 4

=item C<< Gtk2::Ex::WidgetCursor->busy () >>

Show the C<"watch"> cursor (a little wristwatch) in all the application's
widget windows (toplevels, dialogs, popups, etc).  An idle handler
(C<< Glib::Idle->add >>) removes the watch automatically upon returning to
the main loop.

The X queue is flushed to set the cursor immediately, so the program can go
straight into its work.  For example

    Gtk2::Ex::WidgetCursor->busy;
    foreach my $i (1 .. 1_000_000) {
      # do much number crunching
    }

If you create new windows within a C<busy> then they too get the busy cursor
(or they're supposed to, something fishy in Gtk 2.20 and maybe 2.18 has
broken it).  You can even go busy before creating any windows at all.  But
note WidgetCursor doesn't do any extra X flush for new creations; if you
want them to show immediately then you must flush in the usual way.

C<busy> uses a C<WidgetCursor> object as described above and so cooperates
with application uses of that.  Priority level 1000 is set to trump other
cursor settings.

=item C<< Gtk2::Ex::WidgetCursor->unbusy () >>

Explicitly remove the watch cursor setup by C<busy> above.  The X request
queue is flushed to ensure any cursor change appears immediately.  If
C<busy> is not active then do nothing.

It's unlikely you'll need C<unbusy>, because if your program hasn't yet
reached the idle handler in the main loop then it's probably still busy!
But perhaps if most of your work is done then you could unbusy while the
remainder is finishing up.

=back

=head1 INVISIBLE CURSOR

The following invisible cursor is used by WidgetCursor for the
C<"invisible"> cursor and is made available for general use.

=over 4

=item C<< $cursor = Gtk2::Ex::WidgetCursor->invisible_cursor () >>

=item C<< $cursor = Gtk2::Ex::WidgetCursor->invisible_cursor ($target) >>

Return a C<Gtk2::Gdk::Cursor> object which is invisible, ie. displays no
cursor at all.  This is the C<blank-cursor> in Gtk 2.16 and up, or for
earlier versions a "no pixels set" cursor as described by C<gdk_cursor_new>.

With no arguments (or C<undef>) the cursor is for the default display
C<< Gtk2::Gdk::Display->get_default >>.  If your program only uses one
display then that's all you need.

    my $cursor = Gtk2::Ex::WidgetCursor->invisible_cursor;

For multiple displays a cursor is a per-display resource so you must pass a
C<$target>.  This can be a C<Gtk2::Gdk::Display>, or anything with a
C<get_display> method, including C<Gtk2::Widget>, C<Gtk2::Gdk::Window>,
C<Gtk2::Gdk::Drawable>, another C<Gtk2::Gdk::Cursor>, etc.

    my $cursor = Gtk2::Ex::WidgetCursor->invisible_cursor ($widget);

When passing a widget note the display comes from its toplevel
C<Gtk2::Window> parent and until added as a child somewhere under a toplevel
its C<get_display> is the default display and C<invisible_cursor> will give
a cursor for that display.

The invisible cursor is cached against the display so repeated calls don't
make a new one every time.

=back

Gtk had its own "no pixels set" cursor constructor code in C<GtkEntry> and
C<GtkTextView> prior to "blank-cursor" but didn't make it available to
applications.

=head1 BUILDABLE

WidgetCursor is a C<Glib::Object> and can be created by C<Gtk2::Builder> in
the usual way.  Each is a separate toplevel object and the C<widget>
property sets what it should act on.  The C<add-widget> pseudo-property
allows multiple widgets to be set.

    <object class="Gtk2__Ex__WidgetCursor" id="wcursor">
      <property name="widget">mywidget</property>
      <property name="active">1</property>
    </object>

=for me -- becomes /usr/share/doc/... in the deb

See F<examples/builder.pl> and F<examples/builder-add.pl> in the
WidgetCursor sources for complete sample programs.

=head1 LIMITATIONS

WidgetCursor settings are applied to the widget windows without paying
attention to which among them are "no-window" and thus using their parents'
windows.  If different no-window children have a common windowed parent then
WidgetCursor won't notice and the result will probably come out wrong.  For
now it's suggested you either always give a windowed widget, or at least
always the same no-window child.

An exception to the no-window rule is C<Gtk2::Button>.  It has the no-window
flag but in fact keeps a private input-only event window over its allocated
space.  WidgetCursor digs that out and uses it to put the cursor on the
intended area.  But an exception to this exception is C<Gtk2::LinkButton>
where a setting on the button works fine, but any WidgetCursor on its parent
widget is messed up.

In the future it might be possible to have cursors on no-window widgets by
following motion-notify events within the container parent in order to
update the cursor as it goes across different children.  Something similar
might allow certain regions of a window to have a particular cursor, such as
hyperlinked clickable text.  But windowed widgets are normally best, since
they let the X server take care of the display as the mouse moves around.

Reparenting widgets under an C<include_children> probably doesn't quite
work.  If it involves a new realize then it may work (as for reparenting to
a different screen).  Moving widgets is unusual, so in practice this isn't
too bad.  Doing the right thing in all cases might need a lot of C<add> or
C<parent> signal connections.

Widgets calling C<< $window->set_cursor >> themselves generally don't work
with the WidgetCursor mechanism.  WidgetCursor has some special handling for
C<Gtk2::Entry> and C<Gtk2::TextView> (their insertion point cursor), but a
few other core widgets have problems.  The worst currently is
C<Gtk2::LinkButton> per above.  Hopefully this can improve in the future,
though ill effects are often as modest as an C<include_children> merely not
working on children of offending types.

=head1 SEE ALSO

L<Gtk2::Gdk::Cursor>, L<Gtk2::Widget>, L<Gtk2::Gdk::Window>,
L<Gtk2::Gdk::Display>

=head1 HOME PAGE

http://user42.tuxfamily.org/gtk2-ex-widgetcursor/index.html

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetCursor.  If not, see L<http://www.gnu.org/licenses/>.

=cut

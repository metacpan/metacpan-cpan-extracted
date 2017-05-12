# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::WidgetEvents;
use 5.008;
use strict;
use warnings;
use Carp;
use Scalar::Util 'refaddr', 'weaken';

use Gtk2 1.183;  # for Glib::Flags->new and overloaded !=
use Glib::Ex::SignalIds;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;


# The following fields are hung on a target widget,
#
# Gtk2::Ex::WidgetEvents.obj_hash
#     Hashref of WidgetEvents instances targeting this widget, in the form
#     refaddr($wevents_obj) => $wevents_obj.  Values are weakened.  Entries
#     are removed by WidgetEvents DESTROY, including the whole field removed
#     when the last WidgetEvents on the widget is gone.
#
# Gtk2::Ex::WidgetEvents.signal_ids
#     A Glib::Ex::SignalIds object for the 'realize' signal calling
#     _do_widget_realize().  Removed and disconnected by DESTROY of the last
#     WidgetEvents object on the widget.
#
# Gtk2::Ex::WidgetEvents.base_events
#
# Gtk2::Ex::WidgetEvents.last_win_events
#
#
# The various methods taking events as parameters have arg count checks to
# protect against something like $wevents->add('foo','bar') expecting both
# those events added.  It should instead be a single flags parameter
# arrayref like $wevents->add(['foo','bar']).  It'd be possible to relax and
# accept the former, but everywhere else in Gtk2-Perl demands a single arg
# for flags, so don't want to encourage laziness in that area.


sub new {
  my ($class, $widget, $events) = @_;
  ### WidgetEvents new: "$widget"

  if (@_ != 2 && @_ != 3) {
    croak 'WidgetEvents->new(): one or two arguments expected';
  }

  # coerce to flags object
  if (@_ == 2) { $events = []; } # if arg omitted
  $events = Gtk2::Gdk::EventMask->new ($events);

  my $self = bless { widget => $widget,
                     events => $events }, $class;
  weaken ($self->{'widget'});

  # one 'realize' handler per widget
  $widget->{__PACKAGE__.'.signal_ids'} ||= do {
    # X server query for the base events when first acting on this widget
    # and already realized
    if (my $win = $widget->window) {
      $widget->{__PACKAGE__.'.base_events'} = $win->get_events;
    }
    Glib::Ex::SignalIds->new
        ($widget, $widget->signal_connect (realize => \&_do_widget_realize))
      };

  # autovivify 'obj_hash'
  weaken ($widget->{__PACKAGE__.'.obj_hash'}->{refaddr($self)}
          = $self);

  _update_widget ($widget);
  return $self;
}

sub add {
  if (@_ != 2) { croak 'WidgetEvents->add(): one argument expected'; }
  my ($self, $events) = @_;
  my $old_events = $self->{'events'};
  if (($self->{'events'} += $events) != $old_events) {
    _update_widget ($self->{'widget'});
  }
}
sub remove {
  if (@_ != 2) { croak 'WidgetEvents->remove(): one argument expected'; }
  my ($self, $events) = @_;
  my $old_events = $self->{'events'};
  if (($self->{'events'} -= $events) != $old_events) {
    _update_widget ($self->{'widget'});
  }
}

sub DESTROY {
  my ($self) = @_;
  ### WidgetEvents DESTROY
  my $widget = $self->{'widget'} || return;  # possible weakening

  my $href = $widget->{__PACKAGE__.'.obj_hash'};
  delete $href->{refaddr($self)};

  _update_widget ($widget);  # new event mask

  # when the last WidgetEvents goes away on $widget remove fields
  # except keep base_events permanently (is that a good idea?)
  #
  ### down to count on widget: scalar(%$href)
  if (! %$href) {
    delete @{$widget}{__PACKAGE__.'.signal_ids',
                        __PACKAGE__.'.last_win_events',
                          __PACKAGE__.'.obj_hash'};   # hash slice
    # __PACKAGE__.'.base_events',
  }
}

# 'realize' signal handler
sub _do_widget_realize {
  my ($widget) = @_;
  ### WidgetEvents realize: "$widget"

  if (defined (my $base_events = $widget->{__PACKAGE__.'.base_events'})) {
    $widget->{__PACKAGE__.'.last_win_events'} = $base_events;
  }
  _update_widget ($widget);
}

sub _update_widget {
  my ($widget) = @_;
  if (! $widget) { return; } # possible weakening
  ### WidgetEvents update: "$widget"

  my $win = $widget->window || return;  # nothing to do until realized

  my $base_events = $widget->{__PACKAGE__.'.base_events'};
  if (! defined $base_events) {
    $base_events
      = $widget->{__PACKAGE__.'.last_win_events'}
        = $widget->{__PACKAGE__.'.base_events'}
          = $win->get_events;  # X server round-trip

    ### establish base_events: "$base_events"
  }

  my $want_events = $base_events + $widget->get_events;
  foreach my $obj (values %{$widget->{__PACKAGE__.'.obj_hash'}}) {
    if (defined $obj) {  # possible weakening
      $want_events += $obj->{'events'};
    }
  }

  my $last_win_events = $widget->{__PACKAGE__.'.last_win_events'};
  if (! defined $last_win_events) {
    $last_win_events = $widget->{__PACKAGE__.'.last_win_events'}
      = $win->get_events;  # X server round-trip
  }

  if ($want_events != $last_win_events) {
    $widget->{__PACKAGE__.'.last_win_events'} = $want_events;
    $win->set_events ($want_events);  # XSelectInput to server

    ### install: "@{[$win->get_events]}"
    ### which adds:  "@{[$win->get_events - $last_win_events]}"
    ### and removes: "@{[$last_win_events - $win->get_events]}"
  }
}

1;
__END__

=for stopwords WidgetEvents GtkWidget ie arrayref builtin Gtk2-Ex-WidgetBits Ryde

=head1 NAME

Gtk2::Ex::WidgetEvents -- event mask merging for widgets

=for test_synopsis my ($widget)

=head1 SYNOPSIS

 use Gtk2::Ex::WidgetEvents;
 my $wm = Gtk2::Ex::WidgetEvents->new ($widget, ['motion-notify-mask']);

 my $we = Gtk2::Ex::WidgetEvents->new ($widget);
 $we->add (['motion-notify-mask','exposure-mask']);
 $we->remove ('exposure-mask');

=head1 DESCRIPTION

WidgetEvents represents an event mask wanted on a particular widget for an
add-on feature or semi-independent widget component.  The event mask on the
widget's window is the union of WidgetEvents masks and the widget's base
mask.

The plain GtkWidget C<add_events> is geared towards permanent additions to
the event mask.  Often this is enough.  But for removing mask bits to clean
up after a widget add-on it's important to check whether anyone else is
still interested in those events.  WidgetEvents keeps track of that.

Turning event mask bits on and off is mostly a matter of optimization.  For
example it does no great harm to have mouse motion events left on, but it's
wasteful.  Sometimes it's important for event propagation rules to have an
event turned off when unwanted, so for example a button press can go up to a
parent window instead.

=head1 FUNCTIONS

In the following functions C<$mask> can be any of the usual Glib flags
forms, meaning an actual C<Gtk2::Gdk::EventMask> object, an arrayref of flag
name strings, or a single flag name string (see L<Glib/This Is Now That>).

=over 4

=item C<< $wevents = Gtk2::Ex::WidgetEvents->new ($widget) >>

=item C<< $wevents = Gtk2::Ex::WidgetEvents->new ($widget, $mask) >>

Create a new C<WidgetEvents> object which adds C<$mask> to C<$widget>.
C<$mask> can be omitted to start a WidgetEvents with no mask bits.

    $wevents = Gtk2::Ex::WidgetEvents->new
                 ($widget, ['button-press-mask']);

The C<$wevents> object only keeps a weak reference to the given C<$widget>,
which means it's safe to keep it in the widget's instance data without
creating a circular reference.

=item C<< $wevents->add ($mask) >>

Add C<$mask> events to those already selected by C<$wevents>.  The target
widget's window is updated immediately if it's realized.

    $wevents->add (['enter-notify-mask', 'leave-notify-mask']);

=item C<< $wevents->remove ($mask) >>

Remove C<$mask> events from those selected by C<$wevents>.  The target
widget's window is updated immediately if it's realized and if nobody else
is interested in each C<$mask> bit.

    $wevents->remove (['enter-notify-mask', 'leave-notify-mask']);

=back

=head1 OTHER NOTES

The event mask for a widget window comes from flags coded into the widget
implementation plus those in the widget C<events> property.  The hard coded
flags are normally for a widget's builtin features, and the C<events>
property is extras wanted by external code.  The C<< $widget->add_events >>
method extends the C<events> property.

WidgetEvents notices both of these on a window and takes them as a base set
of event mask bits.  The base flags are always left installed.  Additional
bits wanted or not by WidgetEvents objects are then set or cleared.

=head1 SEE ALSO

L<Gtk2::Widget>, L<Gtk2::Gdk::Window>, L<Gtk2::Ex::WidgetCursor>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut

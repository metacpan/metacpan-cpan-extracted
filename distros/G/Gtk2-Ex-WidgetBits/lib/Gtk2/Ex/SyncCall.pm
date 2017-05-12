# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

package Gtk2::Ex::SyncCall;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

# version 2 was in with Gtk2-Ex-Dragger ...
our $VERSION = 48;


my $sync_call_atom;

my $get_display = (Gtk2::Widget->can('get_display')
                   ? 'get_display'
                   : do {
                     my $dummy_display = {};
                     sub { $dummy_display }
                   });

sub sync {
  my ($class, $widget, $callback, $userdata) = @_;
  ### SyncCall sync()

  my $display = $widget->$get_display;
  my $data = ($display->{(__PACKAGE__)} ||= do {
    $widget->add_events ('property-change-mask');

    ### widget add_events gives: $widget->window && $widget->window->get_events
    #### window XID: $widget->window && $widget->window->can('XID') && $widget->window->XID

    require Glib::Ex::SignalIds;
    # hash of data
    ({ sync_list => [],
       signal_ids => Glib::Ex::SignalIds->new
       ($widget,
        $widget->signal_connect (property_notify_event =>
                                 \&_do_property_notify),
        $widget->signal_connect (unrealize => \&_do_widget_destroy),
        $widget->signal_connect (destroy   => \&_do_widget_destroy)) })
  });

  $widget = $data->{'signal_ids'}->object;
  my $win = $widget->window
    || croak __PACKAGE__.'->sync(): widget not realized';

  # HACK: in gtk 2.18.4 and 2.18.5 property-change-event's aren't delivered
  # to a non-toplevel widget unless you call $gdkwin->XID on it
  # (ie. gdk_x11_drawable_get_xid()).  This is bizarre and would have to be
  # a bug, but this workaround at least makes SyncCall work (and its
  # dependents like Gtk2::Ex::CrossHair).
  #
  if ($win->can('XID')) { $win->XID; }

  my $self = { display  => $display,
               callback => $callback,
               userdata => $userdata };
  my $aref = $data->{'sync_list'};
  push @$aref, $self;

  if (@$aref == 1) {
    # first entry in sync_list initiates the sync
    $sync_call_atom ||= Gtk2::Gdk::Atom->intern (__PACKAGE__);
    ### property_change of: $sync_call_atom
    $win->property_change ($sync_call_atom,
                           Gtk2::Gdk::Atom->intern('STRING'),
                           Gtk2::Gdk::CHARS, 'append', '');
  }
  return $self;
}

# 'property-notify-event' signal on sync widget
sub _do_property_notify {
  my ($widget, $event) = @_;
  ### SyncCall property-notify handler: $event->atom

  # note, no overloaded != until Gtk2-Perl 1.183, only == prior to that
  if ($event->atom == $sync_call_atom) {
    my $display = $widget->$get_display;
    my $data = $display->{(__PACKAGE__)};
    _call_all ($data);
  }
  # even though $sync_call_atom is supposed to be for us alone, propagate it
  # anyway in case someone else is monitoring what happens
  return 0;  # Gtk2::EVENT_PROPAGATE
}

# 'unrealize' or 'destroy' signal on the sync widget
sub _do_widget_destroy {
  my ($widget) = @_;
  my $display = $widget->$get_display;
  if (my $data = delete $display->{(__PACKAGE__)}) {
    _call_all ($data);
  }
}

sub _call_all {
  my ($data) = @_;
  my $aref = $data->{'sync_list'};
  $data->{'sync_list'} = [];
  foreach my $self (@$aref) {
    $self->{'callback'}->($self->{'userdata'});
  }
}

1;
__END__

=for stopwords SyncCall unrealize ie Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::SyncCall -- server sync callback

=for test_synopsis my ($widget)

=head1 SYNOPSIS

 use Gtk2::Ex::SyncCall;
 Gtk2::Ex::SyncCall->sync ($widget, sub { some code; });

=head1 DESCRIPTION

C<Gtk2::Ex::SyncCall> sends a synchronizing request to the X server and
calls back to your code when the response is returned.  This is like
C<< $display->sync() >> (see L<Gtk2::Gdk::Display>), but done as a callback
instead of blocking.

A sync like this is a good way to wait for the server to finish doing
drawing or similar you've already sent, before attempting more.  It's up to
you to choose a good point in your program to do that, but the aim will be
not to hammer the server with more animation, updating text, window sizing
or whatever than it can keep up with.

=head2 Implementation

SyncCall is done with a property change on the given C<$widget> window,
which means the widget must be realized.  The setups on that widget are kept
ready for further syncs on that same display.  An unrealize or destroy of
the widget will call pending callbacks and then reset ready for a different
widget on subsequent syncs.

It's a good idea if C<$widget> isn't a top-level C<Gtk2::Window> widget,
because generally the window manager listens for property changes on that.
The property name C<"Gtk2::Ex::SyncCall"> will be ignored by the window
manager, but it's a little wasteful for it to see unnecessary change events.

(There's various alternatives to this approach.  Something not directly
involving a widget could be better, the widget then only indicating the
target display.)

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::SyncCall->sync ($widget, $coderef) >>

=item C<< Gtk2::Ex::SyncCall->sync ($widget, $coderef, $userdata) >>

Send a synchronizing message to the X server and when the server replies
call

    &$coderef ($userdata)

C<$widget> must be realized (ie. C<< $widget->realize() >>).  C<$coderef> is
called just once.

Multiple C<sync> calls to the same display are collected up so just one
synchronising message is sent, with all the callbacks then done when the one
reply comes back.

Within a callback a new C<sync> can be initiated.  This results in a new
synchronising message sent to the server and the new callback runs when the
reply is received.  Chained syncs like this arise quite naturally if you've
got an animation or similar which is being held back by the speed of the
server.

=back

=head2 Error Handling

If C<$coderef> dies the error is trapped by the usual Glib main loop
exception handler mechanism (see L<Glib/EXCEPTIONS>).  Currently however an
error in one sync callback kills all the rest too.  Perhaps this will
change.

=head1 SEE ALSO

L<Gtk2::Widget>, L<Gtk2::Gdk::Display>, L<Gtk2::Ex::WidgetBits>

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

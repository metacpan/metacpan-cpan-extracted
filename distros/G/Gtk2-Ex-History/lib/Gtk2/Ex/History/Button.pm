# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::History::Button;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;

use Gtk2::Ex::History;
use Glib::Ex::ConnectProperties 13;  # v.13 for model-rows

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 8;

use Glib::Object::Subclass
  'Gtk2::Button',
  signals => { clicked => \&_do_clicked,
               button_press_event  => \&_do_button_press_event },
  properties => [ Glib::ParamSpec->object
                  ('history',
                   'History object',
                   'The history object to act on.',
                   'Gtk2::Ex::History',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('way',
                   'Which way',
                   'Which way to go in the history when clicked, either back or forward.',
                   'Gtk2::Ex::History::Way',
                   'back',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  # for some reason these setting don't take effect here but must be done in
  # SET_PROPERTY below
  $self->set_label ("gtk-go-back"); # default
  $self->set_use_stock (1);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  #  if ($pname eq 'history' || $pname eq 'way') { ...

  # should only need to update the icon when setting 'way', but as of gtk
  # 2.18 the icon in INIT_INSTANCE doesn't take effect -- something about
  # "constructor" -- so as a workaround apply the stock icon when setting
  # 'history' too
  #
  my $way = $self->get('way');
  $self->set_label ("gtk-go-$way");
  $self->set_use_stock (1);

  # the history model, either the back or forward one
  my $history = $self->{'history'};
  $self->{'connp'} = $history && Glib::Ex::ConnectProperties->dynamic
    ([$history->model($way), 'model-rows#not-empty'],
     [$self, 'sensitive']);
}

# 'clicked' class closure
sub _do_clicked {
  my ($self) = @_;
  ### History-Button clicked: $self->get('way')
  my $history = $self->{'history'} || return;
  my $way = $self->get('way');
  $history->$way;
  return shift->signal_chain_from_overridden(@_);
}

# 'button-press-event' class closure
#
# Might like this popup to work even when there's no items in the model and
# the button is therefore insensitive, but the button-press-event doesn't
# come through when insensitive.
#
sub _do_button_press_event {
  my ($self, $event) = @_;
  ### History-Button button-press-event: $event->button
  if ($event->button == 3 && (my $history = $self->{'history'})) {
    require Gtk2::Ex::History::Menu;
    Gtk2::Ex::History::Menu->new_popup (history => $history,
                                        way     => $self->get('way'),
                                        event   => $event);
  }
  return shift->signal_chain_from_overridden(@_);
}

1;
__END__

=for stopwords enum Ryde Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History::Button -- button for history "back" or "forward"

=for test_synopsis my ($my_history)

=head1 SYNOPSIS

 use Gtk2::Ex::History::Button;
 my $button = Gtk2::Ex::History::Button->new
                (history => $my_history,
                 way => 'forward');

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::History::Button> is a subclass of C<Gtk2::Button>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Button
            Gtk2::Ex::History::Button

=head1 DESCRIPTION

A C<Gtk2::Ex::History::Button> invokes either C<back> or C<forward> on a
C<Gtk2::Ex::History> object.

    +--------------+
    | ==>  Forward |
    +--------------+

Mouse button-3 opens a C<Gtk2::Ex::History::Menu> to select an entry from a
menu to jump to, to go more than one place back or forward.

A button like this can be used anywhere desired.  If it's put in a
C<Gtk2::ToolItem> it can be used in a C<Gtk2::Toolbar>, though if using
C<Gtk2::UIManager> then see L<Gtk2::Ex::History::Action> instead.

=head1 FUNCTIONS

=over 4

=item C<< $button = Gtk2::Ex::History::Button->new (key => value, ...) >>

Create and return a new history button.  Optional key/value pairs can be
given to set initial properties, as per C<< Glib::Object->new >>.

The C<history> property should be set to say what to display, and C<way> for
back or forward.

    my $button = Gtk2::Ex::History::Button->new
                    (history => $history,
                     way => 'forward');

=back

=head1 PROPERTIES

=over 4

=item C<history> (C<Gtk2::Ex::History> object, default C<undef>)

The history object to act on.

=item C<way> (enum C<Gtk2::Ex::History::Way>, default "back")

The direction to go, either "back" or "forward".

The "stock" icon is set from this, either C<gtk-go-back> or
C<gtk-go-forward>.

=back

=head1 BUGS

The initial button display is empty, not the intended default C<way> "back".
Setting a history object or an explicit initial C<way> works.

    my $button = Gtk2::Ex::History::Button->new
                    (way => 'back');    # explicit as a workaround

It's something to do with object "constructor" stuff making the stock icon
setup in C<INIT_INSTANCE> not work.  Usually you set a C<history> in
initially and that's jigged up to kick it into life.

    my $button = Gtk2::Ex::History::Button->new
                    (history => $history);    # ok, "back" button

=head1 SEE ALSO

L<Gtk2::Ex::History>,
L<Gtk2::Ex::History::Menu>,
L<Gtk2::Ex::History::MenuToolButton>,
L<Gtk2::Ex::History::Action>,
L<Gtk2::Button>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-history/index.html>

=head1 LICENSE

Gtk2-Ex-History is Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-History is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-History is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-History.  If not, see L<http://www.gnu.org/licenses/>.

=cut

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

package Gtk2::Ex::History::Menu;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Scalar::Util;

use Glib::Ex::ObjectBits;
use Gtk2::Ex::History;
use Gtk2::Ex::MenuView;

use Locale::TextDomain ('Gtk2-Ex-History');
use Locale::Messages;
BEGIN {
  Locale::Messages::bind_textdomain_codeset ('Gtk2-Ex-History','UTF-8');
  Locale::Messages::bind_textdomain_filter ('Gtk2-Ex-History',
                                            \&Locale::Messages::turn_utf_8_on);
}
use Gtk2::Ex::Dashes::MenuItem;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 8;

use Glib::Object::Subclass
  'Gtk2::Ex::MenuView',
  signals => { item_create_or_update => \&_do_item_create_or_update,
               activate => \&_do_activate,
             },
  properties => [ Glib::ParamSpec->object
                  ('history',
                   __('History object'),
                   'The history object to present and act on.',
                   'Gtk2::Ex::History',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('way',
                   'Which way',
                   'Which way of the history to present, either back or forward.',
                   'Gtk2::Ex::History::Way',
                   'back',
                   Glib::G_PARAM_READWRITE),
                ];


sub INIT_INSTANCE {
  my ($self) = @_;

  my $dashesitem = Gtk2::Ex::Dashes::MenuItem->new (visible => 1);
  $dashesitem->signal_connect (activate => \&_do_dashesitem_activate);
  $self->prepend ($dashesitem);
  Glib::Ex::ObjectBits::set_property_maybe
      ($dashesitem,
       # tooltip-text new in Gtk 2.12
       tooltip_text => __('Open the back/forward history dialog'));
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'history' || $pname eq 'way') {
    my $history = $self->{'history'};
    $self->set (model => $history && $history->model($self->get('way')));
    #### History-Menu model: $self->get('model')
  }
}

# 'activate' signal handler on Dashes::MenuItem tearoff
sub _do_dashesitem_activate {
  my ($dashesitem) = @_;
  my $self = $dashesitem->get_parent || return;  # if orphaned somehow
  require Gtk2::Ex::History::Dialog;
  Gtk2::Ex::History::Dialog->popup ($self->{'history'}, $self);
}

# 'item-create-or-update' class closure handler
sub _do_item_create_or_update {
  my ($self, $item, $model, $path, $iter) = @_;
  #### History-Menu _do_item_create_or_update(): $path->to_string

  $item ||= Gtk2::MenuItem->new_with_label ('');
  my $place = $model->get ($iter, 0);
  if (my $history = $self->{'history'}) {
    # should always have the history obj when still have model ...
    $item->get_child->set_use_markup ($history->get('use-markup'));
    $place = $history->signal_emit ('place-to-text', $place);
  }
  $item->get_child->set_text ($place);

  return $item;
}

# 'activate' class closure handler
sub _do_activate {
  my ($self, $item, $model, $path, $iter) = @_;
  my $history = $self->{'history'} || return;
  my $way = $self->get('way');
  my $n = ($path->get_indices)[0];
  $history->$way ($n+1);
}

sub new_popup {
  my ($class, %options) = @_;
  ### History-Menu new_popup()
  my $event = delete $options{'event'};
  my $self = $class->new (%options);

  my $button = 0;
  my $time = 0;
  if ($event) {
    if ($event->can('button')) {
      $button = $event->button;
    }
    if ($event->can('time')) {
      $time = $event->time;
    }
    if (my $window = $event->window) {
      $self->set_screen ($window->get_screen);
    }
  }
  ###    screen: $self->get_screen->make_display_name
  ###    $button
  ###    $time
  $self->popup (undef, undef, undef, undef, $button, $time);
  return $self;
}

1;
__END__

=for stopwords tearoff popup enum Ryde Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History::Menu -- menu of "back" or "forward" history items

=for test_synopsis my ($my_history)

=head1 SYNOPSIS

 use Gtk2::Ex::History::Menu;
 my $my_menu = Gtk2::Ex::History::Menu->new
                 (history => $my_history,
                  way => 'forward');

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::History::Menu> is a subclass of C<Gtk2::Ex::MenuView>, though
that's only really an implementation detail and the suggestion is not to
rely on more than <Gtk2::Menu>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            Gtk2::Ex::MenuView
              Gtk2::Ex::History::Menu

=head1 DESCRIPTION

A C<Gtk2::Ex::History::Menu> presents a menu of either the "back" or
"forward" choices from a C<Gtk2::Ex::History> object.  This menu is shown by
C<Gtk2::Ex::History::Button> and C<Gtk2::Ex::History::MenuToolButton>.
Selecting an item makes the History go back or forward to that item.

    +--------------------+
    | ---  ---  ---  --- |
    | Thing last visited |
    | The thing before   |
    | An old thing       |
    +--------------------+

The dashed tearoff item opens a C<Gtk2::Ex::History::Dialog>.  If there's no
items to go "back" or "forward" then that tearoff is all that's in the menu.

=head1 FUNCTIONS

=over 4

=item C<< $histmenu = Gtk2::Ex::History::Menu->new (key => value, ...) >>

Create and return a new history menu.  Optional key/value pairs set initial
properties as per C<< Glib::Object->new >>.  The C<history> property should
be set to say what to display, and C<way> for back or forward.

    my $menu = Gtk2::Ex::History::Menu->new
                 (history => $my_history,
                  way => 'forward');

=item C<< $histmenu = Gtk2::Ex::History::Menu->new_popup (key => value, ...) >>

Create and popup a new history menu.  The key/value parameters set initial
properties, plus an additional

    event =>   Gtk2::Gdk::Event object or undef

If the event has C<button> and C<time> fields then they're used for the menu
popup, and if the C<window> field is set then that gives the screen
(C<Gtk2::Gdk::Screen>) the menu pops up on.  For example,

    sub my_button_press_handler {
      my ($self, $event) = @_;
      Gtk2::Ex::History::Menu->new_popup (history => $my_history,
                                          way     => 'back',
                                          event   => $event);
      return Gtk2::EVENT_PROPAGATE; # other handlers
    }

=back

=head1 PROPERTIES

=over 4

=item C<history> (C<Gtk2::Ex::History> object, default C<undef>)

The history object to display.

=item C<way> (enum C<Gtk2::Ex::History::Way>, default 'back')

The direction to display, either "back" or "forward".

=back

=head1 SEE ALSO

L<Gtk2::Ex::History>,
L<Gtk2::Ex::History::Button>,
L<Gtk2::Ex::History::MenuToolButton>,
L<Gtk2::Ex::History::Dialog>,
L<Gtk2::Ex::MenuView>,
L<Gtk2::Ex::Dashes::MenuItem>

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

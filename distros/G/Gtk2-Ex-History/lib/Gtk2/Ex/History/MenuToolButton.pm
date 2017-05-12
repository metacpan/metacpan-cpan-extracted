# Copyright 2010, 2011 Kevin Ryde

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

package Gtk2::Ex::History::MenuToolButton;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Glib::Ex::ConnectProperties 13;  # v.13 for model-rows
use Gtk2::Ex::History;

# uncomment this to run the ### lines
#use Smart::Comments;



our $VERSION = 8;

use Glib::Object::Subclass
  'Gtk2::MenuToolButton',
  signals => { clicked => \&_do_clicked,
               show_menu => \&_do_show_menu },
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
  $self->set_stock_id ('gtk-go-back');
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'history') {
    unless ($self->get_menu) {
      $self->set_menu (Gtk2::Menu->new); # dummy to make arrow sensitive
    }
  }

  if ($pname eq 'way') {
    $self->set_stock_id ("gtk-go-$newval");
  }

  my $history = $self->{'history'};
  my $way = $self->get('way');
  if (my $menu = $self->get_menu) {
    if ($menu->isa('Gtk2::Ex::History::Menu')) {
      $menu->set (history => $history,
                  way => $way);
    }
  }
  $self->{'connp'} = $history && Glib::Ex::ConnectProperties->dynamic
    ([$history->model($way), 'model-rows#not-empty'],
     [$self, 'sensitive']);
}

sub _do_show_menu {
  my ($self) = @_;
  ### _do_show_menu()
  if (my $history = $self->{'history'}) {
    my $menu;
    unless (($menu = $self->get_menu)
            && ($menu->isa('Gtk2::Ex::History::Menu'))) {
      require Gtk2::Ex::History::Menu;
      $self->set_menu (Gtk2::Ex::History::Menu->new (history => $history,
                                                     way => $self->get('way')));
    }
  }
  shift->signal_chain_from_overridden(@_);
}

# 'clicked' class closure
sub _do_clicked {
  my ($self) = @_;
  ### History-MenuToolButton clicked: $self->get('way')
  my $history = $self->{'history'} || return;
  my $way = $self->get('way');
  $history->$way;
  return shift->signal_chain_from_overridden(@_);
}

1;
__END__

=for stopwords enum MenuToolButton popup Ryde Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History::MenuToolButton -- toolbar button for history "back" or "forward"

=for test_synopsis my ($my_history, $toolbar)

=head1 SYNOPSIS

 use Gtk2::Ex::History::MenuToolButton;
 my $item = Gtk2::Ex::History::MenuToolButton->new
              (history => $my_history,
               way => 'forward');
 $toolbar->add ($item);

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::History::MenuToolButton> is a subclass of
C<Gtk2::MenuToolButton>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ToolItem
            Gtk2::ToolButton
              Gtk2::MenuToolButton
                Gtk2::Ex::History::MenuToolButton

=head1 DESCRIPTION

This is a toolbar button which invokes either C<back> or C<forward> on a
C<Gtk2::Ex::History> object.  The arrow part of the button presents a menu
of the history in that direction.

    +-------------+---+
    |             |   |
    | ==> Forward | V |
    |             |   |
    +-------------+---+
                  +---------------+
                  | Some Thing    |
                  | Another Place |
                  | Future Most   |
                  +---------------+

A plain C<Gtk2::Ex::History::Button> can be put in a C<Gtk2::ToolItem> and
used in a toolbar for a similar result.  The difference is whether you
prefer the menu popup with an arrow or with mouse button-3.  The arrow has
the advantage of a visual indication that there's something available.

=head1 FUNCTIONS

=over 4

=item C<< $item = Gtk2::Ex::History::MenuToolButton->new (key => value, ...) >>

Create and return a new history button.  Optional key/value pairs can be
given to set initial properties, as per C<< Glib::Object->new >>.

The C<history> property should be set to say what to display and act on, and
C<way> for back or forward.

    my $item = Gtk2::Ex::History::MenuToolButton->new
                  (history => $history,
                   way => 'forward');

=back

=head1 PROPERTIES

=over 4

=item C<history> (C<Gtk2::Ex::History> object, default C<undef>)

The history object to act on.

=item C<way> (enum C<Gtk2::Ex::History::Way>, default 'back')

The direction to go, either "back" or "forward".

The C<stock-id> property (per C<Gtk2::ToolButton>) is set from this, either
C<gtk-go-back> or C<gtk-go-forward>.

=back

=head1 SEE ALSO

L<Gtk2::Ex::History>,
L<Gtk2::Ex::History::Menu>,
L<Gtk2::Ex::History::Button>,
L<Gtk2::Ex::History::Action>,
L<Gtk2::MenuToolButton>

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

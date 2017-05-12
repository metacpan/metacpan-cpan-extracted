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

package Gtk2::Ex::History::Action;
use 5.008;
use strict;
use warnings;
use Scalar::Util;

use Gtk2 1.220; # for Gtk2::EVENT_PROPAGATE
use Gtk2::Ex::History;
use Glib::Ex::ConnectProperties 13;  # v.13 for model-rows

use Locale::TextDomain ('Gtk2-Ex-History');
use Locale::Messages;
BEGIN {
  Locale::Messages::bind_textdomain_codeset ('Gtk2-Ex-History','UTF-8');
  Locale::Messages::bind_textdomain_filter ('Gtk2-Ex-History',
                                            \&Locale::Messages::turn_utf_8_on);
}

our $VERSION = 8;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Action',
  signals => { activate => \&_do_activate },
  properties => [ Glib::ParamSpec->object
                  ('history',
                   __('History object'),
                   'The history object to act on.',
                   'Gtk2::Ex::History',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('way',
                   'Which way',
                   'Which way to go in the history when activated, either back or forward.',
                   'Gtk2::Ex::History::Way',
                   'back',
                   Glib::G_PARAM_READWRITE),
                ];

my $connect_hook_id;
my $disconnect_hook_id;

sub INIT_INSTANCE {
  my ($self) = @_;
  ### History-Action INIT_INSTANCE()

  $connect_hook_id ||= Gtk2::ActionGroup->signal_add_emission_hook
    (connect_proxy => \&_do_connect_proxy);
  $disconnect_hook_id ||= Gtk2::ActionGroup->signal_add_emission_hook
    (disconnect_proxy => \&_do_disconnect_proxy);

  _update ($self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### History-Action SET_PROPERTY(): $pname

  $self->{$pname} = $newval;  # per default GET_PROPERTY
  _update ($self);
}

# Gtk2::ActionGroup 'connect-proxy' emission hook handler
sub _do_connect_proxy {
  my ($invocation_hint, $parameters) = @_;
  my ($actiongroup, $self, $toolitem) = @$parameters;
  ### History-Action _do_connect_proxy(): "@{[$self->get_name]} $self onto $toolitem"
  ### child: $toolitem->get_child

  my $button;
  if ($self->isa(__PACKAGE__)
      && $toolitem->isa('Gtk2::ToolItem')
      && ($button = $toolitem->get_child)
      && $button->isa('Gtk2::Button')) {

    # must have 'button-release-mask' or the menu doesn't pop down on button
    # release, for some reason
    require Gtk2::Ex::WidgetEvents;
    $toolitem->{(__PACKAGE__)}->{'wevents'}
      = Gtk2::Ex::WidgetEvents->new ($button, ['button-release-mask']);

    require Glib::Ex::SignalIds;
    Scalar::Util::weaken (my $weak_self = $self);
    $toolitem->{(__PACKAGE__)}->{'ids'} = Glib::Ex::SignalIds->new
      ($button,
       $button->signal_connect
       (button_press_event => \&_do_button_press_event, \$weak_self));
    ### ids: $toolitem->{(__PACKAGE__)}->{'ids'}
  }
  return 1; # keep emission hook
}

# Gtk2::ActionGroup 'disconnect-proxy' emission hook handler
sub _do_disconnect_proxy {
  my ($invocation_hint, $parameters) = @_;
  my ($actiongroup, $action, $widget) = @$parameters;
  ### History-Action _do_disconnect_proxy(): "@{[$action->get_name]} $action from $widget"

  delete $widget->{(__PACKAGE__)};
  return 1; # keep emission hook
}

# 'button-press-event' handler on a toolitem button child
sub _do_button_press_event {
  my ($button, $event, $ref_weak_self) = @_;
  ### History-Action _do_button_press_event(): $event->button
  my $self = $$ref_weak_self || return;
  if ($event->button == 3 && (my $history = $self->{'history'})) {
    require Gtk2::Ex::History::Menu;
    Gtk2::Ex::History::Menu->new_popup (history => $history,
                                        way     => $self->get('way'),
                                        event   => $event);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _update {
  my ($self) = @_;
  my $way = $self->get('way');

  $self->set (stock_id => "gtk-go-$way",
              tooltip  => ($way eq 'back'
                           ? __('Go back.')
                           : __('Go forward.')));

  my $history = $self->{'history'};
  $self->{'connp'} = $history && Glib::Ex::ConnectProperties->dynamic
    ([$history->model($way), 'model-rows#not-empty'],
     [$self, 'sensitive']);
}

sub _do_activate {
  my ($self) = @_;
  my $history = $self->{'history'} || return;
  my $way = $self->get('way');
  $history->$way;
}

1;
__END__

=for stopwords tooltip popup UIManager enum Ryde hashref Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History::Action -- Gtk2::Action to go back or forward in a history

=for test_synopsis my ($my_history, $actiongroup)

=head1 SYNOPSIS

 use Gtk2::Ex::History::Action;
 my $action = Gtk2::Ex::History::Action->new
                 (name    => 'ForwardInHistory',
                  way     => 'forward',
                  history => $my_history);
 $actiongroup->add_action_with_accel ($action, '<Ctrl><Shift>F');

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::History::Action> is a subclass of C<Gtk2::Action>.

    Gtk2::Widget
      Gtk2::Action
        Gtk2::Ex::History::Action

=head1 DESCRIPTION

C<Gtk2::Ex::History::Action> invokes either C<back> or C<forward> on a given
C<Gtk2::Ex::History>.  The "stock" icon and tooltip follow the direction.
The action is insensitive when the history is empty.

When the action is used on a toolbar button a mouse button-3 handler is
added to popup C<Gtk2::Ex::History::Menu>.

If you're not using UIManager and its actions system then see
L<Gtk2::Ex::History::Button> for similar button-3 behaviour.

There's no accelerator keys offered as yet.  "B" and "F" would be natural,
but would depend what other things are in the UIManager and whether letters
should be reserved for text entry etc, or are available as accelerators.
Control-B and Control-F aren't good choices if using a text entry as they're
cursor movement in the Emacs style
F</usr/share/themes/Emacs/gtk-2.0-key/gtkrc>.

=head1 FUNCTIONS

=over 4

=item C<< $action = Gtk2::Ex::History::Action->new (key => value, ...) >>

Create and return a new action object.  Optional key/value pairs set initial
properties per C<< Glib::Object->new >>.

The C<history> property is what to act on, and C<way> for back or forward.
The usual action C<name> property should be set to identify it in a
UIManager or similar.  The name can be anything desired.  Just "Back" and
"Forward" are good, or something more to distinguish it from other actions.

    my $action = Gtk2::Ex::History::Action->new
                    (name    => 'ForwardHistory',
                     way     => 'forward',
                     history => $history);

=back

=head1 PROPERTIES

=over 4

=item C<history> (C<Gtk2::Ex::History> object, default C<undef>)

The history object to act on.

=item C<way> (enum C<Gtk2::Ex::History::Way>, default 'back')

The direction to go, either "back" or "forward".

The "stock" icon is set from this, either C<gtk-go-back> or
C<gtk-go-forward>.

=back

=head1 SEE ALSO

L<Gtk2::Ex::History>,
L<Gtk2::Ex::History::Button>,
L<Gtk2::Action>,
L<Gtk2::ActionGroup>,
L<Gtk2::UIManager>

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

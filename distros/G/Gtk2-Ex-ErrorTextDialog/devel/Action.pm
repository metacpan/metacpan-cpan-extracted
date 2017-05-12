# Copyright 2010, 2011, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ErrorTextDialog::Action;
use 5.008;
use strict;
use warnings;
use Scalar::Util;

use Gtk2;
use Locale::TextDomain ('Gtk2-Ex-ErrorTextDialog');

our $VERSION = 11;

# uncomment this to run the ### lines
use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Action',
  signals => { activate => \&_do_activate };

# "name" is construct-only.  Offer a default through new(), until there's
# some sort of CONSTRUCTOR callback in Glib::Object subclassing.
sub new {
  my $class = shift;
  {
    my %params = @_;
    unless (exists $params{'name'}) {
      unshift @_, name => 'ErrorTextDialog';
    }
  }
  return $class->SUPER::new (@_);
}

sub INIT_INSTANCE {
  my ($self) = @_;
  ### ErrorTextDialog-Action INIT_INSTANCE()

  $self->set (label    => __('Errors'),
              stock_id => 'dialog-error',
              tooltip  => __('Popup the errors dialog.'));
}

sub _do_activate {
  my ($self) = @_;
  ### ErrorTextDialog-Action _do_activate(): @_
  require Gtk2::Ex::ErrorTextDialog;
  my $dialog = Gtk2::Ex::ErrorTextDialog->instance;
  $dialog->present;
}

1;
__END__

=for stopwords 

=head1 NAME

Gtk2::Ex::ErrorTextDialog::Action -- Gtk2::Action to popup the errors dialog

=for test_synopsis my ($actiongroup)

=head1 SYNOPSIS

 use Gtk2::Ex::ErrorTextDialog::Action;
 my $action = Gtk2::Ex::ErrorTextDialog::Action->new;
 $actiongroup->add_action_with_accel ($action, '<Ctrl><Shift>E');

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::ErrorTextDialog::Action> is a subclass of C<Gtk2::Action>.

    Gtk2::Widget
      Gtk2::Action
        Gtk2::Ex::ErrorTextDialog::Action

=head1 DESCRIPTION

C<Gtk2::Ex::ErrorTextDialog::Action> invokes either C<back> or C<forward> on
a given C<Gtk2::Ex::ErrorTextDialog>.  The "stock" icon and tooltip follow
the direction.  The action is insensitive when the history is empty.

When the action is used on a toolbar button a mouse button-3 handler is
added to popup C<Gtk2::Ex::ErrorTextDialog::Menu>.

If you're not using UIManager and its actions system then see
L<Gtk2::Ex::ErrorTextDialog::Button> for similar button-3 behaviour.

There's no accelerator keys offered as yet.  "B" and "F" would be natural,
but would depend what other things are in the UIManager and whether letters
should be reserved for text entry etc, or are available as accelerators.
Control-B and Control-F aren't good choices if using a text entry as they're
cursor movement in the Emacs style
F</usr/share/themes/Emacs/gtk-2.0-key/gtkrc>.

=head1 FUNCTIONS

=over 4

=item C<< $action = Gtk2::Ex::ErrorTextDialog::Action->new (key => value, ...) >>

Create and return a new action object.  Optional key/value pairs set initial
properties per C<< Glib::Object->new >>.

The C<history> property is what to act on, and C<way> for back or forward.
The usual action C<name> property should be set to identify it in a
UIManager or similar.  The name can be anything desired.  Just "Back" and
"Forward" are good, or add more to distinguish it from other actions.

    my $action = Gtk2::Ex::ErrorTextDialog::Action->new
                    (name    => 'ForwardErrorTextDialog',
                     way     => 'forward',
                     history => $history);

=back

=head1 PROPERTIES

=over 4

=item C<name> (string, default "ErrorTextDialog")

=back

=head1 SEE ALSO

L<Gtk2::Ex::ErrorTextDialog>,
L<Gtk2::Action>,
L<Gtk2::ActionGroup>,
L<Gtk2::UIManager>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-errortextdialog/index.html>

=head1 LICENSE

Gtk2-Ex-ErrorTextDialog is Copyright 2010, 2011, 2013 Kevin Ryde

Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-ErrorTextDialog.  If not, see L<http://www.gnu.org/licenses/>.

=cut

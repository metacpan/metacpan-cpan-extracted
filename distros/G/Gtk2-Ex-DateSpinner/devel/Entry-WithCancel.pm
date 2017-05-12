# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Entry::WithCancel;
use 5.008;
use strict;
use warnings;
# version 1.180 for perl subclass overriding GInterfaces from superclass
use Gtk2 1.180;

our $VERSION = 9;

use Glib::Object::Subclass
  'Gtk2::Entry',
  signals => { activate        => \&_do_activate,
               editing_done    => \&_do_editing_done,
               cancel => { param_types   => [],
                           return_type   => undef,
                           flags         => [ 'action','run-last' ],
                           class_closure => \&_do_cancel,
                         },
             },
  interfaces => [ 'Gtk2::CellEditable' ],
  properties => [ Glib::ParamSpec->boolean
                  ('editing-cancelled',
                   'editing-cancelled',
                   'True if editing was cancelled with Escape rather than activated with Return etc.',
                   0, # default
                   Glib::G_PARAM_READWRITE) ];

# In GtkEntry, its gtk_cell_editable_key_press_event() used under the
# start_editing stuff has Escape, Up and Down hard coded.  Here it's through
# keybindings for configurability.
#
# Priority level "gtk" treats this as widget level default, for overriding
# by application or user RC.
#
Gtk2::Rc->parse_string (<<'HERE');
binding "Gtk2__Ex__Entry__WithCancel_keys" {
  bind "Escape" { "cancel" () }
}
class "Gtk2__Ex__Entry__WithCancel"
  binding:gtk "Gtk2__Ex__Entry__WithCancel_keys"
HERE

# # Priority level "gtk" treats this as widget level default, for overriding
# # by application or user RC.
# #
# Gtk2::Rc->parse_string (<<'HERE');
# binding "Gtk2__Ex__DateSpinner__CellRenderer_keys" {
#   bind "Up"   { "activate" () }
#   bind "Down" { "activate" () }
# }
# widget "Gtk2__Ex__DateSpinner__CellRenderer_entry"
#   binding:gtk "Gtk2__Ex__DateSpinner__CellRenderer_keys"
# HERE

# DEBUG
# {
#   *SET_PROPERTY = sub {
#     my ($self, $pspec, $newval) = @_;
#     print "Entry::WithCancel: SET_PROPERTY ",$pspec->get_name,
#                    " ",(defined $newval ? $newval : 'undef'),"\n";
#     $self->{$pspec->get_name} = $newval;
#   };
# }

# GtkCellEditable interface 'start_editing',
# per gtk_cell_editable_start_editing().
#
# Don't want to chain up to GtkEntry superclass gtk_entry_start_editing() of
# this.  Using own 'editing_active' flag here instead of the signal
# connections that gtk_entry_start_editing() establishes.  (That behaviour
# doesn't seem to be documented, so probably best not to rely on it ...)
#
sub START_EDITING {
  my ($self, $event) = @_;
  ### Entry-WithCancel: START_EDITING() ...
  $self->set ('editing-cancelled', 0);
  $self->{'editing_active'} = 1;
}

# 'editing-done' class closure, from GtkCellEditable interface
sub _do_editing_done {
  my ($self) = @_;
  $self->{'editing_active'} = 0;
  return $self->signal_chain_from_overridden;
}

# like gtk_cell_editable_entry_activated()
#
# In GtkEntry gtk_cell_editable_entry_activated() and
# gtk_cell_editable_key_press_event() are done as signal connections on
# self.  Is there a reason for that?  Seems easier to test a flag for when
# to act rather than connect and disconnect.
#
sub _do_activate {
  my ($self) = @_;
  ### Entry-WithCancel: _do_activate() ...
  $self->set ('editing-cancelled', 0);
  _emit_editing_done ($self, 0);
  return $self->signal_chain_from_overridden;
}

sub cancel {
  my ($self) = @_;
  $self->signal_emit ('cancel');
}

# 'cancel' class closure
sub _do_cancel {
  my ($self) = @_;
  ### Entry-WithCancel cancel signal ...
  $self->set ('editing-cancelled', 1);
  _emit_editing_done ($self, 1); # if active
}

sub _emit_editing_done {
  my ($self, $cancelled) = @_;
  if ($self->{'editing_active'}) {
    $self->editing_done;
    $self->remove_widget;
  }
}

1;
__END__

=head1 NAME

Gtk2::Ex::Entry::WithCancel -- Gtk2::Entry with a "cancelled" property

=head1 SYNOPSIS

 use Gtk2::Ex::Entry::WithCancel;
 my $entry = Gtk2::Ex::Entry::WithCancel->new;

 $entry->signal_connect ('editing-done',
                         sub {
                           if ($entry->get('editing-cancelled')) {
                             dont_save_the_value();
                           } else {
                             act_on_the_value();
                           }
                         });

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Entry::WithCancel> is a subclass of C<Gtk2::Entry>.

    Gtk2::Widget
      Gtk2::Entry
        Gtk2::Ex::Entry::WithCancel

And implements the interface

    Gtk2::CellEditable

=head1 DESCRIPTION

This is a little subclass of C<Gtk::Entry> with an "editing-cancelled" flag
made available for editing through the C<Gtk2::CellEditable> interface.

The main use for this is as an editing widget for a C<Gtk2::CellRenderer>.
The renderer connects a handler to the C<editing-done> signal (per the
C<Gtk2::CellEditable> interface) and in that handler can check the
C<editing-cancelled> property to know whether the contents of the entry
widget should be applied, etc, or whether the user wanted to cancel the
edit.

C<Gtk2::Entry> already has such a flag (mis-spelt C<editing_canceled>) but
doesn't make it publicly available, as of Gtk 2.16 or thereabouts.  Is that
right?  At any rate this subclass gets the desired effect.

=head1 FUNCTIONS

=over 4

=item C<< $entry = Gtk2::Ex::Entry::WithCancel->new (key=>value,...) >>

Create and return a new C<Entry::WithCancel> widget.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >>.  Eg.

    my $entry = Gtk2::Ex::Entry::WithCancel->new
                  (xalign => 0.5);

=item C<< $entry->cancel () >>

Emit the C<cancel> action signal, performing that action (see L</SIGNALS>
below).

=back

=head1 PROPERTIES

=over 4

=item C<editing-cancelled> (boolean, default false)

Cleared by C<start_editing> (the C<Gtk2::CellEditable> function) and then
set to true or false under an Escape keypress, C<cancel> signal (below), or
C<activate> signal (C<Gtk2::Widget>).  C<editing-done> signal handlers (from
C<Gtk2::CellEditable>) can then consult the value.

=back

=head1 SIGNALS

=over 4

=item C<cancel> (action, no parameters)

Perform the cancel action, which is to set the C<editing-cancelled>
property, and if editing is active from a C<start_editing> then emit signals
C<editing-done> and C<remove-widget>.

The C<Escape> key binding runs this signal.  You can bind other keys from an
RC file (see C<Gtk2Rc>) to do a cancel.  The class name is
C<Gtk2__Ex__Entry__WithCancel>, so for example to make F12 cancel

    binding "my_cancel_keys" {
      bind "F12" { "cancel" () }
    }
    class "Gtk2__Ex__Entry__WithCancel" binding "my_cancel_keys"

=back

=head1 SEE ALSO

L<Gtk2::Entry>, L<Gtk2::CellEditable>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Gtk2-Ex-DateSpinner is Copyright 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-DateSpinner.  If not, see L<http://www.gnu.org/licenses/>.

=cut

#
# Unused:
#
# This induces a cancel action in a GtkEntry, but there's no apparent way to
# get the editing_canceled field.
#
# package Gtk2::Ex::EntryBits;
# use strict;
# use warnings;
# 
# sub cancel {
#   my ($entry) = @_;
#   my $event = Gtk2::Gdk::Event->new('key-press');
#   $event->keyval (Gtk2::Gdk->keyval_from_name ('Escape'));
#   $entry->signal_emit ('key_press_event', $event);
# }
# 


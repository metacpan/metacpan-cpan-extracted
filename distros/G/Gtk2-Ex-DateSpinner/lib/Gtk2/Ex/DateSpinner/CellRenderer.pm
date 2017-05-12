# Copyright 2008, 2009, 2010, 2013 Kevin Ryde

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

package Gtk2::Ex::DateSpinner::CellRenderer;
use 5.008;
use strict;
use warnings;
use Gtk2;

our $VERSION = 9;

use Glib::Object::Subclass
  'Gtk2::CellRendererText';

# gtk_cell_renderer_start_editing()
#
# Cannot use parent $self->SUPER::START_EDITING from Gtk2::CellRendererText
# to do the Gtk2::Entry creation because it sets that widget to stop editing
# on losing key focus (handler gtk_cell_renderer_text_focus_out_event()),
# which includes the switch away to the DateSpinner::PopupEntry window, the
# effect being to immediately stop editing when that window pops up.
#
# There doesn't seem to be an easy way to suppress that
# gtk_cell_renderer_text_focus_out_event() editing-done behaviour.  Can't
# catch focus-out and not propagate it, as the GtkEntry code needs it.
#
sub START_EDITING {
  my ($self, $event, $view, $pathstr, $back_rect, $cell_rect, $flags) = @_;
  ### Renderer START_EDITING
  ### $pathstr
  ### back: $back_rect->x.",".$back_rect->y." ".$back_rect->width."x".$back_rect->width
  ### cell: $cell_rect->x.",".$cell_rect->y." ".$cell_rect->width."x".$cell_rect->width

  $self->{'pathstr'} = $pathstr;

  # no frame and copy 'xalign' across, the same as CellRendererText does
  my $entry = Gtk2::Entry->new;
  $entry->set (has_frame => 0,
               xalign    => $self->get('xalign'));
  $entry->signal_connect (key_press_event => \&_do_entry_key_press);
  ### edit with: "$entry"

  {
    # This is a hack for Gtk2-Perl 1.210 and earlier ensuring
    # gtk2perl_cell_renderer_start_editing() doesn't see $entry with a
    # refcount of 1, since it would increment that as a protection against
    # premature destruction -- but then never decrement.  If the refcount is
    # 2 it leaves it alone.
    Glib::Idle->add (sub { 0 }, # Glib::SOURCE_REMOVE
                     $entry);
  }

  require Gtk2::Ex::DateSpinner::PopupForEntry;
  Gtk2::Ex::DateSpinner::PopupForEntry->new (entry => $entry);

  my $value = $self->get('text');
  $entry->set_text (defined $value ? $value : '');
  $entry->select_region (0, -1);

  my $ref_weak_self = \$self;
  require Scalar::Util;
  Scalar::Util::weaken ($ref_weak_self);
  $entry->signal_connect (editing_done => \&_do_entry_editing_done,
                          $ref_weak_self);

  # {
  #   $entry->signal_connect (destroy => sub {
  #                             print "editable: destroy\n";
  #                           });
  #   $entry->signal_connect (focus_out_event => sub {
  #                             print "editable: focus_out_event\n";
  #                             return 0; # Gtk2::EVENT_PROPAGATE
  #                           });
  # }

  $entry->show;
  return $entry;
}

# 'key-press-event' handler for Gtk2::Entry
# An Escape for cancelling the edit is noted in a flag.
# This is like gtk_cell_editable_key_press_event() notes in its (mis-spelt)
# "editing_canceled" field.  Would prefer to look at that field, but it's
# private.
sub _do_entry_key_press {
  my ($entry, $event) = @_;
  if ($event->keyval == Gtk2::Gdk->keyval_from_name('Escape')) {
    $entry->{'editing_cancelled'} = 1;
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}

# 'editing-done' handler on the Gtk2::Entry
#
sub _do_entry_editing_done {
  my ($entry, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### DateSpinner-CellRenderer _do_entry_editing_done() ...
  ### cancelled: $entry->{'editing_cancelled'}

  my $cancelled = $entry->{'editing_cancelled'};
  $self->stop_editing ($cancelled);
  if (! $cancelled) {
    $self->signal_emit ('edited', $self->{'pathstr'}, $entry->get_text);
  }
}

1;
__END__

=for stopwords renderer DateSpinner Gtk2-Ex-DateSpinner YYYY-MM-DD popup decrement Ok Eg Gtk2-Perl Ryde

=head1 NAME

Gtk2::Ex::DateSpinner::CellRenderer -- date cell renderer with DateSpinner for editing

=for test_synopsis my ($treeviewcolumn)

=head1 SYNOPSIS

 use Gtk2::Ex::DateSpinner::CellRenderer;
 my $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new;

 $treeviewcolumn->pack_start ($renderer, 0);
 $treeviewcolumn->add_attribute ($renderer, text => 0);
 $renderer->signal_connect (edited => sub { some_code() });

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::DateSpinner::CellRenderer> is a subclass of
C<Gtk2::CellRendererText>.

    Gtk2::Object
      Gtk2::CellRenderer
        Gtk2::CellRendererText
          Gtk2::Ex::DateSpinner::CellRenderer

=head1 DESCRIPTION

C<DateSpinner::CellRenderer> displays an ISO format YYYY-MM-DD date as a
text field.  Editing the field presents both a C<Gtk2::Entry> widget and a
popup C<Gtk2::Ex::DateSpinner>.

    +------------+
    | 2008-06-14 |
    +------------+
    +-----------------------------------------------------+
    | +------+   +----+   +----+         +----+ +------+  |
    | | 2008 |^  |  6 |^  | 14 |^  Sat   | Ok | |Cancel|  |
    | +------+v  +----+v  +----+v        +----+ +------+  |
    +-----------------------------------------------------+

The popup allows mouse clicks or arrow keys to increment or decrement the
date components.  This is good if you often just want to bump a date up or
down.  And when you're displaying YYYY-MM-DD it makes sense to present it
like that for editing.  Of course there's a huge range of other ways you
could display or edit a date.

See F<examples/cellrenderer.pl> for a complete program with a C<TreeView>
and a C<DateSpinner::CellRenderer>.

=head2 Details

The date to display, and edit, is taken from the renderer C<text> property
and must be in YYYY-MM-DD format.  A new edited value is passed to the
C<edited> signal emitted from the renderer in the usual way (see
L<Gtk2::CellRenderer>).  Text renderer properties affect the display and
C<xalign> in the renderer is copied to the Entry widget so it's left, right
or centred while editing the same as displayed (like C<CellRendererText>
does).

Pressing Return in the fields accepts the values.  Pressing Escape cancels
the edit.  Likewise the Ok and Cancel button widgets.  The stock
accelerators activate the buttons too.  These are Alt-O and Alt-C in an
English locale, though Return and Escape are easier to remember.

Note you must set the C<editable> property (per the base class
C<Gtk2::CellRendererText>) to make the C<DateSpinner::CellRenderer>
editable, otherwise nothing happens when you click.  That property can be
controlled by the usual model column or data function mechanisms to make
some rows editable and others not.

=head1 FUNCTIONS

=over 4

=item C<< $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new (key=>value,...) >>

Create and return a new DateSpinner::CellRenderer object.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >>.  Eg.

    my $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new
                     (editable => 1);

=back

=head1 OTHER NOTES

C<DateSpinner::CellRenderer> creates new a new entry widget and a new popup
window for each edit and both are destroyed on accept or cancel.  This is
the same as the base C<CellRendererText> does.  It's a little wasteful, but
is normally fast enough for casual editing and it might save some memory in
between.

The code for the popup is in the C<Gtk2::Ex::DateSpinner::PopupForEntry>
component.  It's not loaded until the first edit and is only meant for
internal use as yet.

=head1 SEE ALSO

L<Gtk2::Ex::DateSpinner>, L<Gtk2::CellRendererText>

Gtk2-Perl F<examples/cellrenderer_date.pl> does a similar display/edit
popping up a C<Gtk2::Calendar>.  See
L<Gtk2::Ex::Datasheet::DBI|Gtk2::Ex::Datasheet::DBI> for a version of it in
use.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-datespinner/index.html>

=head1 LICENSE

Gtk2-Ex-DateSpinner is Copyright 2008, 2009, 2010, 2013 Kevin Ryde

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

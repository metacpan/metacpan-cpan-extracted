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

package Gtk2::Ex::TreeViewBits;
use 5.008;
use strict;
use warnings;
use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;


sub toggle_expand_row {
  my ($treeview, $path, $open_all) = @_;
  if ($treeview->row_expanded ($path)) {
    $treeview->collapse_row ($path);
  } else {
    $treeview->expand_row ($path, $open_all);
  }
}

sub remove_selected_rows {
  my ($treeview) = @_;
  my $model = $treeview->get_model;

  # foreach converting path to rowref frees each path as converted, whereas
  # a "map" keeps them all until the end, to perhaps save a couple of bytes
  # of peak memory use.
  #
  my @rows = $treeview->get_selection->get_selected_rows;  # paths
  foreach (@rows) {
    $_ = Gtk2::TreeRowReference->new($model,$_);  # rowrefs
  }

  # shifting frees each rowref as it's processed, to save
  # gtk_tree_row_ref_deleted() going through now removed rowrefs
  #
  while (my $rowref = shift @rows) {
    my $path = $rowref->get_path || next;  # if somehow gone away
    if (my $iter = $model->get_iter ($path)) {
      $model->remove ($iter);
    } else {
      carp 'Oops, selected row path "',$path->to_string,'" does not exist';
    }
  }
}

# In Gtk 2.12.12, when the row is bigger than the window, set_cursor()
# somehow likes to scroll to the opposite end of the row, presumably as a
# way of showing you the extents.  So if already positioned at the start of
# the row then set_cursor() scrolls to the end of it.  The scroll_to_cell()
# here moves back to the start of the row, but not before an unattractive
# bit of flashing.  There doesn't seem any clean way to avoid that.  It'd be
# much better if TreeView didn't draw immediately, but went through the
# queue_redraw / process_updates so as to collapse multiple programmatic
# changes.
#
sub scroll_cursor_to_path {
  my ($treeview, $path) = @_;
  ### scroll_cursor_to_path() path: $path->to_string
  my $model = $treeview->get_model || return;  # nothing to make visible

  # check path exists, in particular since ->scroll_to_cell() gives an
  # unsightly warning if the path is invalid
  $model->get_iter($path) or return;

  $treeview->expand_to_path ($path);
  $treeview->set_cursor ($path);

  my $bin_window = $treeview->get_bin_window || return; # if unrealized

  my ($bin_width, $bin_height) = $bin_window->get_size;
  ### $bin_height

  my $rect = $treeview->get_cell_area ($path, undef);
  ### path: "y=".$rect->y." height=".$rect->height." end=".($rect->y + $rect->height)

  if ($rect->y >= 0 && $rect->y + $rect->height <= $bin_height) {
    ### fully visible, don't scroll
    return;
  }
  my $row_align = ($rect->height > $bin_height ? 0 : 0.5);
  ### scroll align to: $row_align
  $treeview->scroll_to_cell ($path,
                             undef, # no column scroll
                             1,     # use_align
                             $row_align,
                             0);    # col_align
}

1;
__END__

=for stopwords TreeModel ListStore TreeStore TreeView Ryde Gtk2-Ex-WidgetBits Gtk2 Gtk

=head1 NAME

Gtk2::Ex::TreeViewBits - various helpers for Gtk2::TreeView

=head1 SYNOPSIS

 use Gtk2::Ex::TreeViewBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::TreeViewBits::toggle_expand_row ($treeview, $path) >>

Toggle the row at C<$path> between expanded or collapsed.  C<$path> is a
C<Gtk2::TreePath>.

This is a simple combination of check C<row_expanded> then either
C<expand_row> or C<collapse_row>.  It's handy for making a toggle in the
style of the Space key (C<toggle-cursor-row>), but say on a button press
rather than the cursor row.

See F<examples/treeview-toggle-expand.pl> in the Gtk2-Ex-WidgetBits sources
for a complete program using this under a C<row-activate> signal.

=item C<< Gtk2::Ex::TreeViewBits::remove_selected_rows ($treeview) >>

Remove the currently selected rows of C<$treeview> from the underlying
TreeModel.  If nothing is selected then do nothing.

Rows are removed using C<< $model->remove() >> as per C<Gtk2::ListStore> or
C<Gtk2::TreeStore>.  The model doesn't have to be a ListStore or TreeStore,
only something with a compatible C<remove()> method.

Currently this is implemented by tracking rows to be removed using a
C<Gtk2::TreeRowReference> on each and removing them one by one.  This isn't
fast, but is safe against additional changes to the model or the selection
during the removals.

=item C<< Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path) >>

Move the TreeView cursor to C<$path>, expanding and scrolling if necessary
to ensure the row is then visible.

This function is a combination of C<expand_row()>, C<set_cursor()> and
C<scroll_to_cell()>, except the scroll is skipped if C<$path> is already
fully visible.  Avoiding a scroll is good because it avoids content jumping
around when merely moving to different nearby rows.

When a scroll is done the row is centred in the C<$treeview> window.  If the
row is bigger than the window then it's positioned at the start of the
window.

=back

=head1 BUGS

As of Gtk 2.12.12, if a TreeView is in C<fixed-height-mode> and the last row
is unexpanded then a C<scroll_cursor_to_path()> to a sub-row of it doesn't
scroll correctly.  It expands, moves the cursor, but the scroll goes only to
that last parent row, not the intended sub-row.  Believe this is a bug in
Gtk.

=head1 SEE ALSO

C<Gtk2::TreeView>, C<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

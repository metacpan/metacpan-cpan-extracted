#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-CellLayout-Base.
#
# Gtk2-Ex-CellLayout-Base is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-CellLayout-Base is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-CellLayout-Base.  If not, see <http://www.gnu.org/licenses/>.


# This is a poor man's version of Gtk2::CellView, illustrating how to write
# a simple viewer with Gtk2::Ex::CellLayout::Base.
#
# The viewer takes a Gtk2::TreeModel to get its data as usual, and for
# simplicity just a single "rownum" is the row from that model to display.
# The display itself is the CellRenderers one after the other horizontally.
#
# The mainline code at the end makes use of the new widget class, creating a
# viewer plus a spinner to update the rownum displayed.  If you resize with
# the window manager you can see how the pack_start renderer goes from the
# left and the pack_end from the right.


package PoorMansCellView;
use 5.008;
use strict;
use warnings;
use List::Util qw(min max);
use POSIX qw(INT_MAX);

use Gtk2 1.180;  # 1.180 for Gtk2::CellLayout interface
use base 'Gtk2::Ex::CellLayout::Base';

use Glib::Object::Subclass
  'Gtk2::DrawingArea',
  interfaces => [ 'Gtk2::CellLayout', 'Gtk2::Buildable' ],
  signals => { size_request => \&_do_size_request,
               expose_event => \&_do_expose_event,
             },
  properties => [ Glib::ParamSpec->object
                  ('model',
                   'model',
                   'TreeModel giving the items to display.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('rownum',
                   'rownum',
                   'Row number in the model to display.',
                   0, INT_MAX,
                   0, # default
                   Glib::G_PARAM_READWRITE),
                ];

use constant DEBUG => 0;

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'rownum'} = 0;  # default
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  # NOTE: extreme slackness here, should disconnect from the previously set
  # model, if any, and the hard reference $self in the userdata is a
  # circular reference
  if ($pname eq 'model') {
    $newval->signal_connect (row_changed    => \&_do_row_changed,    $self);
    $newval->signal_connect (row_inserted   => \&_do_row_inserted,   $self);
    $newval->signal_connect (row_deleted    => \&_do_row_deleted,    $self);
    $newval->signal_connect (rows_reordered => \&_do_rows_reordered, $self);
  }

  $self->queue_resize;
  $self->queue_draw;
}

# 'size_request' class closure
#
# This is quite a thorough look at the data to decide a size; it inspects
# every row looking for maximum height and maximum total width of the
# renderers.
#
# If the model has a huge number of rows this could be very slow.  The
# alternatives would be for instance,
#   - Only look at the single requested rownum.  This would mean a resize
#     every time a different row is chosen, but perhaps that's acceptable or
#     even desirable for some uses.
#   - Let the application designate a representative sized row, or something
#     like "fixed-height-mode" from Gtk2::TreeView, allowing shortcuts under
#     suitable data.
#
sub _do_size_request {
  my ($self, $req) = @_;
  if (DEBUG) { print "$self size_request\n"; }

  my $max_width = 0;
  my $max_height = 0;
  if (my $model = $self->{'model'}) {
    my @cells = $self->GET_CELLS;

    for (my $iter = $model->iter_nth_child (undef, 0);
         $iter;
         $iter = $model->iter_next ($iter)) {
      $self->_set_cell_data ($iter);

      my $total_width = 0;
      foreach my $cell (@cells) {
        if (! $cell->get('visible')) { next; }
        my (undef,undef, $width,$height) = $cell->get_size ($self, undef);
        $total_width += $width;
        $max_height = max ($max_height, $height);
      }
      $max_width = max ($max_width, $total_width);
    }
  }
  if (DEBUG) { print "  decide $max_width x $max_height\n"; }

  $req->width ($max_width);
  $req->height ($max_height);
}

# Subclassing from Gtk2::DrawingArea (above) makes life a little easier in
# the expose here since we draw to the entire underlying Gtk2::Gdk::Window.
# If you know what you're doing and want to save a window you can go for a
# direct subclass of Gtk2::Widget, ask for "no-window", then draw onto the
# $self->allocation part of the parent container's window.
#
# The two loops drawing first the pack_start cells then the pack_end ones
# are what the real Gtk2::CellView does.  The code there does what amounts
# to a test of $cellinfo->{'pack'}, here instead _cellinfo_starts() and
# _cellinfo_ends() grep out the respective cellinfo's.
#
# The cell 'visible' property is tested.  It's the usual way to hide cells.
# You must treat 'visible' the same in size_request as in the actual drawing
# of course.
#
# There's a bit of slackness here though,
#   - No attention is paid to the "expand" settings on the renderers: if
#     $win_width is more than the renderers need then the ones marked for
#     expand are meant to share the extra space.
#   - $self->get_direction probably ought to flip the renderer order
#     horizontally, so the "starts" go from the right and the "ends" from
#     the left.  Of course that depends whether you think the viewer ought
#     to follow a notion of direction like that, but it's usually what you
#     want in a right-to-left language locale.
#
sub _do_expose_event {
  my ($self, $event) = @_;
  if (DEBUG) { print "$self expose\n"; }

  my $model = $self->{'model'} || return 0; # Gtk2::EVENT_PROPAGATE
  my $rownum = $self->{'rownum'};
  my $iter = $model->iter_nth_child (undef, $rownum)
    || return 0; # Gtk2::EVENT_PROPAGATE, no such row $rownum

  $self->_set_cell_data ($iter);   # prepare the renderers

  my $window = $self->window;
  my ($win_width, $win_height) = $window->get_size;
  my $expose_rect = $event->area;

  # draw the pack_start's left to right
  my $x = 0;
  foreach my $cellinfo ($self->_cellinfo_starts) {
    my $cell = $cellinfo->{'cell'};
    if (! $cell->get('visible')) { next; }
    my ($x_offset, $y_offset, $width, $height) = $cell->get_size ($self,undef);
    my $rect = Gtk2::Gdk::Rectangle->new ($x,0, $width,$win_height);
    $cell->render ($self->window, $self, $rect, $rect, $expose_rect, []);
    $x += $width;
  }

  # draw the pack_end's right to left
  $x = $win_width;
  foreach my $cellinfo ($self->_cellinfo_ends) {
    my $cell = $cellinfo->{'cell'};
    if (! $cell->get('visible')) { next; }
    my ($x_offset, $y_offset, $width, $height) = $cell->get_size ($self,undef);
    $x -= $width;
    my $rect = Gtk2::Gdk::Rectangle->new ($x,0, $width,$win_height);
    $cell->render ($self->window, $self, $rect, $rect, $expose_rect, []);
  }

  return 0; # Gtk2::EVENT_PROPAGATE
}

# If the model changes we might have to redraw, and changed data contents
# could mean a new preferred size.
#
# There's a lot of slackness here, since a redraw is only actually needed if
# the "rownum" element being displayed has changed or moved.
#
sub _do_row_changed {
  my ($model, $path, $iter, $self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}
sub _do_row_inserted {
  my ($model, $ins_path, $ins_iter, $self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}
sub _do_row_deleted {
  my ($model, $del_path, $self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}
sub _do_rows_reordered {
  my ($model, $reordered_path, $reordered_iter, $aref, $self) = @_;
  $self->queue_resize;
  $self->queue_draw;
}


#-----------------------------------------------------------------------------
# The rest here is pretty standard stuff.

package main;
use strict;
use warnings;
use Gtk2 '-init';

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $spinner = Gtk2::SpinButton->new_with_range (0, 5, 1);
$hbox->pack_start ($spinner, 0,0,0);

my $liststore = Gtk2::ListStore->new ('Glib::String');
foreach my $str ('Zero row',
                 'First',
                 'Second',
                 'Third',
                 'And fourth!') {
  $liststore->set_value ($liststore->append, 0, $str);
}

my $viewer = PoorMansCellView->new (model => $liststore);
$hbox->pack_start ($viewer, 1,1,0);

my $renderer1 = Gtk2::CellRendererText->new;
$viewer->pack_start ($renderer1, 0);
$viewer->add_attribute ($renderer1, text => 0);

my $renderer2 = Gtk2::CellRendererText->new;
$viewer->pack_end ($renderer2, 0);
$viewer->set_cell_data_func ($renderer2, \&datafunc);
sub datafunc {
  my ($viewer, $renderer2, $model, $iter) = @_;
  $renderer2->set(text => 'rownum='.$viewer->{'rownum'});
}

$spinner->signal_connect (changed => sub {
                            $viewer->set (rownum => $spinner->get_value);
                          });

$toplevel->show_all;
Gtk2->main;
exit 0;

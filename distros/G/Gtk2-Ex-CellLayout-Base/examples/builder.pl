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


# This example defines a viewer class and then in the mainline creates an
# instance of it using Gtk2::Builder.  Basically if you're sick of writing
# bloated and repetitive code to create widgets you can write even more
# bloateder and even more repetitive XML!
#
# The functions for buildable support in the new viewer class are provided
# by Gtk2::Ex::CellLayout::Base, so all the class must do is remember
# 'Gtk2::Buildable' in the "interfaces" list.
#
# As a bit of variation, the viewer here is a grid showing all rows of the
# model and each renderer across in a column.  The columns are sized
# according to the biggest output (on all rows), so they line up.
#
# The width for each column is established in _do_size_request() and then
# saved by sticking it in the $cellinfo records.  Those records are meant
# for such things and are a good place to keep extra data associated a cell
# renderer.  Of course when caching a dynamic value like "width" it's
# important to recalculate at suitable times, like when the model data
# changes, etc.


package MyRenderedGrid;
use 5.008;
use strict;
use warnings;
use List::Util qw(min max);
use POSIX qw(INT_MAX);

use Gtk2 1.180;  # need 1.180 for Gtk2::CellLayout interface
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
                   Glib::G_PARAM_READWRITE)
                ];

use constant DEBUG => 0;


sub INIT_INSTANCE {
  my ($self) = @_;
  # nothing to do here
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
sub _do_size_request {
  my ($self, $req) = @_;
  if (DEBUG) { print "$self size_request\n"; }

  my $total_height = 0;

  my $cellinfo_list = $self->{'cellinfo_list'};
  foreach my $cellinfo (@$cellinfo_list) {
    $cellinfo->{'width'} = 0;  # starting point for max() below
  }

  if (my $model = $self->{'model'}) {
    for (my $iter = $model->iter_nth_child (undef, 0);
         $iter;
         $iter = $model->iter_next ($iter)) {
      $self->_set_cell_data ($iter);

      my $total_width = 0;
      my $row_height = 0;
      foreach my $cellinfo (@$cellinfo_list) {
        my $cell = $cellinfo->{'cell'};
        if (! $cell->get('visible')) { next; }

        my (undef,undef, $width,$height) = $cell->get_size ($self, undef);
        $cellinfo->{'width'} = max ($cellinfo->{'width'}, $width);
        $row_height = max ($row_height, $height);
      }
      $total_height += $row_height;
    }
  }
  my $total_width = List::Util::sum (map {$_->{'width'}} @$cellinfo_list);

  if (DEBUG) { print "  decide $total_width x $total_height\n"; }
  $req->width ($total_width);
  $req->height ($total_height);
}

# No attention is paid to the window height here, the rows are just drawn
# according to their height.  It'd be possible to share the extra space
# among them, except that'd mean an extra pass over the model data.  If you
# wanted a spread like that you'd probably best save the row heights
# calculated in _do_size_request().
#
# Like in the cellview.pl example program there's nothing here for the
# $self->get_direction setting to reverse the rendered columns right to left
# instead of left to right.  One thing to note though is that direction
# within each renderer is up to it.  We pass it a rectangle of column width
# as its space and it decides whether to centre, or align to one edge, etc.
#
sub _do_expose_event {
  my ($self, $event) = @_;
  if (DEBUG) { print "$self expose\n"; }

  my $model = $self->{'model'} || return 0; # Gtk2::EVENT_PROPAGATE
  my $cellinfo_list = $self->{'cellinfo_list'};
  my @cells = $self->GET_CELLS;

  my $window = $self->window;
  my ($win_width, $win_height) = $window->get_size;
  my $expose_rect = $event->area;

  my $y = 0;
  for (my $iter = $model->iter_nth_child (undef, 0);
       $iter;
       $iter = $model->iter_next ($iter)) {
    $self->_set_cell_data ($iter);   # prepare the renderers

    # decide the row height
    my $row_height = List::Util::max
      (map {
        my $cell = $_->{'cell'};
        my ($x_offset,$y_offset, $width,$height)
          = $cell->get_size ($self, undef);
        $height
      } @$cellinfo_list);

    # draw the pack_start's left to right
    my $x = 0;
    foreach my $cellinfo ($self->_cellinfo_starts) {
      my $cell = $cellinfo->{'cell'};
      if (! $cell->get('visible')) { next; }
      my $width = $cellinfo->{'width'};
      my $rect = Gtk2::Gdk::Rectangle->new ($x,$y, $width,$row_height);
      $cell->render ($self->window, $self, $rect, $rect, $expose_rect, []);
      $x += $width;
    }

    # draw the pack_end's right to left
    $x = $win_width;
    foreach my $cellinfo ($self->_cellinfo_ends) {
      my $cell = $cellinfo->{'cell'};
      if (! $cell->get('visible')) { next; }
      my $width = $cellinfo->{'width'};
      $x -= $width;
      my $rect = Gtk2::Gdk::Rectangle->new ($x,$y, $width,$row_height);
      $cell->render ($self->window, $self, $rect, $rect, $expose_rect, []);
    }

    $y += $row_height;
    if ($y >= $win_height) { last; }  # small window, we've gone off screen
  }

  return 0; # Gtk2::EVENT_PROPAGATE
}

# If the model data changes we have to resize and redraw, except for a
# reorder of the rows, in which case our sizes are still good we just have
# to redraw.
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
  $self->queue_draw;
}

#-----------------------------------------------------------------------------

package main;
use strict;
use warnings;
use Gtk2 '-init';

my $builder = Gtk2::Builder->new;
$builder->add_from_string ('
<interface>
  <object class="GtkListStore" id="liststore">
    <columns>
      <column type="gchararray"/>
    </columns>
    <!-- some fun pango markup, to be displayed below first as raw text and
         then interpreted -->
    <data>
      <row> <col id="0">Zero &lt;b&gt;row&lt;/b&gt;</col> </row>
      <row> <col id="0">&lt;i&gt;First&lt;/i&gt;</col>    </row>
      <row> <col id="0">Second</col>                      </row>
      <row> <col id="0">&lt;u&gt;Third&lt;/u&gt;</col>    </row>
      <row> <col id="0">And fourth!</col>                 </row>
    </data>
  </object>

  <object class="GtkWindow" id="toplevel">
    <property name="type">toplevel</property>
    <signal name="destroy" handler="do_quit"/>
    <child>

      <object class="MyRenderedGrid" id="ticker">
        <property name="model">liststore</property>

        <child>
          <object class="GtkCellRendererText" id="renderer1">
          </object>
          <attributes>
            <attribute name="text">0</attribute>
          </attributes>
        </child>
        <child>
          <object class="GtkCellRendererText" id="renderer2">
            <property name="xpad">10</property>
          </object>
          <attributes>
            <attribute name="markup">0</attribute>
          </attributes>
        </child>
      </object>

    </child>
  </object>
</interface>
');

sub do_quit { Gtk2->main_quit; }
$builder->connect_signals;

$builder->get_object('toplevel')->show_all;
Gtk2->main;
exit 0;

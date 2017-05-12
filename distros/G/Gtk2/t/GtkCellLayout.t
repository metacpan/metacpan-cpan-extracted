#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  at_least_version => [2, 4, 0, "GtkCellLayout is new in 2.4"],
  tests => 5;

# $Id$

my $column = Gtk2::TreeViewColumn -> new();
isa_ok($column, "Gtk2::CellLayout");

my $box = Gtk2::ComboBox -> new();
isa_ok($box, "Gtk2::CellLayout");

my $entry = Gtk2::ComboBoxEntry -> new();
isa_ok($entry, "Gtk2::CellLayout");

# make sure there is a model; early versions of 2.4.x do not check for NULL
# before unreffing the model.
my $model = Gtk2::ListStore->new ('Glib::Int');
$box->set_model ($model);
$entry->set_model ($model);

my $completion = Gtk2::EntryCompletion -> new();
isa_ok($completion, "Gtk2::CellLayout");

my $renderer = Gtk2::CellRendererText -> new();

$completion -> pack_start($renderer, 0);
$completion -> clear();
$completion -> pack_end($renderer, 1);

$completion -> set_attributes($renderer, stock_id => 0);
$completion -> set_attributes($renderer);  # like calling clear
$completion -> add_attribute($renderer, activatable => 1);
$completion -> clear_attributes($renderer);

$completion -> set_cell_data_func($renderer, sub { warn @_; }, 23);
$completion -> set_cell_data_func($renderer, undef);

SKIP: {
  skip "2.12 stuff", 1
    unless Gtk2 -> CHECK_VERSION (2, 12, 0);

  # GtkEntryCompletion doesn't seem to implement get_cells yet, so we use the
  # GtkTreeViewColumn.
  my $one = Gtk2::CellRendererText -> new();
  my $two = Gtk2::CellRendererText -> new();
  $column -> pack_start($one, 0);
  $column -> pack_start($two, 1);
  is_deeply([$column -> get_cells()], [$one, $two]);
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.

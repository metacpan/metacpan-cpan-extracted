#!/usr/bin/perl -w
#
# Combo boxes 
#
# The ComboBox widget allows to select one option out of a list.
# The ComboBoxEntry additionally allows the user to enter a value
# that is not in the list of options. 
#
# How the options are displayed is controlled by cell renderers.
#

package combobox;

use strict;
use warnings;
use Glib ':constants';
use Gtk2;
#include "demo-common.h"

use constant PIXBUF_COL => 0;
use constant TEXT_COL => 1;

my $window = undef;


sub create_stock_icon_store()
{
  my @stock_id = (
    'gtk-dialog-warning',
    'gtk-stop',
    'gtk-new',
    'gtk-clear',
    undef,
    'gtk-open'    
  );

  my ($item, $pixbuf, $cellview, $iter, $store, $label);

  $cellview = Gtk2::CellView->new();
  
  $store = Gtk2::ListStore->new('Gtk2::Gdk::Pixbuf', 'Glib::String');

  for my $i (@stock_id) {
    if ($i)
    {
      $pixbuf = $cellview->render_icon($i,
                       'GTK_ICON_SIZE_BUTTON');
      $item = Gtk2::Stock->lookup($i);
      $label = $item->{label};
      # strip underscores
      $label =~ tr/_//d;
      $iter = $store->append();
      $store->set ($iter,
                  PIXBUF_COL, $pixbuf,
                  TEXT_COL, $label);
      undef $pixbuf;
    } else {
      $iter = $store->append();
      $store->set($iter,
                  PIXBUF_COL, undef,
                  TEXT_COL, "separator");
    }
  }

  $cellview->destroy();
  
  return $store;
}


# A GtkCellLayoutDataFunc that demonstrates how one can control
# sensitivity of rows. This particular function does nothing 
# useful and just makes the second row insensitive.
#
sub set_sensitive()
{
  my ($cell_layout, $cell, $tree_model, $iter, $data) = @_;

  my $path = $tree_model->get_path($iter);
  my @indices = $path->get_indices();
  my $sensitive = $indices[0] != 1;
  undef $path;

  $cell->set("sensitive", $sensitive);
}


# A GtkTreeViewRowSeparatorFunc that demonstrates how rows can be
# rendered as separators. This particular function does nothing 
# useful and just turns the fourth row into a separator.
#
sub is_separator()
{
  my ($model, $iter, $data) = @_;

  my $path = $model->get_path($iter);
  my @indices = $path->get_indices();
  my $result = $indices[0] == 4;
  undef $path;

  return $result;
}

sub create_capital_store()
{
  my %capitals = (
     "A - B" => [
        "Albany", "Annapolis", "Atlanta", "Augusta", "Austin", "Baton Rouge",
        "Bismarck", "Boise", "Boston"
     ],
     "C - D" => [
        "Carson City", "Charleston", "Cheyenne", "Columbia", "Columbus",
        "Concord", "Denver", "Des Moines", "Dover"
     ],
     "E - J" => [
        "Frankfort", "Harrisburg", "Hartford", "Helena", "Honolulu",
        "Indianapolis", "Jackson", "Jefferson City", "Juneau"
     ],
     "K - O" => [
        "Lansing", "Lincoln", "Little Rock", "Madison", "Montgomery",
        "Montpelier", "Nashville", "Oklahoma City", "Olympia"
     ],
     "P - S" => [
        "Phoenix", "Pierre", "Providence", "Raleigh", "Richmond", "Sacramento",
        "Salem", "Salt Lake City", "Santa Fe", "Springfield", "St. Paul", 
     ],
     "T - Z" => [
        "Tallahassee", "Topeka", "Trenton"
     ],
  );
  my $store = Gtk2::TreeStore->new('Glib::String');
  for my $i (sort { $a cmp $b} keys %capitals ) {
    my $iter = $store->append(undef);
    $store->set($iter, 0, $i);
    for my $capital (@{$capitals{$i}}) {
       my $iter2 = $store->append($iter);
       $store->set($iter2, 0, $capital);
    }
  }
  return $store;
}


sub is_capital_sensitive()
{
  my ($cell_layout, $cell, $tree_model, $iter, $data) = @_;
  my $sensitive = !$tree_model->iter_has_child($iter);
  $cell->set('sensitive', $sensitive);
}


sub fill_combo_entry($)
{
  my $combo = shift;
  $combo->append_text("One");
  $combo->append_text("Two");
  $combo->append_text("2\x{00bd}");
  $combo->append_text("Three");
}


# A simple validating entry
package Gtk2::MaskEntry;
use Gtk2;
use base qw(Gtk2::Entry);


sub mask_entry_set_background($)
{
    my $entry = shift;
    if ($entry->get('mask')) {
       my $re = $entry->get('mask');
       if (! ($entry->get_text() =~ $re) ) {
          $entry->modify_base('GTK_STATE_NORMAL', Gtk2::Gdk::Color->new(65535, 60000, 60000));
          return;
       }
    }
  $entry->modify_base('GTK_STATE_NORMAL', undef);
}

sub mask_entry_changed($)
{
    my $editable = shift;
    mask_entry_set_background($editable);
}

sub INIT_INSTANCE($)
{
  my $self = shift;
  $self->set('mask', undef);
}

use Glib::Object::Subclass
     'Gtk2::Entry',
     properties => [
        Glib::ParamSpec->string (
           'mask',
           '',
           '',
           'Glib::String',
           [qw/readable writable/]
        ),
     ],
     signals => {
        changed => \&mask_entry_changed,
     },
     interfaces => [
        'Gtk2::CellEditable',
     ];


sub new($@)
{
    my $class = shift;
    my $self = $class->SUPER::new();
    
    bless $self, $class;

    $self;
}

package combobox;


sub do {  
  my $do_widget = shift;
  
  if (!$window) {
    $window = Gtk2::Window->new('GTK_WINDOW_TOPLEVEL');
    $window->set_screen ($do_widget->get_screen)
      if Gtk2->CHECK_VERSION (2, 2, 0);
    $window->set_title("Combo boxes");

    $window->signal_connect("destroy", sub { $window = undef; });
    
    $window->set_border_width(10);

    my $vbox = Gtk2::VBox->new(FALSE, 2);
    $window->add($vbox);

    # A combobox demonstrating cell renderers, separators and
    # insensitive rows 
    #
    my $frame = Gtk2::Frame->new("Some stock icons");
    $vbox->pack_start($frame, FALSE, FALSE, 0);
    
    my $box = Gtk2::VBox->new(FALSE, 0);
    $box->set_border_width(5);
    $frame->add($box);
    
    my $model = create_stock_icon_store();
    my $combo = Gtk2::ComboBox->new_with_model($model);
    undef $model;
    $box->add($combo);
    
    my $renderer = Gtk2::CellRendererPixbuf->new();
    $combo->pack_start($renderer, FALSE);
    $combo->set_attributes($renderer,
                    "pixbuf", PIXBUF_COL);

    $combo->set_cell_data_func($renderer, \&set_sensitive);
    
    $renderer = Gtk2::CellRendererText->new();
    $combo->pack_start($renderer, TRUE);
    $combo->set_attributes($renderer,
                    "text", TEXT_COL);

    $combo->set_cell_data_func($renderer, \&set_sensitive);

    $combo->set_row_separator_func(\&is_separator);
    
    $combo->set_active(0);
    
    # A combobox demonstrating trees.
    #
    $frame = Gtk2::Frame->new("Where are we ?");
    $vbox->pack_start($frame, FALSE, FALSE, 0);

    $box = Gtk2::VBox->new(FALSE, 0);
    $box->set_border_width(5);
    $frame->add($box);
    
    $model = create_capital_store ();
    $combo = Gtk2::ComboBox->new_with_model($model);
    # undef $model;
    $box->add($combo);

    $renderer = Gtk2::CellRendererText->new();
    $combo->pack_start($renderer, TRUE);
    $combo->set_attributes($renderer,
                    "text", 0);
    $combo->set_cell_data_func($renderer, \&is_capital_sensitive);

    my $path = Gtk2::TreePath->new_from_indices(0, 8);
    my $iter = $model->get_iter($path);
    undef $path;
    $combo->set_active_iter($iter);

    # A GtkComboBoxEntry with validation.
    #
    $frame = Gtk2::Frame->new("Editable");
    $vbox->pack_start($frame, FALSE, FALSE, 0);
    
    $box = Gtk2::VBox->new(FALSE, 0);
    $box->set_border_width(5);
    $frame->add($box);
    
    $combo = undef;
    eval {
        $combo = Gtk2::ComboBox->text_new_with_entry();
    };
    eval {
        $combo = Gtk2::ComboBoxEntry->new_text();
    } if (!$combo);
    fill_combo_entry($combo);
    $box->add($combo);
    
    my $entry = Gtk2::MaskEntry->new();
    $entry->set('mask', "^([0-9]*|One|Two|2\x{00bd}|Three)\$");
     
    $combo->remove($combo->get_child());
    $combo->add($entry);
  }

  if (!$window->visible()) {
      $window->show_all();
  } else {
      $window->destroy();
  }

  return $window;
}


1;
__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.

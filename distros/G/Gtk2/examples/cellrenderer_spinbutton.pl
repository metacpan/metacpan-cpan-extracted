#!/usr/bin/perl -w

#
# Copyright (C) 2003-2004 by Torsten Schoenfeld, with hacks by muppet, some
# suggested by Jens Wilke.
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# $Id$
#

use strict;

use Gtk2 -init;
use Gtk2::Gdk::Keysyms;

package Kaf::CellRendererSpinButton;

use POSIX qw(DBL_MAX UINT_MAX);

use Glib qw(TRUE FALSE);
use constant x_padding => 2;
use constant y_padding => 3;

use Glib::Object::Subclass
  "Gtk2::CellRenderer",
  signals => {
    edited => {
      flags => [qw(run-last)],
      param_types => [qw(Glib::String Glib::Double)],
    },
  },
  properties => [
    Glib::ParamSpec -> double("xalign", "Horizontal Alignment", "Where am i?", 0.0, 1.0, 1.0, [qw(readable writable)]),
    Glib::ParamSpec -> boolean("editable", "Editable", "Can I change that?", 0, [qw(readable writable)]),
    Glib::ParamSpec -> uint("digits", "Digits", "How picky are you?", 0, UINT_MAX, 2, [qw(readable writable)]),
    map {
      Glib::ParamSpec -> double($_ -> [0],
                                $_ -> [1],
                                $_ -> [2],
                                0.0,
                                DBL_MAX,
                                $_ -> [3],
                                [qw(readable writable)])
    } (["value", "Value", "How much is the fish?",      0.0],
       ["min",   "Min",   "No way, I have to live!",    0.0],
       ["max",   "Max",   "Ah, you're too generous.", 100.0],
       ["step",  "Step",  "Okay.",                      5.0])
  ]
;

sub INIT_INSTANCE {
	my $self = shift;
	$self->{editable} = 0;
	$self->{digits}   = 2;
	$self->{value}    =   0.0;
	$self->{min}      =   0.0;
	$self->{max}      = 100.0;
	$self->{step}     =   5.0;
	$self->{xalign}   =   1.0;
}

sub calc_size {
  my ($cell, $layout, $area) = @_;
  my ($width, $height) = $layout -> get_pixel_size();

  return ($area ? $cell->{xalign} * ($area->width - ($width + 3 * x_padding)) : 0,
          $area ? ($area->height - $height) / 2 - y_padding : 0,
          $width + x_padding * 2,
          $height + y_padding * 2);
}

sub format_text {
	my $cell = shift;
	my $format = sprintf '%%.%df', $cell->{digits};
	sprintf $format, $cell->{value};
}

sub GET_SIZE {
  my ($cell, $widget, $area) = @_;

  my $layout = $cell -> get_layout($widget);
  $layout -> set_text($cell -> format_text);

  return $cell -> calc_size($layout, $area);
}

sub get_layout {
  my ($cell, $widget) = @_;

  return $widget -> create_pango_layout("");
}

sub RENDER {
  my ($cell, $window, $widget, $background_area, $cell_area, $expose_area, $flags) = @_;
  my $state;

  if ($flags & 'selected') {
    $state = $widget -> has_focus()
      ? 'selected'
      : 'active';
  } else {
    $state = $widget -> state() eq 'insensitive'
      ? 'insensitive'
      : 'normal';
  }

  my $layout = $cell -> get_layout($widget);
  $layout -> set_text ($cell -> format_text);

  my ($x_offset, $y_offset, $width, $height) =
  		$cell -> calc_size($layout, $cell_area);
  $widget -> get_style -> paint_layout($window,
                                       $state,
                                       1,
                                       $cell_area,
                                       $widget,
                                       "cellrenderertext",
                                       $cell_area -> x() + $x_offset + x_padding,
                                       $cell_area -> y() + $y_offset + y_padding,
                                       $layout);
}

sub _cell_editing_done {
  my ($self, $path, $new_value) = @_;
  if ($self->{_focus_out_id}) {
    $self->signal_handler_disconnect($self->{_focus_out_id});
    delete $self->{_focus_out_id};
  }
  $self->signal_emit('edited', $path, $new_value);
}

sub START_EDITING {
  my ($cell, $event, $view, $path, $background_area, $cell_area, $flags) = @_;
  my $spin_button = Gtk2::SpinButton -> new_with_range($cell -> get(qw(min max step)));

  $spin_button -> set_value($cell -> get("value"));
  $spin_button -> set_digits($cell -> get("digits"));

  $spin_button -> grab_focus();

  $spin_button -> signal_connect(key_press_event => sub {
    my ($spin_button, $event) = @_;

    if ($event -> keyval == $Gtk2::Gdk::Keysyms{ Return } ||
        $event -> keyval == $Gtk2::Gdk::Keysyms{ KP_Enter }) {
      $spin_button -> update();
      $cell -> _cell_editing_done($path, $spin_button -> get_value());
      $spin_button -> destroy();
      return TRUE;
    }
    elsif ($event -> keyval == $Gtk2::Gdk::Keysyms{ Up }) {
      $spin_button -> spin('step-forward', ($spin_button -> get_increments())[0]);
      return TRUE;
    }
    elsif ($event -> keyval == $Gtk2::Gdk::Keysyms{ Down }) {
      $spin_button -> spin('step-backward', ($spin_button -> get_increments())[0]);
      return TRUE;
    }

    return FALSE;
  });

  $spin_button -> {_focus_out_id} = 
      $spin_button -> signal_connect(focus_out_event => sub {
        my ($spin_button, undef) = @_;
        $cell -> _cell_editing_done($path, $spin_button -> get_value());
        # the spinbutton needs the focus-out event, don't eat it.
        return FALSE;
      });

  $spin_button -> show_all();

  # we don't want the editor widget to be the full height of the cell;
  # if the cell is taller than the spinbutton, the entry will grow, but
  # the spinner buttons won't.  tell the system that the cell is only
  # as tall as the spinbutton wants to be, and it will do the right thing.
  # this means we have to ask the spinbutton how big it wants to be; it
  # hasn't been mapped yet, so we'll have to trigger an actual size_request
  # calculation.
  my $requisition = $spin_button->size_request;
  $cell_area->y ($cell_area->y
                 + ($cell_area->height - $requisition->height) / 2);
  $cell_area->height ($requisition->height);

  return $spin_button;
}


###############################################################################

package main;

use Glib qw(TRUE FALSE);

my $window = Gtk2::Window -> new("toplevel");
$window -> set_title ("CellRendererSpinButton");
$window -> signal_connect (delete_event => sub { Gtk2 -> main_quit(); });

my $model = Gtk2::ListStore -> new(qw(Glib::Double));
my $view = Gtk2::TreeView -> new($model);

foreach (qw(12 12.1 12.12)) {
  $model -> set($model -> append(), 0 => $_);
}

sub cell_edited {
  my ($cell, $path, $new_value) = @_;
  
  $model -> set($model -> get_iter(Gtk2::TreePath -> new_from_string($path)),
                0 => $new_value);
}

my $renderer = Kaf::CellRendererSpinButton -> new();

$renderer -> set(mode => "editable",
                 min => 0,
                 max => 1000,
                 step => 2,
                 digits => 0);

$renderer -> signal_connect(edited => \&cell_edited);

my $column = Gtk2::TreeViewColumn -> new_with_attributes ("no digits",
                                                          $renderer,
                                                          value => 0);
$column->set_resizable (TRUE);

$view -> append_column($column);

#
# another, centered
#
$renderer = Kaf::CellRendererSpinButton -> new();

$renderer -> set(mode => "editable",
                 xalign => 0.5,
                 min => 0,
                 max => 1000,
                 step => 0.1,
                 digits => 1);

$renderer -> signal_connect(edited => \&cell_edited);

$column = Gtk2::TreeViewColumn -> new_with_attributes ("one digit",
                                                       $renderer,
                                                       value => 0);
$column->set_resizable (TRUE);

$view -> append_column($column);

#
# another, left-justified
#
$renderer = Kaf::CellRendererSpinButton -> new();

$renderer -> set(mode => "editable",
                 xalign => 0.0,
                 min => 0,
                 max => 1000,
                 step => 0.1,
                 digits => 2);

$renderer -> signal_connect(edited => \&cell_edited);

$column = Gtk2::TreeViewColumn -> new_with_attributes ("two digits",
                                                       $renderer,
                                                       value => 0);
$column->set_resizable (TRUE);

$view -> append_column($column);


$window -> add($view);
$window -> show_all();

Gtk2 -> main();

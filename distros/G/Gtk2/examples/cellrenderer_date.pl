#!/usr/bin/perl -w

#
# Copyright (C) 2003 by Torsten Schoenfeld
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

package Kaf::CellRendererDate;

use Glib::Object::Subclass
  "Gtk2::CellRenderer",
  signals => {
    edited => {
      flags => [qw(run-last)],
      param_types => [qw(Glib::String Glib::Scalar)],
    },
  },
  properties => [
    Glib::ParamSpec -> boolean("editable", "Editable", "Can I change that?", 0, [qw(readable writable)]),
    Glib::ParamSpec -> string("date", "Date", "What's the date again?", "", [qw(readable writable)]),
  ]
;

use constant x_padding => 2;
use constant y_padding => 3;

use constant arrow_width => 15;
use constant arrow_height => 15;

sub hide_popup {
  my ($cell) = @_;

  Gtk2 -> grab_remove($cell -> { _popup });
  $cell -> { _popup } -> hide();
}

sub get_today {
  my ($cell) = @_;

  my ($day, $month, $year) = (localtime())[3, 4, 5];
  $year += 1900;
  $month += 1;

  return ($year, $month, $day);
}

sub get_date {
  my ($cell) = @_;

  my $text = $cell -> get("date");
  my ($year, $month, $day) = $text
    ? split(/[\/-]/, $text)
    : $cell -> get_today();

  return ($year, $month, $day);
}

sub add_padding {
  my ($cell, $year, $month, $day) = @_;
  return ($year, sprintf("%02d", $month), sprintf("%02d", $day));
}

sub INIT_INSTANCE {
  my ($cell) = @_;

  my $popup = Gtk2::Window -> new ('popup');
  my $vbox = Gtk2::VBox -> new(0, 0);

  my $calendar = Gtk2::Calendar -> new();

  my $hbox = Gtk2::HBox -> new(0, 0);

  my $today = Gtk2::Button -> new('Today');
  my $none = Gtk2::Button -> new('None');

  $cell -> {_arrow} = Gtk2::Arrow -> new("down", "none");

  # We can't just provide the callbacks now because they might need access to
  # cell-specific variables.  And we can't just connect the signals in
  # START_EDITING because we'd be connecting many signal handlers to the same
  # widgets.
  $today -> signal_connect(clicked => sub {
    $cell -> { _today_clicked_callback } -> (@_)
      if (exists($cell -> { _today_clicked_callback }));
  });

  $none -> signal_connect(clicked => sub {
    $cell -> { _none_clicked_callback } -> (@_)
      if (exists($cell -> { _none_clicked_callback }));
  });

  $calendar -> signal_connect(day_selected_double_click => sub {
    $cell -> { _day_selected_double_click_callback } -> (@_)
      if (exists($cell -> { _day_selected_double_click_callback }));
  });

  $calendar -> signal_connect(month_changed => sub {
    $cell -> { _month_changed } -> (@_)
      if (exists($cell -> { _month_changed }));
  });

  $hbox -> pack_start($today, 1, 1, 0);
  $hbox -> pack_start($none, 1, 1, 0);

  $vbox -> pack_start($calendar, 1, 1, 0);
  $vbox -> pack_start($hbox, 0, 0, 0);

  # Find out if the click happended outside of our window.  If so, hide it.
  # Largely copied from Planner (the former MrProject).

  # Implement via Gtk2::get_event_widget?
  $popup -> signal_connect(button_press_event => sub {
    my ($popup, $event) = @_;

    if ($event -> button() == 1) {
      my ($x, $y) = ($event -> x_root(), $event -> y_root());
      my ($xoffset, $yoffset) = $popup -> window() -> get_root_origin();

      my $allocation = $popup -> allocation();

      my $x1 = $xoffset + 2 * $allocation -> x();
      my $y1 = $yoffset + 2 * $allocation -> y();
      my $x2 = $x1 + $allocation -> width();
      my $y2 = $y1 + $allocation -> height();

      unless ($x > $x1 && $x < $x2 && $y > $y1 && $y < $y2) {
        $cell -> hide_popup();
        return 1;
      }
    }

    return 0;
  });

  $popup -> add($vbox);

  $cell -> { _popup } = $popup;
  $cell -> { _calendar } = $calendar;
}

sub START_EDITING {
  my ($cell, $event, $view, $path, $background_area, $cell_area, $flags) = @_;

  my $popup = $cell -> { _popup };
  my $calendar = $cell -> { _calendar };

  # Specify the callbacks.  Will be called by the signal handlers set up in
  # INIT_INSTANCE.
  $cell -> { _today_clicked_callback } = sub {
    my ($button) = @_;
    my ($year, $month, $day) = $cell -> get_today();

    $cell -> signal_emit(edited => $path, join("-", $cell -> add_padding($year, $month, $day)));
    $cell -> hide_popup();
  };

  $cell -> { _none_clicked_callback } = sub {
    my ($button) = @_;

    $cell -> signal_emit(edited => $path, "");
    $cell -> hide_popup();
  };

  $cell -> { _day_selected_double_click_callback } = sub {
    my ($calendar) = @_;
    my ($year, $month, $day) = $calendar -> get_date();

    $cell -> signal_emit(edited => $path, join("-", $cell -> add_padding($year, ++$month, $day)));
    $cell -> hide_popup();
  };

  $cell -> { _month_changed } = sub {
    my ($calendar) = @_;

    my ($selected_year, $selected_month) = $calendar -> get_date();
    my ($current_year, $current_month, $current_day) = $cell -> get_today();

    if ($selected_year == $current_year &&
        ++$selected_month == $current_month) {
      $calendar -> mark_day($current_day);
    }
    else {
      $calendar -> unmark_day($current_day);
    }
  };

  my ($year, $month, $day) = $cell -> get_date();

  $calendar -> select_month($month - 1, $year);
  $calendar -> select_day($day);

  # Figure out where to put the popup - i.e., don't put it offscreen,
  # as it's not movable (by the user).

  $popup -> get_child -> show_all();  # all but $popup itself
  $popup -> realize;
  my ($requisition) = $popup->size_request;
  my ($popup_width, $popup_height) = ($requisition->width, $requisition->height);

  my $screen_height = $popup->get_screen->get_height;

  my ($x_origin, $y_origin) =  $view -> get_bin_window() -> get_origin();

  my $popup_x = $x_origin + $cell_area->x + $cell_area->width - $popup_width;
  if ($popup_x < 0) {
    $popup_x = 0;
  }

  my $popup_y = $y_origin + $cell_area->y + $cell_area->height;
  if ($popup_y + $popup_height > $screen_height) {
    $popup_y = $y_origin + $cell_area->y - $popup_height;
  }

  $popup -> move($popup_x, $popup_y);
  $popup -> show();

  # Grab the focus and the pointer.
  Gtk2 -> grab_add($popup);
  $popup -> grab_focus();

  Gtk2::Gdk -> pointer_grab($popup -> window(),
                            1,
                            [qw(button-press-mask
                                button-release-mask
                                pointer-motion-mask)],
                            undef,
                            undef,
                            0);

  return;
}

sub get_date_string {
  my $cell = shift;
  return $cell->get ('date');
}

sub calc_size {
  my ($cell, $layout) = @_;
  my ($width, $height) = $layout -> get_pixel_size();

  return (0,
          0,
          $width + x_padding * 2 + arrow_width,
          $height + y_padding * 2);
}

sub GET_SIZE {
  my ($cell, $widget, $cell_area) = @_;

  my $layout = $cell -> get_layout($widget);
  $layout -> set_text($cell -> get_date_string());

  return $cell -> calc_size($layout);
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
  $layout -> set_text($cell -> get_date_string());

  my ($x_offset, $y_offset, $width, $height) = $cell -> calc_size($layout);

  $widget -> get_style -> paint_layout($window,
                                       $state,
                                       1,
                                       $cell_area,
                                       $widget,
                                       "cellrenderertext",
                                       $cell_area -> x() + $x_offset + x_padding,
                                       $cell_area -> y() + $y_offset + y_padding,
                                       $layout);

  $widget -> get_style -> paint_arrow ($window,
                                       $widget->state,
                                       'none',
                                       $cell_area,
                                       $cell -> { _arrow },
                                       "",
                                       "down",
                                       1,
                                       $cell_area -> x + $cell_area -> width - arrow_width,
                                       $cell_area -> y + $cell_area -> height - arrow_height - 2,
                                       arrow_width - 3,
                                       arrow_height);
}


###############################################################################

package main;

my $window = Gtk2::Window -> new("toplevel");
$window -> set_title ("CellRendererDate");
$window -> signal_connect (delete_event => sub { Gtk2 -> main_quit(); });

my $model = Gtk2::ListStore -> new(qw(Glib::String));
my $view = Gtk2::TreeView -> new($model);

foreach (qw(2003-10-1 2003-10-2 2003-10-3)) {
  $model -> set($model -> append(), 0 => $_);
}

my $renderer = Kaf::CellRendererDate -> new();
$renderer -> set(mode => "editable");

$renderer -> signal_connect(edited => sub {
  my ($cell, $path, $new_date) = @_;

  $model -> set($model -> get_iter(Gtk2::TreePath -> new_from_string($path)),
                0 => $new_date);
});

my $column = Gtk2::TreeViewColumn -> new_with_attributes ("Date",
                                                          $renderer,
                                                          date => 0);

$view -> append_column($column);

$window -> add($view);
$window -> show_all();

Gtk2 -> main();

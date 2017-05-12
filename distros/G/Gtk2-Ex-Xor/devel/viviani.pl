#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::SyncCall;
use Math::Complex;

# uncomment this to run the ### lines
#use Smart::Comments;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my ($x, $y);
my $area = Gtk2::DrawingArea->new;
$area->set_size_request (350, 300);
#$area->modify_bg ('normal', Gtk2::Gdk::Color->parse ('black'));
$vbox->pack_start ($area, 1,1,0);

my $hbox = Gtk2::HBox->new;
$vbox->pack_start ($hbox, 0,0,0);

{
  my $button = Gtk2::Button->new_from_stock ('gtk-quit');
  $hbox->pack_end ($button, 0,0,0);
  $button->signal_connect
    (clicked => sub { $toplevel->destroy })
}

$area->add_events (['pointer-motion-mask']);
$area->signal_connect (motion_notify_event => sub {
                         my ($area, $event) = @_;
                         $x = $event->x;
                         $y = $event->y;
                         Gtk2::Ex::SyncCall->sync ($area, \&sync_call_handler);
                         return Gtk2::EVENT_PROPAGATE;
                       });
sub sync_call_handler {
  $area->queue_draw;
}
$area->signal_connect (expose_event => sub {
                         my ($area, $event) = @_;
                         if (! defined $x) {
                           (undef, $x, $y) = $area->window->get_pointer;
                         }
                         draw ($area);
                         return Gtk2::EVENT_PROPAGATE;
                       });

sub draw {
  my ($area) = @_;
  my $gc = $area->get_style->fg_gc($area->state);
  my $win = $area->window;

  my $left_gc = ($area->{'left_gc'} ||= do {
    my $color = Gtk2::Gdk::Color->parse ('red');
    my $colormap = $area->get_colormap;
    $colormap->alloc_color ($color, 0, 1);
    my $gc = Gtk2::GC->get ($win->get_depth,
                            $colormap,
                            { foreground => $color });
    $gc->{'foreground'} = $color;
    $gc
  });

  my $right_gc = ($area->{'right_gc'} ||= do {
    my $color = Gtk2::Gdk::Color->parse ('sea green');
    my $colormap = $area->get_colormap;
    $colormap->alloc_color ($color, 0, 1);
    my $gc = Gtk2::GC->get ($win->get_depth,
                            $colormap,
                            { foreground => $color });
    $gc->{'foreground'} = $color;
    $gc
    });

  my $vert_gc = ($area->{'vert_gc'} ||= do {
    my $color = Gtk2::Gdk::Color->parse ('blue');
    my $colormap = $area->get_colormap;
    $colormap->alloc_color ($color, 0, 1);
    my $gc = Gtk2::GC->get ($win->get_depth,
                            $colormap,
                            { foreground => $color });
    $gc->{'foreground'} = $color;
    $gc
    });

  my $screen = $area->get_screen;
  my $aspect = $screen->get_height_mm / $screen->get_height
    * $screen->get_width / $screen->get_width_mm;

  my ($wx, $wy, $width, $height) = $area->allocation->values;
  $width *= 0.9;
  $height *= 0.9;

  my $top_y = $wy + int ($height * 0.1);
  my $bottom_y = $wy + int ($height * 0.8);
  my $side = int (($bottom_y - $top_y)
                  / sin(pi/3));

  my $top_x = $wx + int ($width / 2);
  my $left_x = $top_x - int ($side / 2 * $aspect);
  my $right_x = $left_x + int ($side * $aspect);

  $win->draw_lines ($gc,
                    $top_x, $top_y,
                    $left_x, $bottom_y,
                    $right_x, $bottom_y,
                    $top_x, $top_y);

  ### at: $x, $y
  if ($x >= $wx && $x < $wx + $width
      && $y >= $wy && $y < $wy + $height) {
    my $mid_y = int (($top_y + $bottom_y) / 2);

    my $dy = $y - $top_y;
    my $f = $dy / ($bottom_y - $top_y) *  ($side / 2);
    my $left_pf = $f - ($top_x - $x);
    my $left_len = $left_pf * sin(pi/3);
    my $lix = $x - $left_len * cos(pi/6);
    my $liy = $y - $left_len * sin(pi/6);

    my $right_pf = $f + ($top_x - $x);
    my $right_len = $right_pf * sin(pi/3);
    my $rix = $x + $right_len * cos(pi/6) * $aspect;
    my $riy = $y - $right_len * sin(pi/6) * $aspect;

    my $left_mid_x = int ($top_x - $side / 4 * $aspect);
    my $right_mid_x = int ($left_mid_x + $side / 2 * $aspect);
    $win->draw_segments ($vert_gc, $x, $y, $x, $bottom_y);
    $win->draw_segments ($left_gc, $x, $y, $lix, $liy);
    $win->draw_segments ($right_gc, $x, $y, $rix, $riy);

    my $show_x = $wx + $width * 0.95;
    my $vert_len = $bottom_y - $y;
    my $pos = $bottom_y;
    $pos -= $vert_len;
    $win->draw_rectangle ($vert_gc, 1,
                          $show_x, $pos,
                          4, abs($vert_len));
    $pos -= $left_len;
    $win->draw_rectangle ($left_gc, 1,
                          $show_x, $pos,
                          4, abs($left_len));
    $pos -= $right_len;
    $win->draw_rectangle ($right_gc, 1,
                          $show_x, $pos,
                          4, abs($right_len));
  }
}

# sub draw_xor {
# }


$toplevel->show_all;
Gtk2->main;
exit 0;

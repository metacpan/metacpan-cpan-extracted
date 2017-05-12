#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::CrossHair;

require Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 42;

my $want_version = 22;
is ($Gtk2::Ex::CrossHair::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::CrossHair->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::CrossHair->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::CrossHair->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}
{
  my $cross = Gtk2::Ex::CrossHair->new;
  is ($cross->VERSION, $want_version, 'VERSION object method');
  ok (eval { $cross->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $cross->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

# return an arrayref
sub leftover_fields {
  my ($widget) = @_;
  my @leftover = grep /Gtk2::Ex::CrossHair/, keys %$widget;

  #   if (my $connected = MyTestHelpers::any_signal_connections ($widget)) {
  #     push @leftover, "signal $connected";
  #   }

  if (@leftover) {
    my %leftover;
    @leftover{@leftover} = @{$widget}{@leftover}; # hash slice
    diag "leftover fields: ", keys %leftover;
  }
  return \@leftover;
}

sub show_wait {
  my ($widget) = @_;
  my ($t_id, $s_id);
  $t_id = Glib::Timeout->add (10_000, # 10 seconds
                              sub {
                                diag "Timeout waiting for map event";
                                exit 1;
                              });
  $s_id = $widget->signal_connect (map_event => sub {
                                     Gtk2->main_quit;
                                     return 0; # propagate event
                                   });
  $widget->show;
  Gtk2->main;
  $widget->signal_handler_disconnect ($s_id);
  Glib::Source->remove ($t_id);
}


#-----------------------------------------------------------------------------

require Gtk2;
MyTestHelpers::glib_gtk_versions();

# setting 'widget' notifies 'widgets' too
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $cross = Gtk2::Ex::CrossHair->new;

  my $seen_widget = 0;
  my $seen_widgets = 0;
  $cross->signal_connect ('notify::widget'  => sub { $seen_widget++; });
  $cross->signal_connect ('notify::widgets' => sub { $seen_widgets++; });

  $cross->set (widget => $widget);
  is ($seen_widget,  1, 'notify widget');
  is ($seen_widgets, 1, 'notify widgets');
  $widget->destroy;
}

# setting 'widgets' notifies 'widget' too
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $cross = Gtk2::Ex::CrossHair->new;

  my $seen_widget = 0;
  my $seen_widgets = 0;
  $cross->signal_connect ('notify::widget'  => sub { $seen_widget++; });
  $cross->signal_connect ('notify::widgets' => sub { $seen_widgets++; });

  $cross->set (widgets => [$widget]);
  is ($seen_widget,  1, 'notify widget');
  is ($seen_widgets, 1, 'notify widgets');
  $widget->destroy;
}


# destroyed when weakened empty
{
  my $cross = Gtk2::Ex::CrossHair->new;
  my $weak_cross = $cross;
  require Scalar::Util;
  Scalar::Util::weaken ($weak_cross);
  undef $cross;
  is ($weak_cross, undef, 'weaken empty - destroyed');
  if (defined &explain) { diag explain($weak_cross); }
  if ($weak_cross) { MyTestHelpers::findrefs ($weak_cross); }
}

# destroyed when weakened on unrealized
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $cross = Gtk2::Ex::CrossHair->new (widget => $widget);
  my $weak_cross = $cross;
  require Scalar::Util;
  Scalar::Util::weaken ($weak_cross);
  undef $cross;
  MyTestHelpers::main_iterations();
  is ($weak_cross, undef, 'weaken unrealized - destroyed');
  if (defined &explain) {
    diag explain($widget);
    diag explain($weak_cross);
  }
  if ($weak_cross) {
    MyTestHelpers::findrefs ($weak_cross);
  }
  is_deeply (leftover_fields($widget), [],
             'weaken unrealized - no CrossHair data left behind');
  $widget->destroy;
}

# destroyed when weakened on realized
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;
  my $cross = Gtk2::Ex::CrossHair->new (widget => $widget);
  my $weak_cross = $cross;
  Scalar::Util::weaken ($weak_cross);
  $cross = undef;
  is ($weak_cross, undef, 'weaken realized - destroyed');
  is_deeply (leftover_fields($widget), [],
             'weaken realized - no CrossHair data left behind');
  $widget->destroy;
}

# destroyed when weakened on active
SKIP: {
  Gtk2::Gdk::Display->can('warp_pointer')
      or skip 'no display->warp_pointer(), per Gtk before 2.8', 3;

  my $widget = Gtk2::Window->new ('toplevel');
  $widget->set_size_request (100, 100);
  show_wait ($widget);

  # temporary warp to have mouse pointer within $widget
  my $display = $widget->get_display;
  my ($screen,$x,$y) = $display->get_pointer;
  my ($widget_x,$widget_y) = $widget->window->get_origin;
  $display->warp_pointer($widget->get_screen,$widget_x+50,$widget_y+50);

  is_deeply (leftover_fields($widget), [],
             'weaken active - initially no CrossHair data');

  my $cross = Gtk2::Ex::CrossHair->new (widget => $widget);
  $cross->start;
  # sync and iterate to make the cross draw and use its gc
  $display->sync;
  MyTestHelpers::main_iterations();

  my $weak_cross = $cross;
  Scalar::Util::weaken ($weak_cross);
  $cross = undef;
  MyTestHelpers::main_iterations();
  is ($weak_cross, undef, 'weaken active - destroyed');
  if ($weak_cross) {
    if (defined &explain) { diag explain($weak_cross); }
    MyTestHelpers::findrefs ($weak_cross);
  }
  is_deeply (leftover_fields($widget), [],
             'weaken active - no CrossHair data left behind');

  $widget->destroy;
  $display->warp_pointer($screen,$x,$y);
}

# start() emits "notify::active"
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;
  my $cross = Gtk2::Ex::CrossHair->new (widget => $widget);
  my $seen_notify = 0;
  $cross->signal_connect ('notify::active' => sub { $seen_notify = 1; });
  $cross->start;
  is ($seen_notify, 1, 'start() emits notify::active');
  $widget->destroy;
}

# end() emits "notify::active"
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;
  my $cross = Gtk2::Ex::CrossHair->new (widget => $widget);
  $cross->start;
  my $seen_notify = 0;
  $cross->signal_connect ('notify::active' => sub { $seen_notify = 1; });
  $cross->end;
  is ($seen_notify, 1, 'end() emits notify::active');
    $widget->destroy;
  }

# leftovers on changing widget, and switching to a widget without a common
# ancestor with the previous
SKIP: {
  Gtk2::Gdk::Display->can('warp_pointer')
      or skip 'no display->warp_pointer(), per Gtk before 2.8', 2;

  my $widget = Gtk2::Window->new ('toplevel');
  my $widget2 = Gtk2::Window->new ('toplevel');
  $widget->set_size_request (100, 100);
  show_wait ($widget);
  show_wait ($widget2);

  # temporary warp to have mouse pointer within $widget
  my $display = $widget->get_display;
  my ($screen,$x,$y) = $display->get_pointer;
  my ($widget_x,$widget_y) = $widget->window->get_origin;
  $display->warp_pointer($widget->get_screen,$widget_x+50,$widget_y+50);

  my $cross = Gtk2::Ex::CrossHair->new (widget => $widget);
  $cross->start;
  # sync and iterate to make the cross draw and use its gc
  $display->sync;
  MyTestHelpers::main_iterations();

  $cross->set (widget => $widget2);
  ($widget_x,$widget_y) = $widget2->window->get_origin;
  $display->warp_pointer($widget2->get_screen,$widget_x+50,$widget_y+50);
  $display->sync;
  MyTestHelpers::main_iterations();

  # if (defined &explain) {
  #   diag explain($widget);
  # }
  is_deeply (leftover_fields($widget), [],
             'change widget - no CrossHair data left behind');

  $cross->set (widgets => []);
  is_deeply (leftover_fields($widget2), [],
             'change to no widgets - no CrossHair data left behind');

  $widget->destroy;
  $widget2->destroy;
  $display->warp_pointer($screen,$x,$y);
}

#------------------------------------------------------------------------------
# foreground properties

# return true if two Glib::Boxed objects $b1 and $b2 point to the same
# underlying C object
{
  my $n = 0;
  sub color_parts {
    my ($color) = @_;
    if (Scalar::Util::blessed($color)) {
      return $color->red .','. $color->blue .','. $color->green;
    } else {
      return 'not-a-color-object'.$n++;
    }
  }
}

{
  my $crosshair = Gtk2::Ex::CrossHair->new;
  my %notifies;
  $crosshair->signal_connect (notify => sub {
                            my ($crosshair, $pspec) = @_;
                            my $pname = $pspec->get_name;
                            $notifies{$pname} = 1;
                          });

  # claimed defaults
  is ($crosshair->get('foreground'), undef, 'foreground - default undef');
  is ($crosshair->get('foreground-name'), undef, 'foreground-name - default undef');
  is ($crosshair->get('foreground-gdk'), undef,
      'foreground-gdk - default undef');

  # string
  %notifies = ();
  $crosshair->set (foreground => 'white');
  is ($crosshair->get('foreground'), 'white');
  is ($crosshair->get('foreground-name'), 'white');
  is (color_parts ($crosshair->get('foreground-gdk')),
      color_parts (Gtk2::Gdk::Color->new(65535,65535,65535)));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground string notifies');

  # object
  my $red = Gtk2::Gdk::Color->new (65535,0,0);
  %notifies = ();
  $crosshair->set (foreground => $red);
  is (color_parts ($crosshair->get('foreground')),
      color_parts ($red));
  is ($crosshair->get('foreground-name'), '#ffff00000000');
  # boxed objects not equal
  is (color_parts ($crosshair->get('foreground-gdk')),
      color_parts ($red));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground object notifies');

  # foreground-name string
  %notifies = ();
  $crosshair->set (foreground_name => 'black');
  is ($crosshair->get('foreground'), 'black');
  is ($crosshair->get('foreground-name'), 'black');
  is (color_parts ($crosshair->get('foreground-gdk')),
      color_parts (Gtk2::Gdk::Color->new (0,0,0)));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground-name notifies');

  # foreground-gdk object
  my $green = Gtk2::Gdk::Color->new (0,65535,0);
  %notifies = ();
  $crosshair->set (foreground_gdk => $green);
  is (color_parts ($crosshair->get('foreground')),
      color_parts ($green));
  is ($crosshair->get('foreground-name'), '#0000ffff0000');
  # boxed objects not equal
  is (color_parts ($crosshair->get('foreground-gdk')),
      color_parts ($green));
  is_deeply (\%notifies, {foreground=>1,foreground_name=>1,foreground_gdk=>1},
             'foreground-gdk notifies');
}

exit 0;

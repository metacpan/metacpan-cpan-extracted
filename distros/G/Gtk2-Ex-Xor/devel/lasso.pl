#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use FindBin;
use Gtk2 '-init';
use Gtk2::Ex::Lasso;
use Data::Dumper;

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new;
$hbox->pack_start ($vbox, 0, 0, 0);

my $area_width = 500;
my $area_height = 300;

my $layout = Gtk2::Layout->new;
$layout->set_size_request ($area_width+20, $area_height+20);
$hbox->pack_start ($layout, 1, 1, 0);

my $area = Gtk2::DrawingArea->new;
$area->set_size_request ($area_width, $area_height);
$area->modify_fg ('normal', Gtk2::Gdk::Color->parse ('white'));
$area->modify_bg ('normal', Gtk2::Gdk::Color->parse ('black'));
$layout->put ($area, 0, 0);

my $area2 = Gtk2::DrawingArea->new;
$area2->set_size_request (100, 100);
$area2->modify_fg ('normal', Gtk2::Gdk::Color->parse ('green'));
$area2->modify_bg ('normal', Gtk2::Gdk::Color->parse ('blue'));
$layout->put ($area2, 0, $area_height + 10);

my $lasso = Gtk2::Ex::Lasso->new
  (widget => $area,
   # cursor => 'hand1'
   foreground => Gtk2::Gdk::Color->new(65535/2,0,0,0),
  );
$area->grab_focus;
$area->add_events(['button-press-mask']);
$area->signal_connect (button_press_event =>
                       sub {
                         my ($area, $event) = @_;
                         print "$progname: start button\n";
                         $lasso->start ($event);
                         return 0; # Gtk2::EVENT_PROPAGATE
                       });
$area2->add_events(['button-press-mask']);
$area2->signal_connect (button_press_event =>
                        sub {
                          my ($area2, $event) = @_;
                          print "$progname: start button in area2\n";
                          $lasso->start ($event);
                          return 0; # Gtk2::EVENT_PROPAGATE
                        });

$area->signal_connect (button_release_event =>
                       sub {
                         my ($area, $event) = @_;
                         print "$progname: area1 button release\n";
                         return 0; # Gtk2::EVENT_PROPAGATE
                       });
$area2->signal_connect (button_release_event =>
                        sub {
                          my ($area2, $event) = @_;
                          print "$progname: area2 button release\n";
                          return 0; # Gtk2::EVENT_PROPAGATE
                        });

$lasso->signal_connect (moved =>
                        sub {
                          print "$progname: moved ", join(' ',@_), "\n";
                        });
$lasso->signal_connect (aborted =>
                        sub {
                          print "$progname: aborted ", join(' ',@_), "\n";
                        });
$lasso->signal_connect (ended =>
                        sub {
                          print "$progname: ended ", join(' ',@_), "\n";
                        });

Gtk2->key_snooper_install
  (sub {
     my ($widget, $event) = @_;
     $event->type eq 'key-press' || return 0; # Gtk2::EVENT_PROPAGATE

     if ($event->keyval == Gtk2::Gdk->keyval_from_name('s')) {
       print "$progname: start key\n";
       $lasso->start ($event);
       return 1; # Gtk2::EVENT_STOP
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('e')) {
       print "$progname: end\n";
       $lasso->end;
       return 1; # Gtk2::EVENT_STOP
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('r')) {
       print "$progname: redraw\n";
       $area->queue_draw;
       return 1; # Gtk2::EVENT_STOP
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('2')) {
       print "$progname: toggle area2\n";
       $lasso->set ('widget',
                    ($lasso->get ('widget') == $area ? $area2 : $area));
       return 1; # Gtk2::EVENT_STOP
     }
     return 0; # Gtk2::EVENT_PROPAGATE
   });

{
  my $button = Gtk2::CheckButton->new_with_label ('Active');
  $vbox->pack_start ($button, 0,0,0);
  $lasso->signal_connect ('notify::active' => sub {
                            my $active = $lasso->get ('active');
                            print "$progname: lasso notify active $active\n";
                            $button->set_active ($active);
                          });
  $button->signal_connect
    (toggled => sub {
       my $active = $button->get_active;
       print "$progname: hint toggled $active\n";
       $lasso->set (active => $active);
     });
}
{
  my $button = Gtk2::Button->new_with_label ('Start');
  $button->signal_connect (clicked => sub { $lasso->start; });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('End');
  $button->signal_connect (clicked => sub { $lasso->end; });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Abort');
  $button->signal_connect (clicked => sub { $lasso->abort; });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Swap');
  $button->signal_connect (clicked => sub { $lasso->swap_corners; });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Redraw');
  $button->signal_connect (clicked => sub { $area->queue_draw; });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delayed Unmap');
  $button->set_tooltip_markup
    ("Click to unmap the DrawingArea widget after a delay of 2 seconds (use this to exercise grab_broken handling)");
  $button->signal_connect (clicked => sub {
                             Glib::Timeout->add (2000, # milliseconds
                                                 sub {
                                                   $area->unmap;
                                                   return 0; # Glib::SOURCE_REMOVE
                                                 });
                           });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $button = Gtk2::Button->new_with_label ('Delayed Iconify');
  $button->set_tooltip_markup
    ("Click to iconify the program after a delay of 2 seconds (use this to exercise grab_broken handling)");
  $button->signal_connect (clicked => sub {
                             Glib::Timeout->add (2000, # milliseconds
                                                 sub {
                                                   $toplevel->iconify;
                                                   return 0; # Glib::SOURCE_REMOVE
                                                 });
                           });
  $vbox->pack_start ($button, 0, 0, 0);
}
{
  my $combobox = Gtk2::ComboBox->new_text;
  $vbox->pack_start ($combobox, 0,0,0);
  $combobox->append_text ('hand1');
  $combobox->append_text ('invisible');
  $combobox->append_text ('undef');
  $combobox->append_text ('boat');
  $combobox->append_text ('umbrella');
  $combobox->append_text ('cross');
  $combobox->set_active (0);

  $combobox->signal_connect
    (changed => sub {
       my $type = $combobox->get_active_text;
       if ($type eq 'undef') { $type = undef; }
       $lasso->set (cursor => $type);
     });
  $lasso->signal_connect ('notify::cursor' => sub {
                            my $cursor = $lasso->get ('cursor');
                            print "$progname: lasso cursor '$cursor'\n";
                          });
}
{
  my $timer_id;
  my $idx = 0;
  my @widths = (500, 450, 400, 450);
  my $button = Gtk2::CheckButton->new_with_label ('Resizing');
  $button->set_tooltip_markup
    ("Check this to resize the DrawingArea under a timer, to test lasso recalc when some of it goes outside the new size");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print "$progname: resizing start\n";
                                 Glib::Timeout->add (1000, \&resizing_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print "$progname: resizing stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub resizing_timer {
    $idx++;
    if ($idx >= @widths) {
      $idx = 0;
    }
    my $width = $widths[$idx];
    print "$progname: resize to $width,$area_height\n";
    $area->set_size_request ($width, $area_height);
    return 1; # Glib::SOURCE_CONTINUE
  }
}
{
  my $timer_id;
  my $idx = 0;
  my @x = (0, 50, 100, 50);
  my $button = Gtk2::CheckButton->new_with_label ('Repositioning');
  $button->set_tooltip_markup
    ("Check this to resize the DrawingArea under a timer, to test lasso recalc when some of it goes outside the new size");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print "$progname: repositioning start\n";
                                 Glib::Timeout->add (1000, \&repositioning_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print "$progname: repositioning stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub repositioning_timer {
    $idx++;
    if ($idx >= @x) {
      $idx = 0;
    }
    my $x = $x[$idx];
    print "$progname: reposition to $x,0\n";
    $layout->move ($area, $x, 0);
    return 1; # Glib::SOURCE_CONTINUE
  }
}
{
  my $timer_id;
  my $idx = 0;
  my @cursors = ('hand1', 'fleur', 'boat', 'umbrella');
  my $button = Gtk2::CheckButton->new_with_label ('Cursor Changing');
  $button->set_tooltip_markup
    ("Check this to update the cursor in the lasso, to see the display updates (when the lasso is active)");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print "$progname: cursor changing start\n";
                                 Glib::Timeout->add (1000, \&cursor_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print "$progname: cursor changing stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub cursor_timer {
    $idx++;
    if ($idx >= @cursors) {
      $idx = 0;
    }
    $lasso->set(cursor => $cursors[$idx]);
    return 1; # Glib::SOURCE_CONTINUE
  }
}
{
  my $timer_id;
  my $idx = 0;
  my @foregrounds = ('red', 'black', 'green', 'blue', 'grey');
  my $button = Gtk2::CheckButton->new_with_label ('Foreground Changing');
  $button->set_tooltip_markup
    ("Check this to update the foreground colour in the lasso");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print "$progname: foreground changing start\n";
                                 Glib::Timeout->add (2000, \&foreground_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print "$progname: foreground changing stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub foreground_timer {
    $idx++;
    if ($idx >= @foregrounds) { $idx = 0; }
    $lasso->set(foreground => $foregrounds[$idx]);
    return 1; # Glib::SOURCE_CONTINUE
  }
}
{
  my $timer_id;
  my $idx = 0;
  my @backgrounds = ('red', 'black', 'green', 'blue', 'grey');
  my $button = Gtk2::CheckButton->new_with_label ('Background Changing');
  $button->set_tooltip_markup
    ("Check this to update the background in the widget, to see the lasso gc follow it");
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('toggled' => sub {
                             if ($button->get_active) {
                               $timer_id ||= do {
                                 print "$progname: background changing start\n";
                                 Glib::Timeout->add (2000, \&background_timer);
                               };
                             } else {
                               if ($timer_id) {
                                 print "$progname: background changing stop\n";
                                 Glib::Source->remove ($timer_id);
                                 $timer_id = undef;
                               }
                             }
                           });
  sub background_timer {
    $idx++;
    if ($idx >= @backgrounds) {
      $idx = 0;
    }
    my $color = Gtk2::Gdk::Color->parse ($backgrounds[$idx]);
    $area->modify_bg ('normal', $color);
    return 1; # Glib::SOURCE_CONTINUE
  }
}

$toplevel->show_all;
Gtk2->main;


__END__


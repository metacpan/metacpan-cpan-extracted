#!/usr/bin/perl -w

# Copyright 2008, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Dragger.
#
# Gtk2-Ex-Dragger is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dragger is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dragger.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use FindBin;
use List::Util qw(min max);
use Gtk2 '-init';
use Gtk2::Ex::Dragger;
use Data::Dumper;

# uncomment this to run the ### lines
use Smart::Comments;

my $progname = $FindBin::Script;

# Gtk2::Gdk::Window->set_debug_updates (1);

Gtk2::Rc->parse_string (<<'HERE');
style "My_style"
  {
    fg[ACTIVE]        = { 1.0, 1.0, 1.0 }
    fg[NORMAL]        = { 1.0, 1.0, 1.0 }
    fg[PRELIGHT]      = { 1.0, 1.0, 1.0 }
    fg[SELECTED]      = { 1.0, 1.0, 1.0 }
    fg[INSENSITIVE]   = { 1.0, 1.0, 1.0 }
    text[ACTIVE]      = { 1.0, 1.0, 1.0 }
    text[NORMAL]      = { 1.0, 1.0, 1.0 }
    text[PRELIGHT]    = { 1.0, 1.0, 1.0 }
    text[SELECTED]    = { 1.0, 1.0, 1.0 }
    text[INSENSITIVE] = { 1.0, 1.0, 1.0 }
    bg[ACTIVE]        = { 0, 0, 0 }
    bg[NORMAL]        = { 0, 0, 0 }
    bg[PRELIGHT]      = { 0, 0, 0 }
    bg[SELECTED]      = { 0, 0, 0 }
    bg[INSENSITIVE]   = { 0, 0, 0 }
    base[ACTIVE]      = { 0, 0, 0 }
    base[NORMAL]      = { 0, 0, 0 }
    base[PRELIGHT]    = { 0, 0, 0 }
    base[SELECTED]    = { 0, 0, 0 }
    base[INSENSITIVE] = { 0, 0, 0 }
  }
widget "*.GtkDrawingArea" style "My_style"
HERE

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new;
$hbox->pack_start ($vbox, 0,0,0);

my $table = Gtk2::Table->new (2, 2, 0);
$hbox->pack_start ($table, 0,0,0);

my $area = Gtk2::DrawingArea->new;
$area->set_size_request (200, 200);
$table->attach ($area, 0,1, 0,1,
                ['expand','shrink','fill'],['expand','shrink','fill'], 0,0);
$area->set_flags ('can-focus');
$area->grab_focus;
$area->add_events (['button-press-mask',
                    'button-motion-mask',
                    'button-release-mask']);
# $area->signal_connect (motion_notify_event => sub {
#                          print "$progname: motion_notify\n";
#                          return Gtk2::EVENT_PROPAGATE;
#                        });

my $vadj = Gtk2::Adjustment->new (100, 0, 300, 1, 10, 100);
$vadj->signal_connect
  (notify => sub {
     my ($vadj, $pspec) = @_;
     my $pname = $pspec->get_name;
     print "$progname: vadj notify \"$pname\", value now ",$vadj->value,"\n";
   });
$vadj->signal_connect
  (value_changed => sub {
     my ($vadj, $pspec) = @_;
     print "$progname: vadj value-changed, value now ",$vadj->value,"\n";
   });
my $vscroll = Gtk2::VScrollBar->new ($vadj);
$table->attach ($vscroll, 1,2, 0,1,
                [],['expand','shrink','fill'], 0,0);

my $hadj = Gtk2::Adjustment->new (100, 0, 300, 1, 10, 100);
my $hscroll = Gtk2::HScrollBar->new ($hadj);
$table->attach ($hscroll, 0,1, 1,2,
                ['expand','shrink','fill'],[], 0,0);

my $dragger;
my $confine = 0;
my $hinverted = 0;
my $vinverted = 0;
my $update_policy = 0;
sub make {
  $dragger = Gtk2::Ex::Dragger->new (widget        => $area,
                                     hadjustment   => $hadj,
                                     vadjustment   => $vadj,
                                     hinverted     => $hinverted,
                                     vinverted     => $vinverted,
                                     update_policy => $update_policy,
                                     confine       => $confine,
                                     cursor        => 'fleur');
  print "$progname ",($confine?"confined ":"unconfined "),
    ($hinverted?"hinv ":"hnorm "),
      ($vinverted?"vinv":"vnorm"),
        "policy $update_policy\n";
}
# make();

sub update {
  if (defined $dragger) {
    make ();
  }
}
{
  my $button = Gtk2::CheckButton->new_with_label ('Confine');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect (toggled => sub {
                             $confine = $button->get_active;
                             update();
                           });
}
{
  my $button = Gtk2::CheckButton->new_with_label ('H Inverted');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('notify::active' => sub {
                             $hinverted = $button->get_active;
                             update();
                           });
}
{
  my $button = Gtk2::CheckButton->new_with_label ('V Inverted');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect ('notify::active' => sub {
                             $vinverted = $button->get_active;
                             update();
                           });
}
# {
#   my $combobox = Gtk2::ComboBox->new_text;
#   $vbox->pack_start ($combobox, 0,0,0);
#   foreach my $policy ('default', 'continuous', 'discontinuous', 'delayed') {
#     $combobox->append_text ($policy);
#   }
#   $combobox->set_active (0);
#   $combobox->signal_connect
#     (changed => sub {
#        $update_policy = $combobox->get_active_text;
#        update();
#      });
# }
{
  require Gtk2::Ex::ComboBox::Enum;
  my $combobox = Gtk2::Ex::ComboBox::Enum->new
    (enum_type   => 'Gtk2::Ex::Dragger::UpdatePolicy',
     active_nick => Gtk2::Ex::Dragger->find_property('update-policy')->get_default_value);
  $vbox->pack_start ($combobox, 0,0,0);
  $combobox->signal_connect
    ('notify::active-nick' => sub {
       $update_policy = $combobox->get('active-nick');
       update();
     });
}
{
  my $button = Gtk2::CheckButton->new_with_label ('Hint Mask');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    (notify => sub {
       $area->unrealize;
       my $motion_mask = $button->get_active
         ? ['pointer-motion-hint-mask'] : [];
       my $new_mask = $area->get('events')
         - 'pointer-motion-hint-mask'
           + $motion_mask;
       $area->set(events => $new_mask);
       print "$progname: area widget events ",$area->get('events'),"\n";
       $area->show;
       $area->map;
       my ($width, $height) = $area->window->get_size;
       print "$progname: area ${width}x${height} window events ",$area->window->get_events,"\n";

       $update_policy = 'continuous';
       update();
     });
}
my $sleep = 0;
{
  my $button = Gtk2::CheckButton->new_with_label ('Sleep on Start');
  $vbox->pack_start ($button, 0,0,0);
  $button->signal_connect
    ('notify::active' => sub {
       $sleep = $button->get_active;
       print "$progname: setup sleep $sleep\n";
     });
}

{
  my $label = Gtk2::Label->new ('Keys:
Up,Down,Left,Right,
PgUp, PgDown');
  $vbox->pack_start ($label, 0,0,0);

  $area->signal_connect
    (key_press_event => sub {
       my ($area, $event) = @_;
       if ($event->keyval == Gtk2::Gdk->keyval_from_name('Page_Down')) {
         $vadj->set_value (min ($vadj->upper - $vadj->page_size,
                                $vadj->value + $vadj->page_increment));

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('Page_Up')) {
         $vadj->set_value (max ($vadj->lower,
                                $vadj->value - $vadj->page_increment));

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('Down')) {
         $vadj->set_value (min ($vadj->upper - $vadj->page_size,
                                $vadj->value + $vadj->step_increment));

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('Up')) {
         $vadj->set_value (max ($vadj->lower,
                                $vadj->value - $vadj->step_increment));


       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('Left')) {
         $hadj->set_value (min ($hadj->upper - $hadj->page_size,
                                $hadj->value + $hadj->step_increment));

       } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('Right')) {
         $hadj->set_value (max ($hadj->lower,
                                $hadj->value - $hadj->step_increment));

       }
       return 0; # propagate
     });
}

$area->add_events ('button-press-mask');
$area->signal_connect (button_press_event =>
                       sub {
                         my ($widget, $event) = @_;
                         print "$progname: start button press on $widget\n";
                         if ($sleep) {
                           print "$progname: sleep 1\n";
                           sleep 1;
                         }
                         make();
                         print "$progname: start now 1\n";
                         $dragger->start ($event);
                         return 0; # propagate
                       });

$toplevel->show_all;

### $dragger
### area events: $area->window->get_events.''
Gtk2->main;
exit 0;


__END__


=head1 BUGS

There's no C<notify> signal if the C<widget> property becomes C<undef> due
to weakening.

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
$toplevel->set_default_size (500, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $vbox = Gtk2::VBox->new;
$hbox->pack_start ($vbox, 0, 0, 0);

my $entry = Gtk2::Entry->new;
$hbox->pack_start ($entry, 1, 1, 0);

my $lasso = Gtk2::Ex::Lasso->new (widget => $entry);
$entry->signal_connect
  (key_press_event =>
   sub {
     my ($entry, $event, $userdata) = @_;
     if ($event->keyval == Gtk2::Gdk->keyval_from_name('s')) {
       print "$progname: start key\n";
       $lasso->start ($event);
       return 1; # don't propagate
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('e')) {
       print "$progname: end\n";
       $lasso->end;
       return 1; # don't propagate
     } elsif ($event->keyval == Gtk2::Gdk->keyval_from_name('r')) {
       print "$progname: redraw\n";
       $entry->queue_draw;
       return 1; # don't propagate
     }
     return 0; # propagate
   });
$entry->add_events(['button-press-mask']);
$entry->signal_connect (button_press_event =>
                       sub {
                         my ($entry, $event, $userdata) = @_;
                         print "$progname: start button\n";
                         $lasso->start ($event);
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
  $button->signal_connect (clicked => sub { $entry->queue_draw; });
  $vbox->pack_start ($button, 0, 0, 0);
}

{
  my $combobox = Gtk2::ComboBox->new_text;
  $vbox->pack_start ($combobox, 0,0,0);
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
}

$vbox->pack_start (Gtk2::Label->new(<<'HERE'),0,0,0);
Drag button 1 for lasso
Press: S - start lasso.
   E - end.
   R - redraw Entry.
HERE

$entry->grab_focus;
$toplevel->show_all;
Gtk2->main;
exit 0;

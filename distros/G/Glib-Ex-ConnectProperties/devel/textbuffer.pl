#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Gtk2 '-init';

# use lib 'devel/lib';

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (200, 300);
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0,0);
$toplevel->add ($vbox);

my $textbuf = Gtk2::TextBuffer->new;
$textbuf->signal_connect (notify => sub {
                            my ($textbuf, $pspec) = @_;
                            my $pname = $pspec->get_name;
                            print "textbuf \"notify\" $pname\n";
                          });
$textbuf->signal_connect ('changed' => sub {
                            print "textbuf \"changed\"\n";
                          });

my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
$vbox->add ($textview);

{
  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'text'],
       [$label, 'label']);
  $vbox->pack_start ($label, 0,0,0);
}
{
  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'text',read_signal=>'changed'],
       [$label, 'label']);
  $vbox->pack_start ($label, 0,0,0);
}
{
  my $label = Gtk2::Label->new;
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#char-count'],
       [$label, 'label']);
  $vbox->pack_start ($label, 0,0,0);
}
{
  my $checkbutton = Gtk2::CheckButton->new_with_label('empty');
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#empty'],
       [$checkbutton, 'active']);
  $vbox->pack_start ($checkbutton, 0,0,0);
}
{
  my $checkbutton = Gtk2::CheckButton->new_with_label('not-empty');
  Glib::Ex::ConnectProperties->new
      ([$textbuf, 'textbuffer#not-empty'],
       [$checkbutton, 'active']);
  $vbox->pack_start ($checkbutton, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;

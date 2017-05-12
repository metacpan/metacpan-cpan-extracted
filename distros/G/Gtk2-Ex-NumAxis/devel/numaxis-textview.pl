#!/usr/bin/perl -w

# Copyright 2008, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.


# This example adds draggability to a Gtk2::TextView widget with
# Control-Button1.  Plain Button1 is left as the text selection.
#
# You can use the keyboard to move the insertion point around during a drag,
# which has the effect of moving the scrolled position, generally first by a
# jump to put the insertion point on screen.
#
# The "confine" option on the dragger restricts mouse pointer movement to
# the actual scrollable range.  Whether you want that is mostly a matter of
# personal preference, but it's a pretty good way to know you've hit the
# scrollable limit.
#
# $heading_eventbox copes with a perversity of Gtk (version 2.12 at least).
# A no-window widget like Gtk2::Label in the heading area doesn't get expose
# events propagated to it from the heading window during scrolls.  That's
# something containers are normally meant to do, and if GtkTextView used
# some of the ordinary GtkContainer it'd get it for free.  But at any rate
# using a Gtk2::EventBox forces a subwindow and gives exposes (in that
# subwindow) to the label.
#

use 5.008;
use strict;
use warnings;
use FindBin;
use Gtk2 1.200 '-init';
use Gtk2::Ex::NumAxis;

my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });
$toplevel->set_default_size (300, 300);

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set (hscrollbar_policy => 'never',
                vscrollbar_policy => 'always');
$hbox->pack_start ($scrolled, 1,1,0);

my $axis = Gtk2::Ex::NumAxis->new
  (adjustment => $scrolled->get_vadjustment);
$hbox->pack_start ($axis, 0,0,0);

my $textbuf = Gtk2::TextBuffer->new;
{
  # textbuf contents from this file itself
  open (my $fh, '<', '/etc/passwd') or die $!;
  local $/ = undef; # slurp
  my $str = <$fh>;
  close $fh or die;
  $textbuf->set_text ($str);
}

my $textview = Gtk2::TextView->new;
$textview->set_buffer ($textbuf);
$scrolled->add ($textview);

# my $sizegroup = Gtk2::SizeGroup->new ('vertical');
# $sizegroup->add_widget ($textview);
# $sizegroup->add_widget ($axis);

$scrolled->get_vadjustment->signal_connect
  (notify => sub {
     my ($adj, $pspec) = @_;
     print "$progname: adjustment notify ",$pspec->get_name,"\n";
   });
$scrolled->get_vadjustment->signal_connect
  (changed => sub {
     my ($adj, $pspec) = @_;
     print "$progname: adjustment changed\n";
     print "  ",$adj->lower," ",$adj->upper," ",$adj->page_size,"\n";
   });
$scrolled->get_vadjustment->signal_connect
  (value_changed => sub {
     my ($adj, $pspec) = @_;
     print "$progname: adjustment value-changed\n";
   });

$toplevel->show_all;
Gtk2->main;
exit 0;

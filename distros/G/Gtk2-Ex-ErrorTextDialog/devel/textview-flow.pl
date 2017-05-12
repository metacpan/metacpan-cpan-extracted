#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_default_size (200, 100);
$toplevel->signal_connect (destroy => sub {
                             print "$progname: quit\n";
                             Gtk2->main_quit;
                           });

my $scrolled = Gtk2::ScrolledWindow->new;
$scrolled->set_policy ('automatic', 'always');
$toplevel->add ($scrolled);

my $textbuf = Gtk2::TextBuffer->new();
my $textview = Gtk2::TextView->new_with_buffer ($textbuf);
print "wrap ",$textview->get_wrap_mode,"\n";
print "just ", $textview->get_justification,"\n";
$textview->set_wrap_mode ('word');
$textview->set_justification ('fill');

$scrolled->add ($textview);

# $textbuf->insert ($textbuf->get_end_iter, (" ABC" x 100) ."\n\n");

my $group = Gtk2::SizeGroup->new ('horizontal');
foreach my $i (1 .. 10) {
  if ($i > 1) {
    # $textbuf->insert ($textbuf->get_end_iter, " x ");
  }
  my $button = Gtk2::Button->new_with_label ("button $i");
  $group->add_widget ($button);
  my $anchor = $textbuf->create_child_anchor ($textbuf->get_end_iter);
  $textview->add_child_at_anchor ($button, $anchor);
}
$textbuf->insert ($textbuf->get_end_iter, "\n");

$toplevel->show_all;
Gtk2->main;
exit 0;

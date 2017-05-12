#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Gtk2;
use Gtk2 1.220; # 1.240 for find_child_property()

use FindBin;
my $progname = $FindBin::Script;

my $vbox = Gtk2::VBox->new (0,0);
# pack_start() doesn't go through "add"
$vbox->signal_connect_after
  (add => sub {
     my ($vbox, $child) = @_;
     print "vbox add: $child\n";
   });
$vbox->signal_connect_after
  (remove => sub {
     my ($vbox, $child) = @_;
     print "vbox remove: $child\n";
   });

my $label = Gtk2::Label->new ('Hello');
$label->signal_connect_after
  (parent_set => sub {
     my ($label) = @_;
     print "label parent-set: ",$label->get_parent//'[undef]',"\n";
     if (my $parent =  $label->get_parent) {
       $parent->child_set_property($label,padding=>123);
     }
   });
$label->signal_connect
  (notify => sub {
     my ($label, $pspec) = @_;
     my $pname = $pspec->get_name;
     print "label notify: $pname = ",
       $label->get($pname)//'[undef]',"\n";
   });
$label->signal_connect
  (child_notify => sub {
     my ($label, $pspec) = @_;
     my $pname = $pspec->get_name;
     print "label child-notify: $pname = ",
       $label->get_parent->child_get_property($label,$pname)//'[undef]',"\n";
   });

# $vbox->add($label);
$vbox->pack_start($label,0,0,0);
print "now mnemonic-widget: ",$label->get('mnemonic-widget')//'[undef]',"\n";

print "destroy vbox\n";
$vbox->destroy;
exit 0;

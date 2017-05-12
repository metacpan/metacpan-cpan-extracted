#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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
use Gtk2::Ex::ErrorTextDialog;
use Gtk2 '-init';

my $dialog = Gtk2::Ex::ErrorTextDialog->new;
Gtk2::Ex::ErrorTextDialog::_message_dialog_set_text($dialog,'abc');

our $xx;
BEGIN {
  $xx = sub { 'foo' };
}
print "xx $xx\n";
require Scalar::Util;
Scalar::Util::weaken ($xx);
print "xx $xx\n";






# print "xx ",$Gtk2::Ex::ErrorTextDialog::xx,"\n";
# print "yy ",$Gtk2::Ex::ErrorTextDialog::yy,"\n";
# Scalar::Util::weaken ($Gtk2::Ex::ErrorTextDialog::xx);
# Scalar::Util::weaken ($Gtk2::Ex::ErrorTextDialog::yy);
# print "xx ",$Gtk2::Ex::ErrorTextDialog::xx,"\n";
# print "yy ",$Gtk2::Ex::ErrorTextDialog::yy,"\n";



# my $orig = $Gtk2::Ex::ErrorTextDialog::_message_dialog_set_text;
# print "orig $orig\n";

# print "now  ",$Gtk2::Ex::ErrorTextDialog::_message_dialog_set_text,"\n";
# Scalar::Util::weaken ($orig);
# print "orig $orig\n";

#   print_container_tree($dialog);
# sub print_container_tree {
#   my ($widget, $depth) = @_;
#   $depth ||= 0;
#   print ' 'x$depth,"$widget\n";
#   if ($widget->isa('Gtk2::Container')) {
#     foreach my $child ($widget->get_children) {
#       print_container_tree ($child, $depth + 1);
#     }
#   }
# }


exit 0;

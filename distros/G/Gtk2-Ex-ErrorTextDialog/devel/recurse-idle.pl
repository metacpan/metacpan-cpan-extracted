#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog;
use Gtk2::Ex::ErrorTextDialog::Handler;

use FindBin;
use lib::abs $FindBin::Bin;
my $progname = $FindBin::Script;

$SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;

my $add_message = \&Gtk2::Ex::ErrorTextDialog::add_message;
no warnings 'redefine';
*Gtk2::Ex::ErrorTextDialog::add_message = sub {
  print "$progname: wrapped add_message()\n";
  &$add_message(@_);
  die "$progname: inducing die in add_message";
  # warn "$progname: inducing this warning in add_message";
};

warn "$progname: look to your orb for the warning";

Gtk2->main;
exit 0;

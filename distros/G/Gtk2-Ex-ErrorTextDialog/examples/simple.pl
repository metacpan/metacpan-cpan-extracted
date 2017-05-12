#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

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


# Usage: ./simple.pl
#
# This is the most basic use for the ErrorTextDialog exception handler
# function, installed to catch main loop errors and Perl warnings, including
# Glib::Log messages turned into Perl warnings by Glib-Perl.
#
# The two installs at the start of the code is all it usually takes to have
# ErrorTextDialog in your program.  The rest is just buttons to deliberately
# induce errors etc, whereas in a real program you do everything possible
# not to have errors!
#


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ErrorTextDialog::Handler;

# Perl-Glib exception handler runs for errors under the main loop, meaning
# otherwise untrapped die() calls
Glib->install_exception_handler
  (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);

# this is a global for all warning messages
$SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;

#---------------------

# ErrorTextDialog uses the "application name" in the dialog titles, if set
Glib::set_application_name ('Simple Example');

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);

{
  my $label = Gtk2::Label->new (
'Click on the buttons below
to induce errors and warnings
for the ErrorTextDialog.');
  $vbox->pack_start ($label, 1,1,10);
}

{
  my $button = Gtk2::Button->new_with_label ("An error");
  $button->signal_connect (clicked => sub { die "This is an error" });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("A warning");
  $button->signal_connect (clicked => sub { die "This is a warning" });
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $button = Gtk2::Button->new_with_label ("A g_log warning");
  $button->signal_connect
    (clicked => sub { Glib->warning (undef, "A g_warning") });
  $vbox->pack_start ($button, 0,0,0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;

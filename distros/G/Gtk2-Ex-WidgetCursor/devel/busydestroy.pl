#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::WidgetCursor;

use FindBin;
my $progname = $FindBin::Script;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->set_name ("my_toplevel_1");
$toplevel->signal_connect (destroy => sub {
                             print "$progname: main_quit\n";
                             Gtk2->main_quit;
                           });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

{
  my $button = Gtk2::Button->new_with_label ("Busy and Exit");
  $button->signal_connect (clicked => sub {
                             print "$progname: busy and exit\n";
                             Gtk2::Ex::WidgetCursor->busy;
                             $toplevel->destroy;
                             Gtk2->main_quit;
                           });
  $vbox->pack_start ($button, 1,1,0);
}

package Foo;
use strict;
use warnings;

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;
  $self->{'circular'} = $self;
  return $self;
}

sub DESTROY {
  print "$progname: Foo destroy\n";
  Gtk2::Ex::WidgetCursor->unbusy;
}

package main;
my $foo = Foo->new;

$toplevel->show_all;
Gtk2->main;
print "$progname: main returned, now exit\n";
exit 0;

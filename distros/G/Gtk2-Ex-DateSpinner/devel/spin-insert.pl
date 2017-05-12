#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';

use FindBin;
my $progname = $FindBin::Script;

{
  package MySpin;
  use Glib::Object::Subclass
    'Gtk2::SpinButton',
      signals => { insert_text => \&_do_insert_text,
                 };
  sub _do_insert_text {
    my ($self, $text, $pos) = @_;
    print "insert text: '$text' at $pos\n";
    $self->signal_chain_from_overridden ('9', 1, 0);
  }
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new;
$toplevel->add ($vbox);

my $adj = Gtk2::Adjustment->new (15, 0, 9999, 1, 10, 0);

my $spin = MySpin->new;
$spin->set_adjustment ($adj);
$vbox->pack_start ($spin, 0,0,0);


$toplevel->show_all;
Gtk2->main;
exit 0;

#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2 '-init';

{
  package MyMenu;
  use Gtk2;

  use Glib::Object::Subclass
    'Gtk2::Menu',
      signals => { size_request => \&_do_size_request };

  sub _do_size_request {
    my ($self, $req) = @_;
    print "_do_size_request()\n";
    my @children = $self->get_children;
    unless (@children) {
      my $item = Gtk2::MenuItem->new('Foo');
      $item->show;
      $self->add ($item);
    }
    return shift->signal_chain_from_overridden(@_);
  }
}

{
  my $menu = Gtk2::Menu->new;
  my $req = $menu->size_request;
  print "empty     ",$req->width,"x",$req->height,"\n";
}
{
  my $menu = Gtk2::Menu->new;
  my $item = Gtk2::MenuItem->new('Foo');
  $item->show;
  $menu->add ($item);
  my $req = $menu->size_request;
  print "with item ",$req->width,"x",$req->height,"\n";
}
{
  my $menu = MyMenu->new;
  my $req = $menu->size_request;
  print "MyMenu    ",$req->width,"x",$req->height,"\n";
}

exit 0;

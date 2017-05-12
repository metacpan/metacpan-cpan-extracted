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
  package MyLabel;
  use Gtk2;

  use Glib::Object::Subclass
    'Gtk2::Label',
      signals => {
                   size_request => \&_do_size_request,
                 };

  sub _do_size_request {
    my ($self, $req) = @_;
    print "_do_size_request()\n";
    $req->width(88);
    $req->height(22);
    $self->signal_chain_from_overridden($req);
    print "chained size ",$req->width,"x",$req->height,"\n";
  }
}

{
  my $label = Gtk2::Label->new ('Foo');
  my $req = $label->size_request;
  print $req->width,"x",$req->height,"\n";
}
{
  my $label = MyLabel->new (label => 'Foo');
  my $req = $label->size_request;
  print $req->width,"x",$req->height,"\n";
}
exit 0;

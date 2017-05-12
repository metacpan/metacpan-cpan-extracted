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
use Glib::Ex::SignalIds;
use Gtk2 '-init';

{
  package MyLabel;
  use Gtk2;

  use Glib::Object::Subclass
    'Gtk2::Label';
}

my $label = Gtk2::Label->new ('Foo');
# {
#   my $req = $label->size_request;
#   print "initial ", $req->width,"x",$req->height,"\n";
# }

my $ids;
sub make_ids {
  $ids = Glib::Ex::SignalIds->new
    ($label,
     $label->signal_connect (size_request => \&_do_size_request));
  print "ids ",$ids->ids,"\n";
}
sub _do_size_request {
  my ($self, $req) = @_;
  print "_do_size_request()\n";
  $req->width(88);
  $req->height(22);

  undef $ids;
#  $self->queue_resize;
  my $super_req = $self->size_request;
  make_ids();
  print "super ", $super_req->width,"x",$super_req->height,"\n";

  $req->width ($super_req->width + 1000);
  $req->height ($super_req->height + 1000);
}

{
  make_ids ();
#  $label->queue_resize;
  my $req = $label->size_request;
  print "with ids ", $req->width,"x",$req->height,"\n";
}

exit 0;

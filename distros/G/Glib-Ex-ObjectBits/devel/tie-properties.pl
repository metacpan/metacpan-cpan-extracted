#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Glib::Ex::TieProperties;

{
  package My::Empty;
  use Glib::Object::Subclass 'Glib::Object';
}

{
  my %h;
  print "plain hash scalar(h) empty: ",scalar(%h),"\n";
  $h{1}=2;
  print "plain hash scalar(h)   one: ",scalar(%h),"\n";

  my $obj = My::Empty->new;
  tie %h, 'Glib::Ex::TieProperties', $obj;
  print "SCALAR: ",(scalar %h),"\n";
  print "keys: ",(keys %h),"\n";

  require Gtk2;
  $obj = Gtk2::Label->new;
  tie %h, 'Glib::Ex::TieProperties', $obj;
  print "SCALAR: ",(scalar %h),"\n";
  print "keys: ",(keys %h),"\n";
  exit 0;
}

if (0) {
  print defined exists &foo;
  exit 0;
}

use Gtk2;

{
  my $hbox = Gtk2::HBox->new;
  {
    print $hbox->get('width-request'),"\n";
    local Glib::Ex::TieProperties->new($hbox)->{'width-request'} = 100;
    print $hbox->get('width-request'),"\n";
  }
  print $hbox->get('width-request'),"\n";
  exit 0;
}

{
  my $hbox = Gtk2::HBox->new;
  my $h = Glib::Ex::TieProperties->new ($hbox);
  # while (my $key = each %$h) {
  #   print "$key  ",$h->{$key},"\n";
  # }
  while (my ($key, $value) = each %$h) {
    print "$key ",$value//'undef',"\n";
  }

  print "keys: ",(keys %$h),"\n";
  print "values: ",(values %$h),"\n";

  {
    print $h->{'width-request'},"\n";
    local $h->{'width-request'} = 100;
    print $h->{'width-request'},"\n";
  }
  print $h->{'width-request'},"\n";

  # delete $h->{'fjsdk'};
  # print $h->{'fjsdk'},"\n";
  # $h->{'fjsdk'} = 123;
  print exists($h->{'fjsdk'}),"\n";
  print exists($h->{'width-request'}),"\n";
  print scalar(%$h),"\n";
  keys(%$h) = 200;

  require Scalar::Util;
  Scalar::Util::weaken ($hbox);
  (defined $hbox) || die;
}

{
  my $hbox = Gtk2::HBox->new;

  print "in_object\n";
  Glib::Ex::TieProperties->in_object ($hbox);
  print $hbox->{'property'}->{'width-request'},"\n";

  Scalar::Util::weaken ($hbox);
  (defined $hbox)&& die;
}

{
  my $hbox = Gtk2::HBox->new;
  tie my(%h), 'Glib::Ex::TieProperties', $hbox;

  {
    local @h{'width-request','height-request'} = (100, 200);
    my $req = $hbox->size_request;
    print "in_object ",$req->width,"x",$req->height,"\n";
  }
  my $req = $hbox->size_request;
  print "in_object ",$req->width,"x",$req->height,"\n";

  print "SCALAR: ",(scalar %h),"\n";
}


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

use 5.008;

package Glib::Ex::TieProperty;
use strict;
use warnings;
use Carp;
use Glib;

our $VERSION = 1;

use constant DEBUG => 0;

sub new {
  my ($class, $obj, $pname) = @_;
  tie my($scalar), $class, $obj, $pname;
  return \$scalar;
}
sub object { $_[0]->[0] }

sub TIESCALAR {
  my ($class, $obj, $pname) = @_;
  $obj || croak "$class needs an object to tie";
  return bless [ $obj, $pname ], $class;
}
sub FETCH {
  my ($self) = @_;
  return $self->[0]->get_property($self->[1]);
}
sub STORE {
  my ($self, $value) = @_;
  $self->[0]->set_property ($self->[1], $value);
}

package main;

use Gtk2;
my $hbox = Gtk2::HBox->new;
my $ref = Glib::Ex::TieProperty->new ($hbox, 'width-request');
print $$ref,"\n";

our $wr;
tie $wr, 'Glib::Ex::TieProperty', $hbox, 'width-request';
sub foo {
  {
    local $wr = 100;
    print $$ref,"\n";
  }
}
foo ();
print $$ref,"\n";

# while (my $key = each %$h) {
#   print "$key  ",$h->{$key},"\n";
# }
# while (my $key = each %$h) {
#   print "$key  ",$h->{$key},"\n";
# }
# 
# {
#   print $h->{'width-request'},"\n";
#   local $h->{'width-request'} = 100;
#   print $h->{'width-request'},"\n";
# }
# print $h->{'width-request'},"\n";
# 
# # delete $h->{'fjsdk'};
# # print $h->{'fjsdk'},"\n";
# # $h->{'fjsdk'} = 123;
# print exists($h->{'fjsdk'}),"\n";
# print exists($h->{'width-request'}),"\n";
# print scalar(%$h),"\n";
# keys(%$h) = 200;



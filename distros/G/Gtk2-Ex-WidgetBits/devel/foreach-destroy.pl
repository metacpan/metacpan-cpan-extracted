#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;

{
  package Foo;
  my $n = 0;
  sub new {
    my ($class) = @_;
    $n++;
    print "create $n\n";
    return bless { n => $n }, $class;
  }
  sub DESTROY {
    my ($self) = @_;
    print "destroy $self->{'n'}\n";
  }
}

foreach my $f (map {Foo->new} 1 .. 4) {
  print "f $f->{'n'}\n";
}

{
  print "array\n";
  my @array = map {Foo->new} 1 .. 4;

  print "loop convert\n";
  foreach (@array) { $_ = Foo->new }

  print "map convert\n";
  @array = map {Foo->new} @array;

  print "while\n";
  while (@array) {
    my $f = shift @array;
    print "f $f->{'n'}\n";
  }
}

exit 0;

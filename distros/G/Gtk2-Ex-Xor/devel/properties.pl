#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


# Finding out what different GParamSpec property types are used in all
# Glib::Object types.

use 5.008;
use strict;
use warnings;
use Data::Dumper;
use List::Util;
use Scalar::Util;
use Glib;
use Gtk2 '-init';
use Gtk2::Pango;

my $toplevel = Gtk2::Window->new ('toplevel');
$toplevel->show;

my $bitmap = Gtk2::Gdk::Bitmap->create_from_data (undef, "\0", 1, 1);

my @packages;
foreach (keys %::) {
  walk ($_, '');
}
sub walk {
  my ($name, $level) = @_;
  if ($name eq 'main::') { return; }

  my $classname = $name;
  $classname =~ s/::$//g or return;
  push @packages, $classname;

  no strict;
  if (defined %{$name}) {
    foreach my $part (keys %{$name}) {
      walk ($name.$part, $level.' ');
    }
  }
}
# print join("\n",@packages);
print "total ",scalar @packages," packages\n";

foreach my $class (@packages) {
  if ($class =~ /::_LazyLoader$/) { next; }
  eval { $class->find_property ('x'); }; # force load, maybe
  if (! $class->can('list_properties')) { next; }

  my @props;
  eval { @props = $class->list_properties; } or next;

  # list_properties includes superclass defined properties, prune to just
  # those new in the class
  foreach my $superclass (Glib::Type->list_ancestors ($class)) {
    if ($superclass eq $class) { next; }
    foreach my $superprop ($superclass->list_properties) {
      @props = grep {$_->get_name ne $superprop->get_name} @props;
    }
  }

  foreach my $pspec (@props) {
    my $type = $pspec->get_value_type;
        my $pname = $pspec->get_name;

    if ($pspec->isa ('Glib::Param::Boxed')) {
      if ($type->isa('Gtk2::Gdk::Color')) {
        print "$class   $pname\n";
      }
    }
  }
}

exit 0;

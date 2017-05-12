#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

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

use strict;
use warnings;
use Test::Weaken;
print Test::Weaken->VERSION,"\n";

{
  package MyOverload;
  use Carp;
  use overload '+' => \&add;
  sub new {
    my ($class) = @_;
    my $x;
    return bless \$x, $class;
  }
  sub add {
    my ($x, $y, $swap) = @_;
    croak "I am not in the adding mood";
  }
}

Test::Weaken::leaks ({ constructor => sub {
                         return MyOverload->new;
                       },
                     });


{
  use Scalar::Util;
  my $obj = MyOverload->new;
  print Scalar::Util::refaddr($obj),"\n";
  print $obj+0,"\n";
}

# use Gtk2;
# Test::Weaken::leaks ({ constructor => sub {
#                          return Gtk2::Gdk::EventMask->new([]);
#                        },
#                      });;


#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Gtk2 '-init';

# uncomment this to run the ### lines
use Smart::Comments;

{
  package MyTie;
  sub TIEHASH {
    my ($class) = @_;
    ### TIEHASH
    return bless { }, $class;
  }
  sub FETCH  {
    my ($self, $key) = @_;
    ### FETCH key: $key
    123;
  }
}

my %hash;
tie %hash, 'MyTie';

{
  ### with 123
  my $ret = $hash{123};
  ### $ret
}
{
  ### with undef
  my $ret = $hash{undef};
  ### $ret
}


#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ListModelConcat.
#
# Gtk2-Ex-ListModelConcat is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ListModelConcat is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ListModelConcat.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

{
  package MyOverloadStore;
  use Gtk2;
  use Glib::Object::Subclass 'Gtk2::ListStore';
  use Carp;
  use overload '+' => \&add, fallback => 1;
  sub add {
    my ($x, $y, $swap) = @_;
    croak "I am not in the adding mood";
  }
}

require Gtk2::Ex::ListModelConcat;

my $store = MyOverloadStore->new;
if (eval { my $x = $store+0; 1 }) {
  plan skip_all => 'somehow overloaded object+0 no error, maybe perl 5.8.x badness?';
}
plan tests => 1;

my $concat = Gtk2::Ex::ListModelConcat->new (models => [$store]);
ok (1);

exit 0;

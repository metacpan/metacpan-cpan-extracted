#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.

__END__

my ($get_option, $set_option);
BEGIN {
  if (Gtk2::Gdk::Pixbuf->can('set_option')) {
    $set_option = 'set_option';
    $get_option = 'get_option';
  } else {
    $set_option = sub {
      my ($pixbuf, $key, $value) = @_;
      $pixbuf->{(__PACKAGE__)}->{$key} = $value;
    };
    $get_option = sub {
      my ($pixbuf, $key) = @_;
      if (exists $pixbuf->{(__PACKAGE__)}->{$key}) {
        return $pixbuf->{(__PACKAGE__)}->{$key};
      } else {
        return $pixbuf->get_option($key);
      }
    };
  }
}

sub _get_x_hot { shift->$get_option('x_hot') }
sub _get_y_hot { shift->$get_option('y_hot') }
                          -hotx       => \&_get_x_hot,
                          -hoty       => \&_get_y_hot,


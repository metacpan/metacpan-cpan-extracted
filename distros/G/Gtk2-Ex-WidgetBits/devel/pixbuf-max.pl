#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2;

{
  foreach my $type ('bmp',
                    'tiff',
                    'png',
                    'jpeg',
                    'ico',
                   ) {
    print "$type\n";
    my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, 0,0);
    $pixbuf->fill (0);
    if (eval {
      $pixbuf->save ("/tmp/xxx.$type", $type);
      1
    }) {
      print "$type ok 0,0\n";
    } else {
      print "$type 0,0 -- $@";
    }
  }
  exit 0;
}

{
  my @formats = Gtk2::Gdk::Pixbuf->get_formats;
  @formats = grep {$_->{'is_writable'}} @formats;
  print "writables: ", join(' ', map{$_->{'name'}}@formats), "\n";
}
{
  foreach my $type ('bmp',
                    'tiff',
                    'png',
                    'jpeg',
                    'ico',
                   ) {
    my $found_size = 0;

    for (my $pos = 23; $pos >= 0; $pos--) {
      my $bit = 1 << $pos;
      my $try_size = $found_size + $bit;
      my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb', 0, 8, $try_size, 1);
      $pixbuf->fill (0);
      if (eval {
        $pixbuf->save ("/tmp/xxx.$type", $type);
        1
      }) {
        $found_size = $try_size;
      } else {
        print "$type $try_size -- $@";
      }
    }

    my $hex = sprintf "0x%X", $found_size;
    print "$type max size $found_size $hex\n";
  }
  exit 0;
}

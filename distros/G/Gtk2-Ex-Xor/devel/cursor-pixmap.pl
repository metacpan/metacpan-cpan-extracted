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

use strict;
use warnings;
use Gtk2;

# uncomment this to run the ### lines
use Smart::Comments;

my $d = Gtk2::Gdk::Display->open (':0');
my $c = Gtk2::Gdk::Cursor->new_for_display ($d,'hand1');
$d->close;
undef $d;
print "$c\n";
exit 0;

{
  my $d = Gtk2::Gdk::Display->open (':0');
  my $cursor_obj = Gtk2::Gdk::Cursor->new_for_display ($d,'blank-cursor');

  my $pspec = Glib::ParamSpec->boxed ('equal', 'equal', 'blurb',
                                      'Gtk2::Gdk::Cursor',
                                      Glib::G_PARAM_READWRITE());
  my $cmp = $pspec->values_cmp($cursor_obj,$cursor_obj);

  ### $cursor_obj
  Scalar::Util::weaken ($d);
  ### $cursor_obj
  Scalar::Util::weaken ($cursor_obj);
  ### $cursor_obj
  exit 0;
}

{
  my $c = Gtk2::Gdk::Cursor->new ('hand1');
  my $pspec = Glib::ParamSpec->boxed ('equal', 'equal', 'blurb',
                                      'Gtk2::Gdk::Cursor',
                                      Glib::G_PARAM_READWRITE());
  my $cmp = $pspec->values_cmp($c,$c);
  ### $cmp
  ### $c
  Scalar::Util::weaken ($c);
  ### $c
  exit 0;
}

{
my $rootwin = Gtk2::Gdk->get_default_root_window;
my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1, 1, -1);
my $bitmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1, 1, 1);
my $cursor_obj = Gtk2::Gdk::Cursor->new_from_pixmap
  ($pixmap,
   $bitmap,
   Gtk2::Gdk::Color->new(0,0,0,0), # fg
   Gtk2::Gdk::Color->new(0,0,0,0), # bg
   0,0); # x,y hotspot
### $cursor_obj

undef $cursor_obj;
### $cursor_obj

exit 0;
}

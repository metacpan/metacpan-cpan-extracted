# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Getopt::Long;
use Glib 1.220; # for SOURCE_REMOVE
use Gtk2 '-init';
use Gtk2::Ex::Splash;


# my $option_root;
# 'root'   => \$option_root,

my @args;

# doesn't work ...
my $rootwin = Gtk2::Gdk->get_default_root_window;
require X11::Protocol;
my $X = X11::Protocol->new (':0');
if ($X->init_extension('Composite')) {
  $X->CompositeRedirectWindow ($rootwin->XID, 'Automatic');
  $X->QueryPointer($rootwin->XID);
  $X->ClearArea ($rootwin->XID, 0,0, 0,0);
  $X->QueryPointer($rootwin->XID);
  sleep 3;
}
# $rootwin->set_composited (1);  # no good, ends up "Manual"
my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, $rootwin->get_size, -1);
my $gc = Gtk2::Gdk::GC->new ($rootwin, { graphics_exposures => 0 });
$pixmap->draw_drawable ($gc, $rootwin, 0,0, 0,0, -1,-1);
@args = (pixmap => $pixmap);

my $splash = Gtk2::Ex::Splash->new (@args);
$splash->present;
Glib::Timeout->add (int(.75*1000), # in milliseconds
                    sub {
                      Gtk2->main_quit;
                      return Glib::SOURCE_REMOVE();
                    });
Gtk2->main;
exit 0;

#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-ErrorTextDialog.
#
# Gtk2-Ex-ErrorTextDialog is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ErrorTextDialog is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ErrorTextDialog.  If not, see <http://www.gnu.org/licenses/>.


# needs X11-Motif post 1.1b3 for fixes to QueryTree

use strict;
use warnings;
use Carp;
use X11::Lib;
use 5.010;

{
  $, = ' ';
  say keys %X::ID::;
  say keys %X::Window::;
}

{
print exists($ENV{'FOO'})?'yes':'no',"\n";
{
  local $ENV{'FOO'} = 'abc';
  print $ENV{'FOO'} // 'undef', "\n";
}
print exists($ENV{'FOO'})?'yes':'no',"\n";
}

if (0) {
  my $display_name = $ENV{'DISPLAY'};
  my $display = X::OpenDisplay ($display_name)
    || die "Cannot open '$display_name'";
  print "$display\n";

  my $window = X::DefaultRootWindow ($display);
  print "window $window ",$window->id,"\n";

  my $root;
  my $parent;
  my $children; # = bless \do{ my $x = 0 }, 'DUMMY_WindowPtrPtr';
  my $nchildren;
  my $ok = X::QueryTree ($display, $window, $root,$parent,$children,$nchildren);
  print "ok $ok\n";
  print "root   $root ",$root->id,"\n";
  print "parent $parent ",$parent->id,"\n";
}

sub window_get_parent_XID {
  my ($window) = @_;

  if (! $window->can('XID')) {
    return $window;  # not X11
  }
  my $xid = $window->XID;
  my $display = $window->get_display;
  my $display_name = $display->get_name;

  if (1) {
    # Gtk-Perl 1.220 doesn't have a $display->xdisplay
    #
    my $xdisplay = ($display->{__PACKAGE__.'.x11_lib'} ||= do {
      my $dname = $window->get_display->get_name;
      X::OpenDisplay ($dname) || croak "Cannot open display '$dname'"
      });
    my $xwindow = X::Window->new_from_id ($xid);
    X::QueryTree ($xdisplay, $xwindow,
                  my $root, my $parent, my $children, my $nchildren)
        || croak "Cannot XQueryTree";
    return $parent->id;
  }
}

if (! defined \&X::Window::new_from_id) {
  *X::Window::new_from_id = sub {
    my ($class, $xid) = @_;
    return bless \$xid, $class;
  }
}

use Gtk2 '-init';
my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->show;
$toplevel->get_display->flush;

printf ("%X\n", window_get_parent_XID ($toplevel->window));
#sleep 100;
exit 0;

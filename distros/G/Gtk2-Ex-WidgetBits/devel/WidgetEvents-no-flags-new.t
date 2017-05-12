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


# no new() until Glib-Perl 1.183
#
BEGIN {
  if (Gtk2::Gdk::EventMask->can('new')) { # Glib-Perl 1.183
    ### using EventMask->new
    eval <<'HERE';
      }
HERE
  } else {
    ### using fallback $empty_events
    eval <<'HERE';
      my $empty_events = bless (do{my $zero=0; \$zero}, 'Gtk2::Gdk::EventMask');
      sub _to_eventmask {
        my ($thing) = @_;
        if (Scalar::Util::blessed ($thing)) {
          return $thing;
        } else {
          return $empty_events + $thing;
        }
      }
HERE
  }
}





use strict;
use warnings;
use Test::More tests => 4;

use Gtk2;

{
  package Gtk2::Gdk::EventMask;
  sub can {
    my ($class, $name) = @_;
    if ($name eq 'new') {
      return 0;
    } else {
      return shift->SUPER::can(@_);
    }
  }
  sub new {
    die "oops Gtk2::Gdk::EventMask new()";
  }
}
diag (Gtk2::Gdk::EventMask->can('new'));
ok (! Gtk2::Gdk::EventMask->can('new'));

require Gtk2::Ex::WidgetEvents;

{
  my $flags = Gtk2::Ex::WidgetEvents::_to_eventmask([]);
  is_deeply ([@$flags], []);
}
{
  my $flags = Gtk2::Ex::WidgetEvents::_to_eventmask(['button-press-mask']);
  is_deeply ([@$flags], ['button-press-mask']);
}
{
  my $flags = Gtk2::Ex::WidgetEvents::_to_eventmask('button-press-mask');
  is_deeply ([@$flags], ['button-press-mask']);
}

exit 0;

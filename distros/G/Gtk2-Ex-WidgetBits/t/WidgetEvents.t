#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::WidgetEvents;

require Gtk2;
MyTestHelpers::glib_gtk_versions();
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';
plan tests => 30;

# return an arrayref
sub leftover_fields {
  my ($widget) = @_;
  my @keys = grep /Gtk2::Ex::WidgetEvents/, keys %$widget;

  # keeping this, for now ...
  @keys = grep {$_ ne 'Gtk2::Ex::WidgetEvents.base_events'} @keys;

  return \@keys;
}

#------------------------------------------------------------------------------

my $want_version = 48;
my $check_version = $want_version + 1000;
is ($Gtk2::Ex::WidgetEvents::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::WidgetEvents->VERSION,  $want_version, 'VERSION class method');
ok (eval { Gtk2::Ex::WidgetEvents->VERSION($want_version); 1 },
    "VERSION class check $want_version");
ok (! eval { Gtk2::Ex::WidgetEvents->VERSION($check_version); 1 },
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# flags +=

{
  my $e = Gtk2::Gdk::EventMask->new ([]);
  my $e2 = $e;
  $e2 += 'button-press-mask';
  is_deeply ($e->as_arrayref, [],
             'flags += orig unchanged');
  is_deeply ($e2->as_arrayref, ['button-press-mask'],
             'flags += copy changed');
}


#----------------------------------------------------------------------------
# # _to_event_mask()
#
# {
#   my $flags = Gtk2::Ex::WidgetEvents::_to_eventmask([]);
#   is_deeply ([@$flags], []);
# }
# {
#   my $flags = Gtk2::Ex::WidgetEvents::_to_eventmask(['button-press-mask']);
#   is_deeply ([@$flags], ['button-press-mask']);
# }
# {
#   my $flags = Gtk2::Ex::WidgetEvents::_to_eventmask('button-press-mask');
#   is_deeply ([@$flags], ['button-press-mask']);
# }


#------------------------------------------------------------------------------

# destroyed when weakened on unrealized
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $e = Gtk2::Ex::WidgetEvents->new ($widget, []);

  is ($e->VERSION, $want_version, 'VERSION object method');
  ok (eval { $e->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $e->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  require Scalar::Util;
  Scalar::Util::weaken ($e);
  ok (! defined $e, 'WidgetEvents destroyed by weaken, widget unrealized');
  is_deeply (leftover_fields($widget), [],
             'no WidgetEvents data left behind on unrealized');
}

# destroyed when weakened on realized
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;
  my $e = Gtk2::Ex::WidgetEvents->new ($widget);
  my $weak_e = $e;
  Scalar::Util::weaken ($weak_e);
  $e = undef;
  ok (! defined $weak_e, 'WidgetEvents destroyed by weaken, widget realized');
  is_deeply (leftover_fields($widget), [],
             'no WidgetEvents data left behind on realized');
}

# two destroyed when weakened on unrealized
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $e1 = Gtk2::Ex::WidgetEvents->new ($widget);
  my $e2 = Gtk2::Ex::WidgetEvents->new ($widget);
  my $weak_e1 = $e1;
  my $weak_e2 = $e2;
  Scalar::Util::weaken ($weak_e1);
  Scalar::Util::weaken ($weak_e2);
  $e1 = undef;
  $e2 = undef;
  ok (! defined $weak_e1,
      'WidgetEvents 1 destroyed by weakening, two unrealized');
  ok (! defined $weak_e2,
      'WidgetEvents 2 destroyed by weakening, two unrealized');
  is_deeply (leftover_fields($widget), [],
             'no WidgetEvents data left behind from two on unrealized');
}

# two destroyed when weakened on realized
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;
  my $e1 = Gtk2::Ex::WidgetEvents->new ($widget);
  my $e2 = Gtk2::Ex::WidgetEvents->new ($widget);
  my $weak_e1 = $e1;
  my $weak_e2 = $e2;
  Scalar::Util::weaken ($weak_e1);
  Scalar::Util::weaken ($weak_e2);
  $e1 = undef;
  $e2 = undef;
  ok (! defined $weak_e1, 'WidgetEvents 1 destroyed by weaken');
  ok (! defined $weak_e2, 'WidgetEvents 2 destroyed by weaken');
  is_deeply (leftover_fields($widget), [],
             'no WidgetEvents data left behind from two on realized');
}

# remove mask from realized
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;

  my $base_events = $widget->window->get_events;
  my $e = Gtk2::Ex::WidgetEvents->new ($widget, 'pointer-motion-mask');
  is_deeply (\@{$widget->window->get_events},
             \@{$base_events + ['pointer-motion-mask']},
             'window events base+pointer');

  $e->remove ('pointer-motion-mask');
  is_deeply (\@{$widget->window->get_events},
             \@{$base_events},
             'window events back to base');
}

# two WidgetEvents
{
  my $widget = Gtk2::Window->new ('toplevel');
  $widget->realize;

  my $base_events = $widget->window->get_events;
  my $e1 = Gtk2::Ex::WidgetEvents->new ($widget, 'pointer-motion-mask');
  my $e2 = Gtk2::Ex::WidgetEvents->new ($widget, 'pointer-motion-mask');
  is_deeply (\@{$widget->window->get_events},
             \@{$base_events + ['pointer-motion-mask']},
             'window events base+pointer');

  $e1 = undef;
  is_deeply (\@{$widget->window->get_events},
             \@{$base_events + ['pointer-motion-mask']},
             'window events base+pointer');

  $e2 = undef;
  is_deeply (leftover_fields($widget), [],
             'no WidgetEvents data left behind after two WidgetEvents');

  is_deeply (\@{$widget->window->get_events},
             \@{$base_events},
             'window events back to base_events');
}

# installed when realized
{
  my $widget = Gtk2::Window->new ('toplevel');
  my $e = Gtk2::Ex::WidgetEvents->new ($widget, 'pointer-motion-mask');

  $widget->realize;
  ok ($widget->window->get_events >= 'pointer-motion-mask',
      'initial realize');

  $widget->unrealize;
  $widget->realize;
  ok ($widget->window->get_events >= 'pointer-motion-mask',
      'after a re-realize');

  $e->remove ('pointer-motion-mask');
  ok (! ($widget->window->get_events & 'pointer-motion-mask'),
      'remove while realized');

  $e->add ('pointer-motion-mask');
  $widget->realize;
  ok ($widget->window->get_events >= 'pointer-motion-mask',
      'add() while realized');

  $e->remove ('pointer-motion-mask');
  ok (! ($widget->window->get_events & 'pointer-motion-mask'),
      'remove() while realized');
}

exit 0;

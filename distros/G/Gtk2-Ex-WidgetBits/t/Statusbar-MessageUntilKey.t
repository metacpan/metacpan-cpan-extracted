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

require Gtk2::Ex::Statusbar::MessageUntilKey;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';

plan tests => 10;

{
  my $want_version = 48;
  is ($Gtk2::Ex::Statusbar::MessageUntilKey::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::Statusbar::MessageUntilKey->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::Statusbar::MessageUntilKey->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Statusbar::MessageUntilKey->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------

# This diabolical bit of code is what it takes to synthesize a
# Gtk2::Gdk::Event::Key which gtk_bindings_activate_event() will dispatch.
# That func looks at the hardware_keycode and group, rather than the
# keyval in the event, so must generate those.  hardware_keycode values
# are basically arbitrary aren't they?  At any rate the strategy is to
# lookup what hardware code is Return in the display keymap and use that.
# gtk_bindings_activate_event() then ends up then going the other way,
# turning the hardware code into a keyval to lookup in the bindingset!
#
# The gtk_widget_get_display() docs say $mywidget won't have a display
# until it's the child of a toplevel.  Gtk 2.12 will give you back the
# default display before then, but probably better not to rely on that.
#
# my $event;
# if ($have_display) {
#
#   $toplevel->add ($mywidget);
#   my $display = $mywidget->get_display;
#   my $keymap = Gtk2::Gdk::Keymap->get_for_display ($display);
#   my @keys = $keymap->get_entries_for_keyval ($keyval);
#
#
#  = Gtk2::Gdk::Event->new ('key-press');
# $event->keycode (Gtk2::Gdk->keyval_from_name('x'));
# $event->keyval (Gtk2::Gdk->keyval_from_name('x'));

{
  my $toplevel = Gtk2::Window->new;
  my $statusbar = Gtk2::Statusbar->new;
  $toplevel->add ($statusbar);

  my $pushed = 0;
  my $popped = 0;
  $statusbar->signal_connect
    (text_pushed => sub {
       my ($statusbar, $context_id, $text) = @_;
       # diag "push: ",(defined $text ? $text : 'undef');
       $pushed++ });
  $statusbar->signal_connect
    (text_popped => sub {
       my ($statusbar, $context_id, $text) = @_;
       # diag "pop: ",(defined $text ? $text : 'undef');
       $popped++;
     });

  #------
  Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, 'hello');
  is ($pushed, 1, 'text-pushed emitted');

  $popped = 0;
  Gtk2::Ex::Statusbar::MessageUntilKey->remove($statusbar);
  is ($popped, 1, 'text-popped emitted');
  is_deeply ($statusbar, {}, 'no fields left on statusbar');

  #------
  $statusbar->realize;
  my $event = Gtk2::Gdk::Event->new ('key-press');
  $event->window ($statusbar->window);
  $event->keyval (Gtk2::Gdk->keyval_from_name('x'));

  Gtk2::Ex::Statusbar::MessageUntilKey->message($statusbar, 'hello');
  $popped = 0;
  Gtk2->main_do_event ($event);
  is ($popped, 1, 'text-popped emitted by keypress event');
  is_deeply ($statusbar, {},
             'no fields left on statusbar after keypress event');

  #------
  my $subclass_remove_called;
  {
    package MySubclass;
    use base 'Gtk2::Ex::Statusbar::MessageUntilKey';
    sub remove {
      my $class_or_self = shift;
      $subclass_remove_called = 1;
      $class_or_self->SUPER::remove (@_);
    }
  }
  MySubclass->message($statusbar, 'hello');
  Gtk2->main_do_event ($event);
  is ($subclass_remove_called, 1, 'Subclass remove() called');
}

exit 0;

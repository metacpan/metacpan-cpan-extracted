#!/usr/bin/perl

# Copyright 2009 by the gtk2-perl team (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, see <http://www.gnu.org/licenses/>.


package My::Object;
use strict;
use warnings;
use Gtk2;
use Glib::Object::Subclass
  'Gtk2::Object',
  signals => { mysig => { param_types   => [],
                          return_type   => undef,
                          flags         => ['run-last','action'],
                          class_closure => \&do_mysig },
               mysig_with_long => { param_types   => [ 'Glib::Long' ],
                                    return_type   => undef,
                                    flags         => ['run-last','action'],
                                    class_closure => \&do_mysig_with_long },
               mysig_with_float => { param_types   => [ 'Glib::Double' ],
                                     return_type   => undef,
                                     flags         => ['run-last','action'],
                                     class_closure => \&do_mysig_with_float },
             };
my $mysig_seen;
sub do_mysig {
  #Test::More::diag ("mysig runs");
  $mysig_seen = 1;
}
my $mysig_with_long_value;
sub do_mysig_with_long {
  my ($self, $value) = @_;
  #Test::More::diag ("mysig_with_long runs, value=$value");
  $mysig_with_long_value = $value;
}
my $mysig_with_float_value;
sub do_mysig_with_float {
  my ($self, $value) = @_;
  #Test::More::diag ("mysig_with_float runs, value=$value");
  $mysig_with_float_value = $value;
}

package My::Widget;
use strict;
use warnings;
use Gtk2;
use Glib::Object::Subclass
  'Gtk2::EventBox',
  signals => { mywidgetsig => { parameter_types => [],
                          return_type => undef,
                          flags => ['run-last','action'],
                          class_closure => \&do_mywidgetsig },
             };
my $mywidgetsig_seen;
sub do_mywidgetsig {
  #Test::More::diag ("mywidgetsig runs");
  $mywidgetsig_seen = 1;
}


package main;
use strict;
use warnings;
# Note: need '-init' to make Gtk2::Rc do its thing ...
use Gtk2::TestHelper tests => 43;

# A few tests below require a valid keymap, which some display servers lack.
# So try to determine if we're affected and skip the relevant tests if so.
my $keymap = Gtk2::Gdk::Keymap->get_default();
my @entries = $keymap->get_entries_for_keyval(
  Gtk2::Gdk->keyval_from_name('Return'));
my $have_valid_keymap = scalar @entries != 0;

#-----------------------------------------------------------------------------
# new()

my $mybindings = Gtk2::BindingSet->new('mybindings');
ok ($mybindings, 'new()');

#-----------------------------------------------------------------------------
# priority constants

is (Gtk2::GTK_PATH_PRIO_LOWEST, 0);
ok (Gtk2::GTK_PATH_PRIO_GTK);
ok (Gtk2::GTK_PATH_PRIO_APPLICATION);
ok (Gtk2::GTK_PATH_PRIO_THEME);
ok (Gtk2::GTK_PATH_PRIO_RC);
ok (Gtk2::GTK_PATH_PRIO_HIGHEST);

#-----------------------------------------------------------------------------
# set_name() field accessor

is ($mybindings->set_name, 'mybindings',
    'set_name() of mybindings');

#-----------------------------------------------------------------------------
# find()

ok (Gtk2::BindingSet->find('mybindings'),
    'find() mybindings');
is (Gtk2::BindingSet->find('nosuchbindingset'), undef,
    'find() not found');

#-----------------------------------------------------------------------------
# by_class()

ok (Gtk2::BindingSet->by_class('Gtk2::Entry'),
    'by_class() Gtk2::Entry');

#-----------------------------------------------------------------------------
# activate()

# The rc mechanism doesn't actually parse anything or create any
# GtkBindingSet's until one or more GtkSettings objects exist and are
# interested in the rc values.  Create a dummy label widget to force that to
# happen and thus ensure creation of the "some_bindings" set.
#
my $dummy_label = Gtk2::Label->new;

Gtk2::Rc->parse_string (<<'HERE');
binding "some_bindings" {
  bind "Return" { "mysig" () }
}
HERE

{
  my $some_bindings = Gtk2::BindingSet->find('some_bindings');
  ok ($some_bindings, 'find() of RC parsed bindings');

  my $myobj = My::Object->new;
  $mysig_seen = 0;
  ok ($some_bindings->activate (Gtk2::Gdk->keyval_from_name('Return'),
                                [],$myobj),
      'activate() return true on myobj');
  is ($mysig_seen, 1, 'activate() runs mysig on myobj');
}

#-----------------------------------------------------------------------------
# add_path() and $object->bindings_activate() and bindings_activate_event()

Gtk2::Rc->parse_string (<<'HERE');
binding "my_widget_bindings" {
  bind "Return" { "mywidgetsig" () }
}
HERE

# As of Gtk 2.12 $gtkobj->bindings_activate() only actually works on a
# Gtk2::Widget, not a Gtk2::Object, hence using My::Widget to exercise
# add_path() instead of My::Object.
SKIP: {
  skip 'Need a keymap and gtk+ >= 2.4', 5
    unless $have_valid_keymap && Gtk2->CHECK_VERSION(2, 4, 0);

  my $my_widget_bindings = Gtk2::BindingSet->find('my_widget_bindings');
  ok ($my_widget_bindings, 'find() of RC parsed bindings');

  $my_widget_bindings->add_path ('class', 'My__Widget',
                                 Gtk2::GTK_PATH_PRIO_APPLICATION);

  my $mywidget = My::Widget->new;
  my $keyval = Gtk2::Gdk->keyval_from_name ('Return');
  my $modifiers = [];

  $mywidgetsig_seen = 0;
  ok ($mywidget->bindings_activate ($keyval,$modifiers),
      'bindings_activate() return true on mywidget');
  is ($mywidgetsig_seen, 1,
      'bindings_activate() runs mywidgetsig on mywidget');

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
  my $toplevel = Gtk2::Window->new;
  $toplevel->add ($mywidget);
  my $display = $mywidget->get_display;
  my $keymap = Gtk2::Gdk::Keymap->get_for_display ($display);
  my @keys = $keymap->get_entries_for_keyval ($keyval);
  # diag "keys ", explain \@keys;

  my $event = Gtk2::Gdk::Event->new ('key-press');
  $event->window ($mywidget->window);
  $event->keyval ($keyval);
  $event->set_state ($modifiers);
  $event->group($keys[0]->{'group'});
  $event->hardware_keycode($keys[0]->{'keycode'});
  $mywidget->bindings_activate_event ($event);

  $mywidgetsig_seen = 0;
  ok ($mywidget->bindings_activate_event ($event),
      'bindings_activate() return true on mywidget');
  is ($mywidgetsig_seen, 1,
      'bindings_activate() runs mywidgetsig on mywidget');

  $toplevel->destroy;
}

#-----------------------------------------------------------------------------
# entry_add_signal()

{
  my $bindings = Gtk2::BindingSet->new ('entry_add_signal_test');
  my $obj = My::Object->new;

  {
    my $keyval = Gtk2::Gdk->keyval_from_name('Return');
    my $modifiers = [];
    $bindings->entry_add_signal ($keyval, $modifiers, 'mysig');
    $mysig_seen = 0;
    ok ($bindings->activate ($keyval, $modifiers, $obj),
        'entry_add_signal() activate on MyObject -- dispatch mysig');
    is ($mysig_seen, 1,
        'entry_add_signal() activate on MyObject -- ran mysig');
  }

  # object taking Glib::Long, pass as Glib::Long
  #
  {
    my $keyval = Gtk2::Gdk->keyval_from_name('Escape');
    my $modifiers = [];
    my $arg = 12456;
    $bindings->entry_add_signal ($keyval, $modifiers, 'mysig-with-long',
                                 'Glib::Long', $arg);
    $mysig_with_long_value = 0;
    ok ($bindings->activate ($keyval, $modifiers, $obj),
        'entry_add_signal() activate on MyObject -- dispatch mysig_with_long');
    is ($mysig_with_long_value, $arg,
        'entry_add_signal() activate on MyObject -- mysig_with_long value');
  }

  # object taking Glib::Float, pass as Glib::Double
  #
  {
    my $keyval = Gtk2::Gdk->keyval_from_name('space');
    my $modifiers = [ 'control-mask' ];
    my $arg = 1.25;
    $bindings->entry_add_signal ($keyval, $modifiers, 'mysig-with-float',
                                 'Glib::Double', $arg);
    $mysig_with_float_value = 0;
    ok ($bindings->activate ($keyval, $modifiers, $obj),
        'entry_add_signal() activate on MyObject -- dispatch mysig_with_float');
    delta_ok ($mysig_with_float_value, $arg,
              'entry_add_signal() activate on MyObject -- mysig_with_float value');
  }

  Glib::Type->register_flags ('My::Flags',
                              ['value-one'   =>  8 ],
                              ['value-two'   => 16 ],
                              ['value-three' => 32 ]);

  # object taking Glib::Long, give flags as arrayref
  #
  {
    my $keyval = Gtk2::Gdk->keyval_from_name('Escape');
    my $modifiers = [ 'control-mask' ];
    my $flags = ['value-one', 'value-three'];
    my $flags_num = 40;
    $bindings->entry_add_signal ($keyval, $modifiers, 'mysig-with-long',
                                 'My::Flags', $flags);
    $mysig_with_long_value = -1;
    ok ($bindings->activate ($keyval, $modifiers, $obj),
        'entry_add_signal() activate on MyObject -- dispatch mysig_with_long');
    is ($mysig_with_long_value, $flags_num,
        'entry_add_signal() activate on MyObject -- mysig_with_long value');
  }

  # object taking Glib::Long, give flags as flags object
  #
  {
    my $keyval = Gtk2::Gdk->keyval_from_name('Escape');
    my $modifiers = [ 'control-mask' ];
    my $flags = My::Flags->new (['value-one', 'value-two']);
    my $flags_num = 24;
    $bindings->entry_add_signal ($keyval, $modifiers, 'mysig-with-long',
                                 'Glib::Flags', $flags);
    $mysig_with_long_value = -1;
    ok ($bindings->activate ($keyval, $modifiers, $obj),
        'entry_add_signal() activate on MyObject -- dispatch mysig_with_long');
    is ($mysig_with_long_value, $flags_num,
        'entry_add_signal() activate on MyObject -- mysig_with_long value');
  }

  Glib::Type->register_flags ('My::Enum',
                              [eeeek => 123 ]);

  # object taking Glib::Long, give enum as string
  #
  {
    my $keyval = Gtk2::Gdk->keyval_from_name('space');
    my $modifiers = [];
    $bindings->entry_add_signal ($keyval, $modifiers, 'mysig-with-long',
                                 'My::Enum', 'eeeek');
    $mysig_with_long_value = -1;
    ok ($bindings->activate ($keyval, $modifiers, $obj),
        'entry_add_signal() activate on MyObject -- dispatch mysig_with_long');
    is ($mysig_with_long_value, 123,
        'entry_add_signal() activate on MyObject -- mysig_with_long value');
  }
}

#-----------------------------------------------------------------------------
# entry_remove()

{
  my $bindings = Gtk2::BindingSet->new ('entry_remove_test');
  my $obj = My::Object->new;

  my $keyval = Gtk2::Gdk->keyval_from_name('Return');
  my $modifiers = [];
  $bindings->entry_add_signal ($keyval, $modifiers, 'mysig');

  $mysig_seen = 0;
  ok ($bindings->activate ($keyval, $modifiers, $obj),
      'before entry_remove() activate on MyObject -- dispatch mysig');
  is ($mysig_seen, 1,
      'before entry_remove() activate on MyObject -- ran mysig');

  $bindings->entry_remove ($keyval, $modifiers);

  $mysig_seen = 0;
  ok (! $bindings->activate ($keyval, $modifiers, $obj),
      'after entry_remove() activate on MyObject -- no dispatch mysig');
  is ($mysig_seen, 0,
      'after entry_remove() activate on MyObject -- no run mysig');
}


#-----------------------------------------------------------------------------
# entry_skip()

SKIP: {
  skip 'Need a keymap', 8
    unless $have_valid_keymap;

  skip 'entry_skip() new in 2.12', 8
    unless Gtk2->CHECK_VERSION(2, 12, 0);

  # see that basic invocation on object doesn't dispatch
  #
  my $skip_bindings = Gtk2::BindingSet->new ('entry_skip_test');
  my $keyval = Gtk2::Gdk->keyval_from_name('Return');
  my $modifiers = [];
  $skip_bindings->entry_add_signal ($keyval, $modifiers, 'mysig');

  my $obj = My::Object->new;

  $mysig_seen = 0;
  ok ($skip_bindings->activate ($keyval, $modifiers, $obj),
      'before entry_skip() activate on MyObject -- dispatch mysig');
  is ($mysig_seen, 1,
      'before entry_skip() activate on MyObject -- ran mysig');

  $skip_bindings->entry_skip ($keyval, $modifiers);

  $mysig_seen = 0;
  ok (! $skip_bindings->activate ($keyval, $modifiers, $obj),
      'after entry_skip() activate on MyObject -- no dispatch mysig');
  is ($mysig_seen, 0,
      'after entry_skip() activate on MyObject -- no run mysig');


  # When an entry_skip() binding shadows another binding the latter doesn't
  # run.
  #
  # This more exercises gtk than it does the bindings, but it does make sure
  # the shared code of ->entry_skip() and ->entry_remove() have the right
  # func under the right name.
  #
  my $mywidget = My::Widget->new;

  $mywidgetsig_seen = 0;
  ok ($mywidget->bindings_activate (Gtk2::Gdk->keyval_from_name('Return'),[]),
      'before entry_skip(), bindings_activate return true on mywidget');
  is ($mywidgetsig_seen, 1,
      'before entry_skip(), bindings_activate runs mywidgetsig on mywidget');

  $skip_bindings->add_path ('widget-class', 'My__Widget',
                            Gtk2::GTK_PATH_PRIO_HIGHEST);

  $mywidgetsig_seen = 0;
  ok (! $mywidget->bindings_activate(Gtk2::Gdk->keyval_from_name('Return'),[]),
      'before entry_skip(), bindings_activate return true on mywidget');
  is ($mywidgetsig_seen, 0,
      'before entry_skip(), bindings_activate runs mywidgetsig on mywidget');
}

exit 0;

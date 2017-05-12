#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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


use strict;
use warnings;
use Devel::GlobalDestruction ();

BEGIN { $ENV{'DISPLAY'} ||= ':0' }
use Gtk2 '-init';

{
  package Foo;

  use Glib::Object::Subclass
    'Glib::Object',
      signals => { status_changed => { param_types => ['Glib::String'],
                                       return_type => undef },
                 };
}

{
  package Bar;
  sub new {
    my ($class) = @_;
    my $hook_id = Foo->signal_add_emission_hook
      (status_changed => sub { print "status changed\n" });
    return bless { hook_id => $hook_id }, $class;
  }
  sub DESTROY {
    my ($self) = @_;
    my $hook_id = $self->{'hook_id'};
    print "GlobalDestruction ", Devel::GlobalDestruction::in_global_destruction(),"\n";
    print "DESTROY hook $hook_id\n";
    Foo->signal_remove_emission_hook
      (status_changed => $hook_id);
  }
}

{
  package Quux;
  sub new {
    my ($class) = @_;

    my $query = Gtk2::Widget->signal_query ('button_press_event');
    print "query button_press_event $query\n";

    my $hook_id = Gtk2::Widget->signal_add_emission_hook
      (button_press_event => sub { print "button press\n" });
    return bless { hook_id => $hook_id }, $class;
 }

  sub DESTROY {
    my ($self) = @_;

    my $query = Gtk2::Widget->signal_query ('button_press_event');
    print "query button_press_event $query\n";

    my $hook_id = $self->{'hook_id'};
    print "GlobalDestruction ", Devel::GlobalDestruction::in_global_destruction(),"\n";
    print "DESTROY hook $hook_id\n";
    Gtk2::Widget->signal_remove_emission_hook
      (button_press_event => $hook_id);
  }
}

my $label = Gtk2::Label->new;

my $bar = Bar->new;
$bar->{'circular'} = $bar;

my $quux = Quux->new;
$quux->{'circular'} = $quux;

exit 0;

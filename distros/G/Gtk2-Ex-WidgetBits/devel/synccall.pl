#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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
use Gtk2 '-init';
use Gtk2::Ex::SyncCall;

my $toplevel = Gtk2::Window->new('toplevel');

my $drawingarea = Gtk2::DrawingArea->new;
$drawingarea->set_size_request (100, 100);
$toplevel->add($drawingarea);

$toplevel->show_all;
my $widget = $drawingarea;

if (1) {
  print "initial\n";
  Gtk2::Ex::SyncCall->sync ($widget, sub { print "hello\n"; });
  Gtk2::Ex::SyncCall->sync ($widget, sub { print "world\n"; });
}

if (1) {
  Glib::Timeout->add
      (3000, sub {
         print "another\n";
         Gtk2::Ex::SyncCall->sync ($widget, sub { print "one\n"; });
         Gtk2::Ex::SyncCall->sync ($widget, sub { print "two\n"; });
         return 1;
       });
}

Gtk2->main;
exit 0;



__END__

sub sync {
  my ($class, $widget, $callback, $userdata) = @_;
  push @$sync_list, $class->new (widget => $widget,
                                 callback => $callback,
                                 callback_args => [$userdata],
                                 _permanent => 1)
}

sub new_for_object {
  my ($class, $widget, $callback, $obj) = @_;
  return $class->new (widget => $widget,
                      callback => $callback,
                      callback_obj => $obj);
}

# widget =>
# callback =>
# callback_obj =>
# and_idle => bool
# and_idle_timeout => ms
# and_idle_limited => ms
# idle_priority => 
# timeout_priority => 
# and_priority => 
# priority => 
#
# or_timeout

sub new {
  my ($class, %self) = @_;
  my $widget = $self{'widget'} || croak 'SyncCall: no target widget';
  my $callback = $self{'callback'} || croak 'SyncCall: no callback';
  my $display = $widget->$get_display;

  my $self = bless \%self, $class;
  push @$sync_list, $self;
  unless (delete $self{'_permanent'}) {
    Scalar::Util::weaken ($sync_list->[-1]);
  }
  return $self;
}

sub DESTROY {
  
}

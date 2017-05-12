#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;



#   If the Clock widget is
# unmapped then the timer doesn't run.


  #   signals => { map   => \&_do_map_or_unmap,
  #                unmap => \&_do_map_or_unmap,
  #              },
  #   if ($self->mapped) {
  #   } else {
  #     undef $self->{'timer'};
  #   }

# If timer running then the string is up-to-date already.
# On doing an update could start the timer so as to know it's up-to-date
# until that next update time, if that saved a little work in size-request,
# and maybe a user $clock->update() too.
sub _do_size_request {
  my ($self, $req) = @_;
  if (! $self->{'timer'}) {
    _update($self);
  }
  return shift->signal_chain_from_overridden (@_);
}

# 'map' class closure ($self)
# 'unmap' class closure ($self)
#
# This is asking the widget to map or unmap itself, not map-event or
# unmap-event back from the server.
#
sub _do_map_or_unmap {
  my ($self) = @_;
  ### Clock _do_map_or_unmap()

  # chain before _update(), so the GtkWidget code sets or unsets the mapped
  # flag which _update() will look at
  $self->signal_chain_from_overridden;
  ### mapped: $self->mapped
  _update ($self);
}



package Gtk2::Ex::NoWindowVisibility;
use strict;
use warnings;

sub new {
  my ($class, $widget) = @_;
  if ($widget->flags & 'no-window') {
    die;
  }
  my $events = Gtk2::Ex::WidgetEvents->new ($widget, 'visibility-notify-mask');
  my $self =  bless { widget => $widget, 
                 events => $events,
                    }, $class;
  Scalar::Util::weaken ($self->{'widget'});
  return $self;
}

package Gtk2::Ex::Visibility;
use strict;
use warnings;
use Scalar::Util;
use Glib::Ex::SignalIds;

sub new {
  my ($class, $widget) = @_;
  if ($widget->flags & 'no-window') {
    die;
  }

  my $self =  bless { widget => $widget,
                      visibility_state => '',
                      events => Gtk2::Ex::WidgetEvents->new ($widget, 'visibility-notify-mask'),
                      ids => $ids,
                    }, $class;
  Scalar::Util::weaken ($self->{'widget'});

  Scalar::Util::weaken (my $weak_self = $self);
  my $self->{'ids'} = Glib::Ex::SignalIds->new
    ($widget,
     $widget->signal_connect ('visibility_notify_event',
                              \&_do_visibility_notify_event,
                              \$weak_self));

  return $self;
}

sub _do_visibility_notify_event {
  my ($ref_weak_self, $event) = @_;
  my $self = $$ref_weak_self || return 0; # Gtk2::EVENT_PROPAGATE
  $self->{'visibility_state'} = $event->state;
  $self->notify ('visibility-state');
  return 0; # Gtk2::EVENT_PROPAGATE
}

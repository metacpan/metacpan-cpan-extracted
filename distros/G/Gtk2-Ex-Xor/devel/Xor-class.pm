# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Xor;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util;

use Glib::Object::Subclass
  'Glib::Object',
  signals => { draw => { param_types => [ 'Gtk2::Widget',
                                          'Gtk2::Window',
                                          'Gtk2::Gdk::Region' ],
                         return_type => undef },
             },
  properties => [ Glib::ParamSpec->object
                  ('widget',
                   'widget',
                   'Widget to draw the lasso on.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('active',
                   'active',
                   'True if xoring is being drawn.',
                   0, # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->boolean
                  ('drawn',
                   'drawn',
                   'True if the xor is currently drawn.',
                   0, # default
                   Glib::G_PARAM_READWRITE),
                ];

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};

  if ($pname eq 'widget') {
    my $drawn = $self->{'drawn'};
    _undraw ($self);
    $self->{$pname} = $newval;  # per default GET_PROPERTY
    my $widget = $newval;

    Scalar::Util::weaken ($self->{'widget'});
    $self->{'style_sig'} = $widget && Glib::Ex::SignalIds->new
      ($widget,
       $widget->signal_connect (style_set => \&_do_style_set,
                                Gtk2::Ex::Xor::_ref_weak($self)));
    delete $self->{'gc'}; # new colours etc in new widget

    if ($drawn) {
      _draw($self);
    }
  }

  if ($pname eq 'active') {
    $self->{'active'} = $newval;
    if ($newval) {
      _draw ($self);
    } else {
      _undraw ($self);
    }
  }

  if ($pname eq 'widget' || $pname eq 'active') {
    $self->{'widget_ids'} = $self->{'active'}
      && (my $widget = $self->{'widget'})
        && do {
          my $ref_weak_self = Gtk2::Ex::Xor::_ref_weak ($self);
          Glib::Ex::SignalIds->new
              ($widget,
               $widget->signal_connect_after (expose_event => \&_do_expose,
                                              $ref_weak_self));
        };
  }
}

sub _draw {
  my ($self) = @_;
  my ($widget, $window);
  if ($self->{'active'}
      && ! $self->{'drawn'}
      && ($widget = $self->{'widget'})
      && ($window = $widget->window)) {
    $self->signal_emit ('draw', $widget, $window, undef);
    $self->{'drawn'} = 1;
    $self->notify('drawn');
  }
}
sub _undraw {
  my ($self) = @_;
  my ($widget, $window);
  if ($self->{'drawn'}) {
    my ($widget, $window);
    if (($widget = $self->{'widget'})
        && ($window = $widget->window)) {
      $self->signal_emit ('draw', $widget, $window, undef);
    }
    $self->{'drawn'} = 0;
    $self->notify('drawn');
  }
}

# 'style-set' signal handler on widget
sub _do_style_set {
  my ($widget, $prev_style, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  delete $self->{'gc'};  # for new colour
}

# 'expose' signal handler on widget
sub _do_expose {
  my ($widget, $event, $ref_weak_self) = @_;
  if (my $self = $$ref_weak_self) {
    ### Xor _do_expose(): "$widget", active=" . ($self->{'active'}||0)
    if ($self->{'drawn'}) {
      $self->signal_emit ('draw', $self, $event->region);
    }
  }
  return 0; # Gtk2::EVENT_PROPAGATE
}




#------------------------------------------------------------------------------


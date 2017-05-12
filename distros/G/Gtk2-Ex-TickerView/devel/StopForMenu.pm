# Gtk2::Ex::TickerView::Stopper
#     tickerview
#     active
#
# Gtk2::Ex::TickerView::Stopper->for_menu($tickerview, $menu)
# $ticker->stop_for_menu
#     while menu popped up
# Gtk2::Ex::TickerView::StopForMenu
#     tickerview  - weak
#     menu        - weak
#     active

# 	$ticker->stop_for_menu($menu) during popup menu
# 	$ticker->stopper  object lifespan
# 	Gtk2::Ex::TickerView::Pause



# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::TickerView::StopForMenu;
use strict;
use warnings;
use 5.008;
use Scalar::Util 'weaken';
use Glib::Ex::SignalIds;
use Gtk2::Ex::TickerView::Stopper;

our $VERSION = 15;

use Glib::Object::Subclass
  'Gtk2::Ex::TickerView',
  properties => [ Glib::ParamSpec->object
                  ('menu',
                   'menu',
                   'Menu widget to stop for.',
                   'Gtk2::Menu',
                   Glib::G_PARAM_READWRITE),
                ];

sub SET_PROPERTY {
  my ($self, $pspec, $menu) = @_;

  weaken ($self->{'menu'} = $newval);
  $self->{'ids'} = $menu && do {
    Scalar::Util::weaken (my $weak_self = $self);
    my $ref_weak_self = \$weak_self;
    Glib::Ex::SignalIds->new
        ($menu,
         $model->signal_connect_after (map   => \&_do_menu_map,
                                       \$weak_self),
         $model->signal_connect_after (unmap => \&_do_menu_map,
                                       \$weak_self))
      };
  _do_menu_map($menu, \$self);
}

sub _do_menu_map {
  my ($menu, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->set (stop => $menu && $menu->mapped);
}

1;
__END__

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::QuadScroll::ArrowButton;
use 5.008;
use strict;
use warnings;
use Gtk2;

use Gtk2::Ex::ArrowButton;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 57;

use Glib::Object::Subclass
  'Gtk2::Ex::ArrowButton',
  signals => { clicked => \&_do_clicked };

sub _do_clicked {
  my ($self) = @_;
  ### QuadScroll-Arrow _do_clicked()
  my $parent = $self->get_parent || return;
  my $arrow_type = $self->get('arrow-type');
  $parent->signal_emit ('change-value',
                        (Gtk2->get_current_event->get_state & 'control-mask'
                         ? 'page' : 'step') . '-' . $arrow_type);
}

1;
__END__

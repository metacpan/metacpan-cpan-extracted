# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Menu::EnumRadio::Item;
use 5.008;
use strict;
use warnings;
use Glib::Ex::ObjectBits;
use Gtk2;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

# Gtk2::RadioMenuItem is no good as the base class since it insists on at
# least one item active all the time.
#
# The _do_activate() class handler here allows a parent notify without a
# separate activate signal connection on each item.

use Glib::Object::Subclass
  'Gtk2::CheckMenuItem',
  signals => { activate => \&_do_activate },
  properties => [ Glib::ParamSpec->string
                  ('nick',
                   'Enum nick',
                   'The enum nick for this item.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE)
                ];

use Gtk2::Ex::MenuItem::Subclass;
unshift our @ISA, 'Gtk2::Ex::MenuItem::Subclass';

sub INIT_INSTANCE {
  my ($self) = @_;
  Glib::Ex::ObjectBits::set_property_maybe ($self, draw_as_radio => 1);
}

sub _do_activate {
  my ($self) = @_;
  ### EnumRadio-Item _do_activate()
  $self->signal_chain_from_overridden;

  if ($self->get_active) {
    if (my $menu = $self->get_parent) { # perhaps orphaned during destroy
      foreach my $menuitem ($menu->get_children) {
        if ($menuitem != $self && $menuitem->isa(__PACKAGE__)) {
          $menuitem->set_active(0);
        }
      }
    }
    if (my $menu = $self->parent) {
      $menu->notify('active-nick');
    }
  }
}

1;
__END__

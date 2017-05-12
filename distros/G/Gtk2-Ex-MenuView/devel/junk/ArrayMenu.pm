# Menu of items from an array.

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ArrayMenu;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;

# Version 1 - the first version
#
our $VERSION = 0;


use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::Menu',
  signals => { show => \&_do_show,
               activate => { param_types => ['Glib::Scalar'],
                             return_type => undef },
             },
  properties => [Glib::ParamSpec->scalar
                 ('array',
                  'array',
                  'Array reference of menu items.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('name-proc',
                  'name-proc',
                  'Function to extract item text from array element.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->scalar
                 ('item-proc',
                  'item-proc',
                  'Function to modify a menu item directly.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->boolean
                 ('use-mnemonic',
                  'use-mnemonic',
                  'Whether to use "_" for mnemonics in menu item text.',
                  1,
                  Glib::G_PARAM_READWRITE),
                 ];

sub noop {
  return $_[0];
}

sub _do_activate {
  my ($item, $i) = @_;
  my $self = $item->parent;
  if (DEBUG) { print "$self activate $i\n"; }
  my $array = $self->get('array');
  $self->signal_emit ('activate', $array->[$i]);
}

sub _freshen_items {
  my ($self) = @_;
  my $array = $self->get('array');
  my $name_proc = $self->{'name_proc'} || \&noop;
  my $item_proc = $self->{'item_proc'} || \&noop;
  my $use_mnemonic = $self->get('use-mnemonic');
  my @children = $self->get_children;

  my $i;
  for ($i = 0; $i < @$array; $i++) {
    my $item;
    if ($i < @children) {
      $item = $children[$i]
    } else {
      $item = Gtk2::MenuItem->new_with_label ('');
      $item->signal_connect ('activate', \&_do_activate, $i);
      $self->append ($item);
    }
    my $elem = $array->[$i];
    my $str = $name_proc->($self, $elem);
    my $label = $item->get_child;
    if ($use_mnemonic) {
      $label->set_text_with_mnemonic ($str);
    } else {
      $label->set_text ($str);
    }
    $item->show;

    $item_proc->($self, $item, $elem);
  }

  # hide any excess children
  for ( ; $i < @children; $i++) {
    my $item = $children[$i];
    $item->hide;
  }
}

# 'show' class closure
sub _do_show {
  my ($self) = @_;
  _freshen_items ($self);
  return shift->signal_chain_from_overridden(@_);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  $self->{$pspec->get_name} = $newval;  # per default GET_PROPERTY

  if ($self->visible) {
    _freshen_items ($self);
  }
}

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

1;
__END__

=for stopwords VAxis Eg arraymenu boolean stringize stringizing

=head1 NAME

Gtk2::Ex::ArrayMenu -- menu of items from an array

=for test_synopsis my ($item)

=head1 SYNOPSIS

 use Gtk2::Ex::ArrayMenu;

 my $menu = Gtk2::Ex::ArrayMenu->new (array => ['One', 'Two']);

 # standalone popup
 $menu->popup;

 # or as a submenu
 $item->set_submenu ($menu);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ArrayMenu> is a subclass of C<Gtk2::Menu>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            Gtk2::Ex::ArrayMenu

=head1 DESCRIPTION

A C<Gtk2::Ex::ArrayMenu> presents menu items from a given array of values.
Those values can be strings to show directly, or functions can be set to
form the strings, and make other setups.  A single C<activate> signal on the
C<ArrayMenu> is called for any item activated.

A new array of desired items to show can be set at any time and the number
of items and their contents are changed accordingly.  The work in doing that
is left until the menu is popped up.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::ArrayMenu->new (key=>value,...) >>

Create and return a new VAxis widget.  Optional key/value pairs set initial
properties, as per C<< Glib::Object->new >>.  Eg.

    my $adj = Gtk2::Adjustment->new (5,0,20, 1,8, 10);
    Gtk2::Ex::VAxis->new (adjustment => $adj,
                           decimals => 1);

=back

=head1 SIGNALS

=over 4

=item C<activate>,  parameters (C<$arraymenu>, C<$elem>, C<$userdata>)

Emitted when the user activates one of the items within the arraymenu.  The
corresponding array element is passed as a parameter.

=back

=head1 PROPERTIES

=over 4

=item C<array> (array reference, default empty C<[]>)

Array of items to display.

=item C<use-mnemonic> (boolean, default true)

Whether to interpret underscores "_" in the item names as mnemonics.

=item C<name-proc> (code reference, default C<undef>)

Procedure to call to get the item name from an array element.  The default
C<undef> means to expect the elements to be strings, or to stringize with
C<"$elem"> in the usual way.  Setting a procedure allows some sub-field of
an element to be used.  C<name-proc> is called as

    $str = my_name_proc ($arraymenu, $elem);

So for instance

    sub my_name_proc {
      my ($arraymenu, $elem) = @_;
      return $elem->{'name'};
    }
    $arraymenu->set ('name-proc', \&my_name_proc);

The default stringizing means that if the elements are objects then they can
overload the stringizing operator C<""> (see L<overload>).  But unless
you've want a stringize like that for other purposes it's far clearer to set
a specific C<name-proc> here.

=back

=head1 SEE ALSO

L<Gtk2::Menu>, L<Gtk2::MenuItem>, L<Gtk2::Label>

=cut

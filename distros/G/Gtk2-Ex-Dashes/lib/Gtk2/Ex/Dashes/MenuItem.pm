# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::Dashes::MenuItem;
use 5.008;
use strict;
use warnings;
use Gtk2;

# uncomment this to run the commented-out ### lines
#use Smart::Comments;

our $VERSION = 2;

use Glib::Object::Subclass
  'Gtk2::MenuItem',
  signals => { direction_changed => \&_do_direction_changed };

sub INIT_INSTANCE {
  my ($self) = @_;

  require Gtk2::Ex::Dashes;
  my $dashes = Gtk2::Ex::Dashes->new (visible => 1,
                                      xalign => 0);
  $self->add ($dashes);

  # Is it necessary to set the initial direction, or will the initial be the
  # same for the two widgets anyway?
  ### initial child set_direction
  $self->get_child->set_direction ($self->get_direction);

  # The initial style is just the default, a real style is set later when
  # MenuItem gets into a toplevel tree, so must signal_connect() to set ypad
  # from the real thickness.  Or would a fixed 2 pixels be enough anyway?
  #
  ### initial _ypad_from_style_ythickness
  $dashes->signal_connect (style_set => \&_ypad_from_style_ythickness);
  _ypad_from_style_ythickness ($dashes); # initial setting

  ### done INIT_INSTANCE
}

sub _ypad_from_style_ythickness {
  my ($dashes) = @_;
  ### Dashes-MenuItem _ypad_from_style_ythickness(): $dashes->style->ythickness
  $dashes->set (ypad => $dashes->style->ythickness);
}

# Not certain if it's a great idea to propagate the direction from the
# parent to the child.  If the child is thought of as a display detail it
# makes sense, but not if it's supposed to be independently controlled.
#
sub _do_direction_changed {
  my ($self) = @_;  # ($self, $prev_direction)
  ### Dashes-MenuItem _do_direction_changed(): $self->get_direction
  $self->get_child->set_direction ($self->get_direction);
  return shift->signal_chain_from_overridden(@_);
}

1;
__END__

=head1 NAME

Gtk2::Ex::Dashes::MenuItem -- menu item showing a row of dashes

=for test_synopsis my ($menu)

=head1 SYNOPSIS

 use Gtk2::Ex::Dashes::MenuItem;
 my $item = Gtk2::Ex::Dashes::MenuItem->new;
 $menu->append ($item);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Dashes::MenuItem> is a subclass of C<Gtk2::MenuItem>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Item
            Gtk2::MenuItem
              Gtk2::Ex::Dashes::MenuItem

=head1 DESCRIPTION

A C<Gtk2::Ex::Dashes::MenuItem> displays a line of dashes similar in
appearance to a C<Gtk2::TearoffMenuItem>, but as a plain menu item, not
driving the tearoff state.

    +--------------------------------+
    |                                |
    |  ====  ====  ====  ====  ====  |
    |                                |
    +--------------------------------+

Clicking on the item runs the MenuItem C<activate> handler etc in the usual
way.  Connect to that signal to run an action for the item.  The idea is you
can open a dialog box or toplevel toolbox representing the menu contents,
with more things or more features than just a torn-off menu would provide.

=head1 FUNCTIONS

=over 4

=item C<< $item = Gtk2::Ex::Dashes::MenuItem->new (key=>value,...) >>

Create and return a new C<Dashes::MenuItem> widget.  Optional key/value
pairs can be given to set initial properties, as per
C<< Glib::Object->new >>.

For example setting the C<visible> property saves the usual
C<< $item->show >> needed before adding to a menu.

    my $item = Gtk2::Ex::Dashes::MenuItem->new (visible => 1);

=back

=cut

=head1 PROPERTIES

There are properties beyond what C<Gtk2::MenuItem> offers.

The widget text direction (ie. C<set_direction>) on the C<Dashes::MenuItem>
controls which end the dashes start from.  The effect of this is that a
whole dash begins from the same end as the text (left to right or right to
left).

=head1 SEE ALSO

L<Gtk2::Ex::Dashes>, L<Gtk2::MenuItem>, L<Gtk2::TearoffMenuItem>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-dashes/index.html>

=head1 LICENSE

Gtk2-Ex-Dashes is Copyright 2010 Kevin Ryde

Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Dashes.  If not, see L<http://www.gnu.org/licenses/>.

=cut

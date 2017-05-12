# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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


package Gtk2::Ex::TableBits;
use 5.008;
use strict;
use warnings;
use Scalar::Util 'refaddr';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;

my @attach_pnames = ('left-attach',
                     'right-attach',
                     'top-attach',
                     'bottom-attach',
                     'x-options',
                     'y-options',
                     'x-padding',
                     'y-padding');

sub update_attach {
  my ($table, $child, @args) = @_;
  ### TableBits update_attach: "$child", @args

  if (! _child_is_attached_at($table, $child, @args)) {
    ### must re-attach ...
    if (my $parent = $child->get_parent) {
      $parent->remove ($child);
    }
    $table->attach ($child, @args);
  }
}

# or maybe a func which just checked the attach positions, not the table too
sub _child_is_attached_at {
  my ($table, $child, @args) = @_;
  {
    my $parent = $child->get_parent;
    if (! $parent || refaddr($parent) != refaddr($table)) {
      # parent is not the desired $table
      return 0;
    }
  }
  # Note: compare with "==" operator here, not with "!=".  Glib::Flags
  # "!=" is only in Perl-Gtk2 1.200 and higher.  "x-options" and
  # "y-options" are Gtk2::AttachOptions flags.
  foreach my $pname (@attach_pnames) {
    unless ($table->child_get_property($child,$pname)
            == shift @args) {
      return 0;
    }
  }
  return 1;
}

1;
__END__

=for stopwords Ryde Gtk2-Ex-WidgetBits

=head1 NAME

Gtk2::Ex::TableBits -- helpers for Gtk2::Table widgets

=head1 SYNOPSIS

 use Gtk2::Ex::TableBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::TableBits::update_attach ($table, $child, $left_attach, $right_attach, $top_attach, $bottom_attach, $xoptions, $yoptions, $xpadding, $ypadding) >>

Update the attachment positions of C<$child> in C<$table>, if necessary.
The arguments are the same as C<< $table->attach() >>.

If C<$child> is not attached to C<$table>, or if it's not at the given
positions, then a C<remove()> and fresh C<attach()> are done to put it
there.

This function is designed to move a child to what might be a new position,
but do nothing if it's already in the right place.  Avoiding an unnecessary
C<remove()> and C<attach()> can save a lot of resizing and possibly some
flashing.

Another way to move a child is by changing the container child properties

    $table->child_set_property($child,...)

but only when child is already attached in the correct table (whereas
C<update_attach()> can make an initial attachment or move to a different
C<$table>).

=back

=head1 SEE ALSO

L<Gtk2::Table>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut

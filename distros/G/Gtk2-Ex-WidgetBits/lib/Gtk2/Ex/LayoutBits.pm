# Copyright 2010, 2011, 2012 Kevin Ryde

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

package Gtk2::Ex::LayoutBits;
use 5.008;
use strict;
use warnings;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(move_maybe);

our $VERSION = 48;

# uncomment this to run the ### lines
#use Smart::Comments;

sub move_maybe {
  my ($layout, $child, $x, $y) = @_;
  ### LayoutBits move_maybe()...
  if ($layout->child_get_property($child,'x') != $x
      || $layout->child_get_property($child,'y') != $y) {
    ### move to: "$x,$y"
    $layout->move ($child, $x, $y)
  }
}

1;
__END__

=for stopwords Ryde Gtk Gtk2

=head1 NAME

Gtk2::Ex::LayoutBits -- misc Gtk2::Layout helpers

=head1 SYNOPSIS

 use Gtk2::Ex::LayoutBits;

=head1 FUNCTIONS

=over

=item C<< Gtk2::Ex::LayoutBits::move_maybe ($layout, $child, $x, $y) >>

Move C<$child> to C<$x,$y> in C<$layout> as per C<< $layout->move() >>, if
it's not already at C<$x,$y>.

As of Gtk 2.22 C<< $layout->move() >> or a C<child_set_property()> always
does a C<queue_resize()>.  This function avoids that if the child is already
in the right place.

=back

=head1 SEE ALSO

L<Gtk2::Layout>, L<Gtk2::Ex::WidgetBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

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

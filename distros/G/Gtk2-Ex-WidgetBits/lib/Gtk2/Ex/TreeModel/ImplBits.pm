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


package Gtk2::Ex::TreeModel::ImplBits;
use 5.008;
use strict;
use warnings;
use Gtk2;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = ('random_stamp');

our $VERSION = 48;

sub random_stamp {
  my ($model) = @_;
  if (my $stamp = $model->{'stamp'}) {
    # 1 to 2^31-1, inclusive, and skipping existing $stamp value
    my $new_stamp = 1 + int(rand(2**31 - 2));
    $model->{'stamp'} = $new_stamp + ($new_stamp >= $stamp);
  } else {
    # 1 to 2^31-1, inclusive
    $model->{'stamp'} = 1 + int(rand(2**31 - 1));
  }
}

1;
__END__

=for stopwords TreeModel ImplBits iter gint Gtk2-Ex-WidgetBits TreeStore ListStore Ryde Gtk2::TreeModel Gtk2::Ex::TreeModel::ImplBits Perl-Gtk iters

=head1 NAME

Gtk2::Ex::TreeModel::ImplBits - miscellaneous helpers for TreeModel implementations

=head1 SYNOPSIS

 use Gtk2::Ex::TreeModel::ImplBits;

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::TreeModel::ImplBits::random_stamp ($model) >>

Set C<< $model->{'stamp'} >> to a randomly chosen stamp (an integer) between
1 and 2**31-1 inclusive.  If C<< $model->{'stamp'} >> is an existing stamp
value then that's excluded, ensuring a new value.

This is designed to pick a stamp in the C<INIT_INSTANCE> of a TreeModel
object,

    use Gtk2::Ex::TreeModel::ImplBits;

    sub INIT_INSTANCE {
      my ($self) = @_;
      Gtk2::Ex::TreeModel::ImplBits::random_stamp ($self);
      # ...
    }

and also later to change stamp to deliberately invalidate iters an
application might still have.  This can be when the last row is deleted, so
no iter can possibly be valid, or when the model is not C<iters-persist> and
a delete, insert or reorder has moved memory etc rendering existing iter
pointers or references invalid.

Zero is not used for a stamp because it's what ListStore and TreeStore
C<remove> set to invalidate an iter when no next row.  Negatives are not
used because Perl-Gtk 1.220 on a system with 64-bit IV and 32-bit gint will
sometimes zero extend (instead of sign extend), giving back a positive
value.  In the future though it might be possible to use negatives, or a
full 64-bit gint on a 64-bit system.

C<Gtk2::TreeStore> uses a similar randomly chosen stamp.  With a random
stamp there's a small chance an iter misuse will be undetected because
stamps happen to match.  But this will be extremely rare, and randomness has
the considerable advantage that it won't be systematically tricked by
something semi-deterministic like uninitialized or re-used memory.

=back

=head1 EXPORTS

Nothing is exported by default, but C<random_stamp> can be requested in
usual C<Exporter> style,

    use Gtk2::Ex::TreeModel::ImplBits 'random_stamp';

    sub remove {
      my ($self, $iter) = @_;
      # ...
      if (have_become_empty) {
        # no iter can be valid, new stamp to enforce that
        random_stamp ($self);
      }
    }

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import yet unknown names would be asking for trouble!

=head1 SEE ALSO

L<Gtk2::TreeModel>, L<Gtk2::Ex::WidgetBits>, L<Exporter>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2009, 2010, 2011, 2012 Kevin Ryde

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

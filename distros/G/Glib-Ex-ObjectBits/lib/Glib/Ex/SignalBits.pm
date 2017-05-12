# Copyright 2009, 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::SignalBits;
use 5.008;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(accumulator_first
                    accumulator_first_defined);

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 16;

sub accumulator_first {
  my ($hint, $acc, $ret) = @_;
  ### accumulator_first(): $acc,$ret
  return (0,     # flag, false don't continue emission
          $ret); # retval
}

sub accumulator_first_defined {
  my ($hint, $acc, $ret) = @_;
  ### accumulator_first_defined(): $acc,$ret
  return (! defined $ret,  # flag, true to continue if $ret is undef
          $ret);           # retval
}

# # signal accumulator returning first true value from handler
# sub accumulator_first_true {
#   my ($hint, $acc, $ret) = @_;
#   ### _accumulator_first_true: [$acc,$ret]
#   return (! $ret,  # flag, true to continue if no $ret item
#           $ret);   # retval
# }
# 
# =item C<< Glib::Ex::SignalBits::accumulator_first_true ($hint, $acc, $ret) >>
# 
# Accumulator stopping at and returning the first true value (true in the Perl
# boolean sense) from the handlers.

1;
__END__

=for stopwords Glib-Ex-ObjectBits Ryde Perl-Glib

=head1 NAME

Glib::Ex::SignalBits -- miscellaneous Glib signal helpers

=head1 SYNOPSIS

 use Glib::Ex::SignalBits;

=head1 FUNCTIONS

=head2 Accumulators

The following functions are designed for use as the "accumulator" in a
signal created by C<Glib::Object::Subclass> or
C<< Glib::Type->register_object() >>.  The functions are trivial, but giving
them names gets the right sense and order for the return values.

=over 4

=item C<< ($cont, $ret) = Glib::Ex::SignalBits::accumulator_first ($hint, $acc, $ret) >>

Stop at and return the value from the first handler.

=item C<< ($cont, $ret) = Glib::Ex::SignalBits::accumulator_first_defined ($hint, $acc, $ret) >>

Stop at and return the first C<defined> value, in the Perl sense.  This
means the first non-NULL C<Glib::Object>, C<Glib::String>, etc, or first
non-C<undef> C<Glib::Scalar>.

=back

=head3 Example

    use Glib::Object::Subclass
      'Gtk2::Widget',
      signals => {
        'make-title' => {
          param_types   => ['Glib::Int'],
          return_type   => 'Glib::String',
          flags         => ['run-last'],
          class_closure => \&my_default_make_title,
          accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
        },
      };

Don't forget to C<use Glib::Ex::SignalBits> because a non-existent function
in a signal accumulator will cause an C<abort()> from Perl-Glib (as of
version 1.220).

=head1 EXPORTS

Nothing is exported by default, but each function can be requested in usual
C<Exporter> style,

    use Glib::Ex::SignalBits 'accumulator_first';
    
    use Glib::Object::Subclass
      ... accumulator => \&accumulator_first

=head1 SEE ALSO

L<Glib::Object>,
L<Glib::Object::Subclass>,
L<Glib::Signal>,
L<Glib::Ex::SignalIds>,
L<Glib::Ex::FreezeNotify>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2009, 2010, 2011, 2012, 2014 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut

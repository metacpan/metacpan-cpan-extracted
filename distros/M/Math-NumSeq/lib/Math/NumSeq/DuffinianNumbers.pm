# Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::DuffinianNumbers;
use 5.004;
use strict;
use List::Util 'sum';
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::Factor::XS 0.40 'factors'; # version 0.40 for factors() on BigInt


use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
use List::Util 'min';
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Duffinian Numbers');
use constant description => Math::NumSeq::__('Duffinian numbers.');
use constant i_start => 1;

use constant values_min => 4;

#------------------------------------------------------------------------------

use constant oeis_anum => 'A003624';


#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### DuffinianNumbers pred(): $value

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value < 2 || $value != int($value)) {
    return 0;
  }
  if ($value > 0xFFFF_FFFF) {
    return undef;
  }
  $value = "$value"; # numize any Math::BigInt for speed

  return ! is_prime($value)
    && _coprime($value, sum(1,factors($value)));
}

# return true if coprime
sub _coprime {
  my ($x, $y) = @_;
  ### _coprime(): "$x,$y"

  if ($y > $x) {
    ($x,$y) = ($y,$x);
  }
  for (;;) {
    if ($y <= 1) {
      ### result: ($y == 1)
      return ($y == 1);
    }
    ($x,$y) = ($y, $x % $y);
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq Duffinian

=head1 NAME

Math::NumSeq::DuffinianNumbers -- no common factor with sum of divisors

=head1 SYNOPSIS

 use Math::NumSeq::DuffinianNumbers;
 my $seq = Math::NumSeq::DuffinianNumbers->new ();
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the Duffinian numbers which are composites having no common factor
with their sum of divisors.

    4, 8, 9, 16, 21, 25, 27, 32, 35, 36, 39, 49, 50, 55, 57, 63, ...
    starting i=1

For example 21 has divisors 1,3,7,21 total 32 which has no common factor
with 21.  Only composites are included since primes would not be
particularly interesting for this rule.  They'd having only divisors 1,p and
so p+1 never having a common factor with p.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DuffinianNumbers-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Duffinian number.

In the current code a hard limit of 2**32 is placed on the C<$value> to be
checked, in the interests of not going into a near-infinite loop.  The
return is C<undef> for bigger values.

=back

=head1 SEE ALSO

L<Math::NumSeq>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut

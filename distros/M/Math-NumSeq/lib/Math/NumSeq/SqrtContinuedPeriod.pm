# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::SqrtContinuedPeriod;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Sqrt Continued Fraction Period');
use constant description => Math::NumSeq::__('Period of the continued fraction expansion of sqrt(i), or 0 for perfect squares (where the expansion is finite)');
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant default_i_start => 1;
use constant values_min => 0;

# cf A097853 contfrac sqrt(n) period, or 1 if square
#    A054269 contfrac sqrt(prime(i)) period
#
use constant oeis_anum => 'A003285';  # sqrt period, or 0 if square

sub ith {
  my ($self, $i) = @_;
  ### SqrtContinuedPeriod ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  if ($i <= 0) {
    return 0;
  }

  # initial a[1] = floor(sqrt(i)) = $root
  # then root + 1/x = sqrt(i)
  #      1/x = sqrt(i)-root
  #      x = 1/(sqrt(i)-root)
  #      x = (sqrt(i)+root)/(i-root*root)
  # so P = root
  #    Q = i - root*root
  #
  my $p = my $root = int(sqrt($i));
  my $q = $i - $root*$root;
  if ($q <= 0) {
    # perfect square
    return 0;
  }

  my %seen;
  my $count = 0;
  for (;;) {
    if ($seen{"$p,$q"}++) {
      return $count;
    }
    $count++;

    my $value = int (($root + $p) / $q);
    $p -= $value*$q;
    ($p, $q) = (-$p,
                ($i - $p*$p) / $q);

    ### assert: $p >= 0
    ### assert: $q > 0
    ### assert: $p <= $root
    ### assert: $q <= 2*$root+1
    ### assert: (($p*$p - $i) % $q) == 0
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq BigInt

=head1 NAME

Math::NumSeq::SqrtContinuedPeriod -- period of the continued fraction for sqrt(i)

=head1 SYNOPSIS

 use Math::NumSeq::SqrtContinuedPeriod;
 my $seq = Math::NumSeq::SqrtContinuedPeriod->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This the period of the repeating part of the continued fraction expansion of
sqrt(i).

    0, 1, 2, 0, 1, 2, 4, 2, etc

For example sqrt(12) is 3 then terms 2,6 repeating, which is period 2.

                    1   
   sqrt(12) = 3 + ----------- 
                  2 +   1
                      -----------
                      6 +   1
                          ----------
                          2 +   1
                              ---------
                              6 + ...        2,6 repeating

All square root continued fractions like this comprise an integer part
followed by repeating terms of some length.  Perfect squares are an integer
part only, nothing further, and the period for them is taken to be 0.

The continued fraction calculation has denominator value at each stage of
the form

   den =(P+sqrt(S)) / Q

   with

   0 <= P <= root
   0 < Q <= 2*root+1
   where root=floor(sqrt(S))

The limited range of P,Q means a finite set of combinations at most
root*(2*root+1), which is roughly 2*S.  In practice it's much less.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SqrtContinuedPeriod-E<gt>new (sqrt =E<gt> $s)>

Create and return a new sequence object giving the Continued expansion terms of
C<sqrt($s)>.

=item C<$value = $seq-E<gt>ith ($i)>

Return the period of sqrt($i).

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::SqrtContinued>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::TotientStepsSum;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Totient 13;
*_totient = \&Math::NumSeq::Totient::_totient;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('Totient Steps Sum');
use constant description => Math::NumSeq::__('Sum of totients repeatedly applying until reach 1.');
use constant characteristic_increasing => 0;
use constant characteristic_integer => 1;
use constant i_start => 1;
use constant parameter_info_array =>
  [ { name        => 'including_self',
      type        => 'boolean',
      display     => Math::NumSeq::__('Incl Self'),
      default     => 1,
      description => Math::NumSeq::__('Whether to include N itself in the sum.'),
    },
  ];
sub values_min {
  my ($self) = @_;
  return ($self->{'including_self'} ? 1 : 0);
}


# OEIS-Catalogue: A053478 including_self=1
# OEIS-Catalogue: A092693 including_self=0
sub oeis_anum {
  my ($self) = @_;
  return ($self->{'including_self'} ? 'A053478' : 'A092693');
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub next {
  my ($self) = @_;

  my $i = $self->{'i'}++;
  my $sum = ($self->{'including_self'} ? $i : 0);
  my $v = $i;
  while ($v > 1) {
    $sum += ($v = _totient($v));
  }
  return ($i, $sum);
}

sub ith {
  my ($self, $i) = @_;

  if (_is_infinite($i)) {
    return $i;
  }

  my ($good, @primes) = _prime_factors($i);
  return undef unless $good;

  my %primes;
  foreach my $p (@primes) {
    $primes{$p}++;
  }

  my %factors;
  my $sum = ($self->{'including_self'} ? $i : $i*0);
  while (%primes) {
    ### %primes

    my %next;
    while (my ($p, $e) = each %primes) {
      if (--$e) {
        $next{$p} += $e;
      }
      ($good, @primes) = _prime_factors($p-1);
      return undef unless $good;

      foreach my $f (@{ $factors{$p} ||= [ @primes ] }) {
        $next{$f}++;
      }
    }

    my $next_value = 1;
    while (my ($p, $e) = each %next) {
      $next_value *= $p ** $e;
    }
    $sum += $next_value;

    %primes = %next;
  }
  ### final sum: $sum

  return $sum;
}

1;
__END__

=for stopwords Ryde Math-NumSeq totient totients

=head1 NAME

Math::NumSeq::TotientStepsSum -- sum of repeated totients to reach 1

=head1 SYNOPSIS

 use Math::NumSeq::TotientStepsSum;
 my $seq = Math::NumSeq::TotientStepsSum->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sum of the totients on repeatedly applying the totient function to
reach 1.

    1, 3, 6, 7, 12, 9, 16, 15, 18, 17, 28, 19, 32, ...

For example i=5 applying the totient function goes 5 -E<gt> 4 -E<gt> 2
-E<gt> 1 so total value=5+4+2+1=12.

The default is to include the initial i itself in the sum.  Option
C<including_self =E<gt> 0> excludes, in which case for example i=5 has
value=4+2+1=7.

    0, 1, 3, 3, 7, 3, 9, 7, 9, 7, 17, 7, 19, ...

See L<Math::NumSeq::TotientPerfect> for totient sums equal to i itself.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::TotientStepsSum-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the totient steps sum running i down to 1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Totient>,
L<Math::NumSeq::TotientSteps>,
L<Math::NumSeq::TotientPerfect>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

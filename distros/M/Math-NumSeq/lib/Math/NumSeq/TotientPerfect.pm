# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::TotientPerfect;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Totient;
*_totient = \&Math::NumSeq::Totient::_totient;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Totient Perfect Numbers');
use constant description => Math::NumSeq::__('Numbers for which the sum of repeated applications of the totient function equals N.  Eg. 9 is perfect because phi(9)=6, phi(6)=2, phi(2)=1 and the sum 6+2+1 = 9.');

use constant values_min => 3;
use constant i_start => 1;
use constant oeis_anum => 'A082897';


sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'upto'} = 1;
}
sub next {
  my ($self) = @_;

 OUTER: for (;;) {
    my $value = ($self->{'upto'} += 2);

    my $sum = my $p = _totient($value);
    while ($p > 1) {
      $sum += ($p = _totient($p));
      if ($sum > $value) {
        next OUTER;
      }
    }
    if ($sum == $value) {
      return ($self->{'i'}++, $value);
    }
  }
}


sub pred {
  my ($self, $value) = @_;

  if ($value < $self->values_min
      || _is_infinite($value)
      || ($value % 2) == 0) {  # even numbers not perfect
    return 0;
  }
  if ($value < 0) {
    return undef;
  }

  my ($good, @primes) = _prime_factors($value);
  return undef unless $good;

  my %primes;
  foreach my $p (@primes) {
    $primes{$p}++;
  }

  my %factors;
  my $sum = 0;
  while (%primes) {
    ### %primes

    my %next;
    while (my ($p, $e) = each %primes) {
      if (--$e) {
        $next{$p} += $e;
      }
      my $factors_aref = ($factors{$p} ||= do {
        my ($good, @primes) = _prime_factors($p-1);
        return undef unless $good;
        \@primes
      });
      foreach my $f (@$factors_aref) {
        $next{$f}++;
      }
    }

    my $next_value = 1;
    while (my ($p, $e) = each %next) {
      $next_value *= $p ** $e;
    }
    $sum += $next_value;
    last unless $sum < $value;

    %primes = %next;
  }
  ### final sum: $sum

  return ($sum == $value);
}



1;
__END__

=for stopwords Ryde Math-NumSeq totient totients

=head1 NAME

Math::NumSeq::TotientPerfect -- sum of repeated totients is N itself

=head1 SYNOPSIS

 use Math::NumSeq::TotientPerfect;
 my $seq = Math::NumSeq::TotientPerfect->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

Numbers for which the sum of repeated totients until reaching 1 gives the
starting n itself.

    3, 9, 15, 27, 39, 81, 111, 183, 243, 255, ...

For example totient(15)=8, totient(8)=4, totient(4)=2 and totient(1)=1.
Adding them up 8+4+2+1=15 so 15 is a perfect totient.

The current implementation of C<next()> is merely a search by C<pred()>
through all odd integers, which isn't very fast.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::TotientPerfect-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a perfect totient.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Totient>,
L<Math::NumSeq::TotientSteps>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::TwinPrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('Twin Primes');
use constant description => Math::NumSeq::__('The twin primes, 3, 5, 7, 11, 13, being integers where both K and K+2 are primes.');
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant parameter_info_array =>
  [
   { name    => 'pairs',
     display => Math::NumSeq::__('Pairs'),
     type    => 'enum',
     default => 'first',
     choices => ['first','second','both','average'],
     choices_display => [Math::NumSeq::__('First'),
                         Math::NumSeq::__('Second'),
                         Math::NumSeq::__('Both'),
                         Math::NumSeq::__('Average')],
     description => Math::NumSeq::__('Which of a pair of values to show.'),
   },
  ];

my %values_min = (first   => 3,
                  second  => 5,
                  both    => 3,
                  average => 4);
sub values_min {
  my ($self) = @_;
  return $values_min{$self->{'pairs'}};
}

#------------------------------------------------------------------------------
# cf A077800 - both, with repetition, so 3,5, 5,7, 11,13, ...
#    A040040 - average/2 since the average is always even
#    A054735 - sum twin primes (OFFSET=1)
#    A111046 - p^2 - q^2
#    A167777 - even "isolated" numbers, 2 plus twin primes average
#    A129297 - m s.t. m^2-1 no no divisors 1<d<m-1, twin average plus 0..3
#
#    A067774 - primes where p+2 not prime
#    A063637 - primes where p+2 is a semiprime
#
#    A048598 - cumulative total twin primes
#    A100923 - characteristic 0,1 according to 6n+/-1 both primes
#              ie. twin prime 6n-1,6n+1
#
my %oeis_anum = (
                 first  => 'A001359',
                 # OEIS-Catalogue: A001359 pairs=first

                 second => 'A006512',
                 # OEIS-Catalogue: A006512 pairs=second

                 both   => 'A001097', # both, without repetition
                 # OEIS-Catalogue: A001097 pairs=both

                 average => 'A014574', # average
                 # OEIS-Catalogue: A014574 pairs=average
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'pairs'}};
}

#------------------------------------------------------------------------------

my %pairs_add = (first => 0,
                 average => 1,
                 second => 2,
                 both => 0);

sub rewind {
  my ($self) = @_;
  ### TwinPrimes rewind() ...

  $self->{'i'} = $self->i_start;
  my $primes_seq = $self->{'primes_seq'} = Math::NumSeq::Primes->new;
  $self->{'twin_both'} = 0;
  (undef, $self->{'twin_prev'}) = $primes_seq->next;
}

sub next {
  my ($self) = @_;
  ### TwinPrimes next(): "i=$self->{'i'} prev=$self->{'twin_prev'}"

  my $prev = $self->{'twin_prev'};
  my $primes_seq = $self->{'primes_seq'};

  for (;;) {
    (undef, my $prime) = $primes_seq->next
      or return;

    if ($prime == $prev + 2) {
      my $pairs = $self->{'pairs'};
      $self->{'twin_prev'} = $prime;
      $self->{'twin_both'} = ($pairs eq 'both');
      return ($self->{'i'}++, $prev + $pairs_add{$pairs});

    } elsif ($self->{'twin_both'}) {
      $self->{'twin_prev'} = $prime;
      $self->{'twin_both'} = 0;
      return ($self->{'i'}++, $prev);
    }
    $prev = $prime;
  }
}


# ENHANCE-ME: are_all_prime() to look for small divisors in both values
# simultaneously, in case the reversal is even etc and easily excluded.
#
my %pairs_other = (first => 2,
                   average => 1,
                   second => 0);
my %pairs_mod = (first => 5,
                 average => 0,
                 second => 1);
sub pred {
  my ($self, $value) = @_;
  if ((my $pairs = $self->{'pairs'}) eq 'both') {
    return ($self->Math::NumSeq::Primes::pred ($value)
            && ($self->Math::NumSeq::Primes::pred ($value + 2)
                || $self->Math::NumSeq::Primes::pred ($value - 2)));
  } else {
    # pairs are always 3n-1,3n+1 since otherwise one of them would be a 3n
    # and also both odd so 6n-1,6n+1
    if (my $mod = $pairs_mod{$pairs}) {
      if ($value >= 6 && ($value % 6) != $mod) {
        return 0;
      }
    }
    return ($self->Math::NumSeq::Primes::pred ($value - $pairs_add{$pairs})
            && $self->Math::NumSeq::Primes::pred ($value + $pairs_other{$pairs}));
  }
}

# Hardy and Littlewood conjecture, then
#     pi2(x) -> x / (ln x)^2
#
# Brun upper bound
#     pi2(x) <= const * C2 * x/(ln x)^2 * (1 + O(ln ln x / ln x))
#     with const < 68/9 ~= 7.55
#
#                   x
# pi2(x) ~ 2*C2 * integral  1/(ln x)^2 dx
#                   2
#
# cf pi2(x) ~ 2*C2 * pi(x)^2 / x
#
# integral 1/(ln x)^2 = li(x) - x/ln(x)
#          li(x) = int 1/ln(x)
#

# C2 = product (1 - 1/(p-1)^2) for all primes p>2
#
use constant 1.02 _TWIN_PRIME_CONSTANT => 0.6601618158;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate(): $value

  if ($value < 2) { return 0; }

  $value = int($value);
  if (defined (my $blog2 = _blog2_estimate($value))) {
    # est = v/(log(v)^2) * 2*tpc
    # log2(v) = log(v)/log(2)
    # est = v/((log2(v)^2 * log(2)^2)) * 2*tpc
    #     = v/(log2(v)^2) * 2*tpc/(log(2)^2) 
    #    ~= v/(log2(v)^2) * 11/4
    # using 11/4 as an approximation to 2*tpc/(log(2)^2) to stay in BigInt
    #
    ### $blog2
    ### num: $value*13
    ### den: 9 * $blog2
    return ($value * 11) / (4 * $blog2 * $blog2);
  }

  my $log = log($value);
  return int($value / ($log*$log) * (2 * _TWIN_PRIME_CONSTANT));
}
1;
__END__

=for stopwords Ryde Math-NumSeq ie Brun Littlewood's

=head1 NAME

Math::NumSeq::TwinPrimes -- twin primes

=head1 SYNOPSIS

 use Math::NumSeq::TwinPrimes;
 my $seq = Math::NumSeq::TwinPrimes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The twin primes 3, 5, 11, 19, 29, etc, where both P and P+2 are primes.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::TwinPrimes-E<gt>new ()>

=item C<$seq = Math::NumSeq::TwinPrimes-E<gt>new (pairs =E<gt> 'second')>

Create and return a new sequence object.  The optional C<pairs> parameter (a
string) controls which of each twin-prime pair of values is returned

    "first"      the first of each pair, 3,5,11,17 etc
    "second"     the second of each pair 5,7,13,19 etc
    "both"       both values 3,5,7,11,13,17,19 etc
    "average"    the average of the pair, 4,6,12,8 etc

"both" is without repetition, so for example 5 belongs to the pair 3,5 and
5,7, but is returned in the sequence just once.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a twin prime of the given C<pairs> type.  For
example with "second" C<pred()> returns true when C<$value> is the second of
a pair, ie. C<$value-2> is also a prime.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  Currently this is
the asymptotic by Brun

                     value
    i ~= 2 * C * --------------
                 (log(value))^2

with Hardy and Littlewood's conjectured twin-prime constant C=0.66016.  In
practice it's quite close, being too small by a factor between 0.75 and 0.85
in the small to medium size integers this module might calculate.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::SophieGermainPrimes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

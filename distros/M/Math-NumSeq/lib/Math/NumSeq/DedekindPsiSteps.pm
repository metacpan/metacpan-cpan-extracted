# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::DedekindPsiSteps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Dedekind Psi Steps');
use constant description => Math::NumSeq::__('Number of repeated applications of the Dedekind psi function to reach factors 2 and 3 only.');
use constant default_i_start => 1;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant values_min => 0;

# A001615 dedekind psi
# A019268 dedekind psi first requiring n steps
# A019269 number of steps
# A173290 dedekind psi cumulative
#
use constant oeis_anum => 'A019269';

sub ith {
  my ($self, $i) = @_;
  ### DedekindPsiSteps ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  if ($i < 0) {
    return undef;
  }

  my ($good, @primes) = _prime_factors($i);
  return undef unless $good;

  my %primes;
  foreach my $p (@primes) {
    $primes{$p}++;
  }
  my $count = 0;

  my %prime_factors;
  for (;;) {
    delete $primes{'2'};
    delete $primes{'3'};
    last unless %primes;

    ### %primes
    $count++;
    my %next_primes;
    while (my ($p, $e) = each %primes) {
      if (--$e) {
        $next_primes{$p} += $e;
      }
      my $prime_factors_aref = ($prime_factors{$p} ||= do {
        my ($good, @primes) = _prime_factors($p+1);
        return undef unless $good;
        \@primes
      });
      foreach my $f (@$prime_factors_aref) {
        $next_primes{$f}++;
      }
    }
    %primes = %next_primes;
  }
  return $count;
}

# sub _psi_ex23 {
#   my ($n) = @_;
#   ### _psi(): $n
# 
#   my $prev = 0;
#   my $ret = 1;
#   foreach my $p (prime_factors($n)) {
#     next if $p == 2 || $p == 3;
#     if ($p == $prev) {
#       $ret *= $p;
#     } else {
#       $ret *= $p+1;
#       $prev = $p;
#     }
#   }
#   return $ret;
# 
#   # my %primes;
#   # @primes{prime_factors($n)} = (); # hash slice
#   # delete $primes{2,3}; # hash slice
#   # foreach my $p (keys %primes) {
#   #   $n /= $p;
#   #   $n *= $p+1;
#   # }
#   return $n;
# }

# sub _is_2x3y {
#   my ($n) = @_;
#   until ($n % 2) {
#     $n = int($n/2);
#   }
#   until ($n % 3) {
#     $n = int($n/3);
#   }
#   return ($n == 1);
# }

1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::DedekindPsiSteps -- psi function until 2^x*3^y

=head1 SYNOPSIS

 use Math::NumSeq::DedekindPsiSteps;
 my $seq = Math::NumSeq::DedekindPsiSteps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is the how many repeated applications of the Dedekind psi
function are required to reach a number of the form 2^x*3^y.

    0,0,0,0,1,0,1,0,0,1,1,0,2,1,1,0,1,0,2,1,1,1,1,0,2,2,0,1,2,...

The psi function is

    psi(n) =        product          (p+1) * p^(e-1)
             prime factors p^e in n

The p+1 means that one copy of each distinct prime in n is changed from p to
p+1.  That p+1 is even, so although the value has increased the prime
factors are all less than p.  Repeated applying that reduction eventually
reaches just primes 2 and 3 in some quantity.

For example i=25 requires 2 steps,

    psi(25) = (5+1)*5 = 30 = 2*3*5
    then
    psi(30) = (2+1)*(3+1)*(5+1) = 72 = 2*2*2*3*3

If i is already 2s and 3s then it's considered no steps are required and the
value is 0.  For example at i=12=2*2*3 the value is 0.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DedekindPsiSteps-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of repeated applications of the psi function on C<$i>
required to reach just factors 2 and 3.

This calculation requires factorizing C<$i> and in the current code after
small factors a hard limit of 2**32 is enforced in the interests of not
going into a near-infinite loop.  Above that the return is C<undef>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::TotientSteps>,
L<Math::NumSeq::DedekindPsiCumulative>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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

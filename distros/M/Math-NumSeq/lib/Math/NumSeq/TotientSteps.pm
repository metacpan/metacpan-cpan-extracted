# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020, 2021 Kevin Ryde

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

package Math::NumSeq::TotientSteps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Totient;
*_totient = \&Math::NumSeq::Totient::_totient;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('Totient Steps');
use constant description => Math::NumSeq::__('Number of repeated applications of the totient function to reach 1.');
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant values_min => 0; # at i=1
use constant i_start => 1;
use constant oeis_anum => 'A003434';



sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub next {
  my ($self) = @_;

  my $v = my $i = $self->{'i'}++;
  my $count = 0;
  for (;;) {
    if ($v <= 1) {
      return ($i, $count);
    }
    $v = _totient($v);
    $count++;
  }
}


sub ith {
  my ($self, $i) = @_;
  ### TotientSteps ith(): $i

  if ($i < 0) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  my ($good, @primes) = _prime_factors($i);
  return undef unless $good;

  my %primes;
  foreach my $p (@primes) {
    $primes{$p}++;
  }

  my %prime_factors;
  my $count = 0;
  while (%primes) {
    ### %primes
    $count++;

    my %next;
    while (my ($p, $e) = each %primes) {
      if (--$e) {
        $next{$p} += $e;
      }
      my $prime_factors_aref = ($prime_factors{$p} ||= do {
        my ($good, @primes) = _prime_factors($p-1);
        return undef unless $good;
        \@primes
      });
      foreach my $f (@$prime_factors_aref) {
        $next{$f}++;
      }
    }

    %primes = %next;
  }
  return $count;
}

sub pred {
  my ($self, $value) = @_;
  return ($value==int($value) && $value >= values_min());
}

1;
__END__

=for stopwords Ryde Math-NumSeq totient totients

=head1 NAME

Math::NumSeq::TotientSteps -- count of repeated totients to reach 1

=head1 SYNOPSIS

 use Math::NumSeq::TotientSteps;
 my $seq = Math::NumSeq::TotientSteps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

How many repeated applications of the totient function to reach 1, so from
i=1

    0, 1, 2, 2, 3, 2, 3, 3, 3, 3, 4, 3, 4, ...

For example i=5 goes 5 -E<gt> 4 -E<gt> 2 -E<gt> 1 so value=3 steps.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::TotientSteps-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the count of totient(i) steps to get down to 1.

=item C<$value = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which simply means a count
C<$value E<gt>= 0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Totient>,
L<Math::NumSeq::TotientStepsSum>,
L<Math::NumSeq::DedekindPsiSteps>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020, 2021 Kevin Ryde

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

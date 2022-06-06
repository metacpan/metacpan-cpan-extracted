# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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


# cf
# http://mathworld.wolfram.com/dePolignacsConjecture.html
#   consecutive primes difference is every even number infinitely many times

# 1,
# 127, 149, 251, 331,
# 337, 373, 509, 599,
# 701, 757, 809, 877,
# 905, 907, 959, 977,
# 997, 

package Math::NumSeq::PolignacObstinate;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Primes; # for primes_list()
use Math::Prime::XS 'is_prime';

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Polignac Obstinate');
use constant description => Math::NumSeq::__('Odd integers N not representable as prime+2^k.');
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant i_start => 1;

# cf A133122 - demanding k>0, so 1,3,127,... as 3 no longer representable
#    A065381 - primes not p+2^k k>=0, filtering from odds to primes
#    
use constant oeis_anum => 'A006285'; # with k>=0 so 1,127,...


sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'string'} = '';
  vec($self->{'string'},3/2,1) = 1;  # 2+2^0=3
  $self->{'done'} = -1;
  _resieve ($self, 20);
}

sub _resieve {
  my ($self, $hi) = @_;
  ### _resieve() ...

  $self->{'hi'} = $hi;
  my $sref = \$self->{'string'};
  vec($$sref,$hi,1) = 0;  # pre-extend
  my @primes = Math::NumSeq::Primes::_primes_list (3, $hi-1);
  for (my $power = 2; $power < $hi; $power *= 2) {
    foreach my $p (@primes) {
      if ((my $v = $p + $power) > $hi) {
        last;
      } else {
        vec($$sref,$v/2,1) = 1;
      }
    }
  }
}

sub next {
  my ($self) = @_;
  ### Obstinate next(): $self->{'i'}

  my $v = $self->{'done'};
  my $sref = \$self->{'string'};
  my $hi = $self->{'hi'};

  for (;;) {
    ### consider: "v=".($v+1)."  cf done=$self->{'done'}"
    if (($v+=2) > $hi) {
      _resieve ($self,
                $hi = ($self->{'hi'} *= 2));
    }
    unless (vec($$sref,$v/2,1)) {
      return ($self->{'i'}++,
              $self->{'done'} = $v);
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  ### Obstinate pred(): $value

  unless ($value >= 0 && $value <= 0xFFFF_FFFF) {
    return undef;
  }
  if ($value != int($value)
      || $value < 127
      || ($value % 2) == 0) {
    return ($value == 1);
  }
  $value = "$value"; # numize Math::BigInt for speed

  # Maybe an is_any_prime(...)
  for (my $power = 2; $power < $value; $power *= 2) {
    if (is_prime($value - $power)) {
      return 0;
    }
  }
  return 1;
}

1;
__END__

=for stopwords Ryde Math-NumSeq de Polignac Erdos Pickover ie

=head1 NAME

Math::NumSeq::PolignacObstinate -- odd integers not prime+2^k

=head1 SYNOPSIS

 use Math::NumSeq::PolignacObstinate;
 my $seq = Math::NumSeq::PolignacObstinate->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This sequence is integers which cannot be represented as prime+2^k for an
integer k.  These are counter-examples to a conjecture by Prince de Polignac
that every odd integer occurs as prime+2^k (and are called "obstinate"
numbers by Andy Edwards).

    1, 127, 149, 251, 331, 337, ...

For example 149 is obstinate because it cannot be written as prime+2^k.
Working backwards, it can be seen that none of 149-1, 149-2, 149-4, 149-8,
... 149-128 are primes.

A theorem by Erdos gives infinitely many such obstinate integers (in an
arithmetic progression).

The value 3 is not in the sequence because it can be written prime+2^k, for
prime=2 and k=0.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PolignacObstinate-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is obstinate, ie. that there's no C<$k E<gt>= 0>
for which C<$value - 2**$k> is a prime.

This check requires prime testing up to C<$value> and in the current code a
hard limit of 2**32 is placed on the C<$value> to be checked, in the
interests of not going into a near-infinite loop.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>

Clifford Pickover, "The Grand Internet Obstinate Number Search"

=over

L<http://sprott.physics.wisc.edu/pickover/obstinate.html>

=back

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

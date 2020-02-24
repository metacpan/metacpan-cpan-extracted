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

package Math::NumSeq::SafePrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq::Primes');

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Safe Primes');
use constant description => Math::NumSeq::__('The safe primes 5,7,11,23,47, being primes where (P-1)/2 is also prime (those are the Sophie Germain primes).');
use constant values_min => 5;
use constant characteristic_increasing => 1;
use constant oeis_anum => 'A005385';

sub rewind {
  my ($self) = @_;
  $self->SUPER::rewind;
  $self->{'safe_i'} = 0;
  $self->{'safe_bseq'} = Math::NumSeq::Primes->new;
}

sub next {
  my ($self) = @_;

  my $bseq = $self->{'safe_bseq'};
  my $behind = 0;
  for (;;) {
    (undef, my $prime) = $self->SUPER::next
      or return;

    my $target = ($prime-1)/2;
    while ($behind < $target) {
      (undef, $behind) = $bseq->next
        or return;
    }
    if ($behind == $target) {
      return (++$self->{'safe_i'}, $prime);
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  return (($value & 1)
          && $self->Math::NumSeq::Primes::pred ($value)
          && $self->Math::NumSeq::Primes::pred (($value-1)/2));
}

1;
__END__

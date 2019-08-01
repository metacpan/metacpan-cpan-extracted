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


package Math::NumSeq::LuckyNumbersSlow;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 73;

use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Lucky Numbers');
use constant description => Math::NumSeq::__('Sieved out multiples according to the sequence itself.');
use constant values_min => 1;
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf A145649 - 0,1 characteristic of Lucky numbers
#    A050505 - complement, the non-Lucky numbers
#
#    A007951 - ternary sieve, dropping 3rd, 6th, 9th, etc
#    1,2,_,4,5,_,7,8,_,10,11,_,12,13,_,14,15,_
#                              ^9th
#    1,2,4,5,7,8,10,11,14,16,17,19,20,22,23,25,28,29,31,32,34,35,37,38,41,     

use constant oeis_anum => 'A000959';

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'value'} = -1;
  $self->{'count'} = [ 3 ];
  $self->{'remaining'}  = [ 3 ];
}

# ENHANCE-ME: Defer pushing each value only the count array until needed.
# Might keep array size down to i/log(i) instead of i.
#
sub next {
  my ($self) = @_;
  ### LuckyNumbers next(): "i=$self->{'i'}"
  ### count: $self->{'count'}
  ### remaining: $self->{'remaining'}
  ### value: $self->{'value'}

  my $count = $self->{'count'};
  my $remaining = $self->{'remaining'};
  my $value = $self->{'value'};

 OUTER: for (;;) {
    $value += 2;
    ### $value
    foreach my $i (0 .. $#$remaining) {
      if (--$remaining->[$i] <= 0) {
        ### exclude at: "i=$i  count=$self->{'count'}->[$i]"
        $remaining->[$i] = $self->{'count'}->[$i];
        next OUTER;
      }
    }
    $self->{'value'} = $value;
    if ($value > 3) {
      push @$count, $value;
      push @$remaining, $value - $self->{'i'};
    }
    return ($self->{'i'}++,
            $value);
  }
}

# i~=value/log(value)
#
use Math::NumSeq::Primes;
*value_to_i_estimate = \&Math::NumSeq::Primes::value_to_i_estimate;

1;
__END__

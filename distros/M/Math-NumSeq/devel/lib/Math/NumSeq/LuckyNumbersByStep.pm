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


package Math::NumSeq::LuckyNumbersByStep;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 75;

use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


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
#
# use constant oeis_anum => 'A000959';

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'}             = $self->i_start;
  $self->{'remaining'}     = [ 4 ];
  $self->{'subseq'}->{'i'} = 4;
  $self->{'subseq'}->{'inc'}       = $self->{'inc'}    = 4;
  $self->{'subseq'}->{'values'}    = $self->{'values'} = [ 7 ];  # shared
  $self->{'subseq'}->{'value'}     = $self->{'value'}  = 7;
  $self->{'subseq'}->{'remaining'} = [ 4 ];
}

my @small = (undef, 1, 3, 7);
sub next {
  my ($self) = @_;
  ### LuckyNumbers next(): "i=$self->{'i'}"

  my $values;
  {
    my $i = $self->{'i'};
    if ($i <= $#small) {
      ### small: $small[$i]
      return ($self->{'i'}++, $small[$i]);
    }

    $values = $self->{'values'};
    if (($i -= 3) <= $#$values) {   # i=3 value=7
      ### values array: $values->[$i]
      return ($self->{'i'}++, $values->[$i]);
    }
  }

  my $remaining = $self->{'remaining'};
  my $value = $self->{'value'};

 OUTER: for (;;) {
    $value += ($self->{'inc'} ^= 6);  # 2 or 4 alternately

    ### at remaining: join(', ',@$remaining)
    ### values      : join(', ',@{$self->{'values'}})
    ### consider value: $value

    foreach my $pos (0 .. $#$remaining - 1) {
      if (--$remaining->[$pos] <= 0) {
        ### exclude at: "pos=$pos  mults value=$self->{'values'}->[$pos]"
        $remaining->[$pos] = $self->{'values'}->[$pos]; # reset
        next OUTER;
      }
    }

    if (--$remaining->[-1] <= 0) {
      ### exclude at last: "pos=$#$remaining  mults value=$self->{'values'}->[$#$remaining]"
      # restart last counter
      my $reset = $remaining->[-1] = $self->{'values'}->[$#$remaining];

      my $sub_value;
      my $pos = scalar(@$remaining);
      if ($pos <= $#$values) {
        $sub_value = $values->[$pos];
      } else {
        (my $sub_i, $sub_value) = &next($self->{'subseq'});
      }

      ### $sub_value
      $self->{'values'}->[$pos] = $sub_value;
      $self->{'remaining'}->[$pos] = $sub_value - $reset + 1;
      next;
    }

    $self->{'value'} = $value;
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




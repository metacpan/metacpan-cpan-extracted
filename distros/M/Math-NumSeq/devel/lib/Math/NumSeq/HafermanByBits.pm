# Copyright 2013, 2014, 2016, 2019 Kevin Ryde

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


# Math::PlanePath::ZOrderCurve


package Math::NumSeq::HafermanByBits;
use 5.004;
use strict;
use Math::PlanePath::Base::Digits 'digit_split_lowtohigh';

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant description => Math::NumSeq::__('0,1 of Haferman carpet.');
use constant default_i_start => 0;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;
use constant values_min => 0;
use constant values_max => 1;

# 000 all zeros
# 001 infs are box fractal
# 010 evens  is plain starting from 1
# 011      odd=1 even=0 inf=0  is inverse of plain
# 100 odds odd=0 even=1 inf=1  is plain starting from 0
# 101 inverse of evens
# 110 inverse of infs box fractal
# 111 all ones

# start0     carpet 0
# start0 inv carpet 0 inverse
# start1     carpet 1
# start1 inv carpet 1 inverse
# box
# box inverse

use constant parameter_info_array =>
  [
   { name    => 'odd',
     display => Math::NumSeq::__('Odd'),
     type    => 'integer',
     default => 1,
     minimum => 0,
     maximum => 1,
     width   => 1,
   },
   { name    => 'even',
     display => Math::NumSeq::__('Even'),
     type    => 'integer',
     default => 0,
     minimum => 0,
     maximum => 1,
     width   => 1,
   },
   { name    => 'infinite',
     display => Math::NumSeq::__('Infinite'),
     type    => 'integer',
     default => 0,
     minimum => 0,
     maximum => 1,
     width   => 1,
   },
   { name    => 'count_low',
     display => Math::NumSeq::__('Count'),
     type    => 'enum',
     default => 'even',
     choices => ['even','odd'],
   },
   { name    => 'radix',
     share_key => 'radix_9',
     type    => 'integer',
     display => Math::NumSeq::__('Radix'),
     default => 9,
     minimum => 2,
     width   => 3,
     description => Math::NumSeq::__('Radix, ie. base, for the values calculation.  Default is base 9.'),
   },
  ];

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if ($i < 0 || _is_infinite($i)) {  # don't loop forever if $i is +infinity
    return undef;
  }

  my $count = 0;
  for (;;) {
    if ($i) {
      my $digit = _divrem_mutate($i,$self->{'radix'}) & 1;
      if ($self->{'count_low'} eq 'odd') {
        $digit ^= 1;
      }
      if ($digit) {
        # stop at odd digit
        if ($count) {
          return $self->{'even'};
        } else {
          return $self->{'odd'};
        }
      } else {
        # count even digit
        $count ^= 1;
      }
    } else {
      # no more digits, all even
      return $self->{'infinite'};
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1);
}

#------------------------------------------------------------------------------

# return $remainder, modify $n
# the scalar $_[0] is modified, but if it's a BigInt then a new BigInt is made
# and stored there, the bigint value is not changed
sub _divrem_mutate {
  my $d = $_[1];
  my $rem;
  if (ref $_[0] && $_[0]->isa('Math::BigInt')) {
    ($_[0], $rem) = $_[0]->copy->bdiv($d);  # quot,rem in array context
    if (! ref $d || $d < 1_000_000) {
      return $rem->numify;  # plain remainder if fits
    }
  } else {
    $rem = $_[0] % $d;
    $_[0] = int(($_[0]-$rem)/$d); # exact division stays in UV
  }
  return $rem;
}

1;
__END__


# Local variables:
# compile-command: "math-image --wx --values=HafermanByBits --path=ZOrderCurve,radix=3 --scale=5"
# End:

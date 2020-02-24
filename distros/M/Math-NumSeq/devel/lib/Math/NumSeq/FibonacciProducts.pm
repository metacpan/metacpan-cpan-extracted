# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


package Math::NumSeq::FibonacciProducts;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq',
        'Math::NumSeq::Base::IteratePred');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant name => Math::NumSeq::__('Fibonacci Products');
use constant description => Math::NumSeq::__('Numbers which can be formed by multiplying together some set of Fibonacci numbers.');
use constant default_i_start => 1;
use constant values_min => 1;

#------------------------------------------------------------------------------
# cf A065105 not products     values_type=>'non_products'
#    A049997 fib product of two
#    A094563 fib product of three
#    A178772 fib integers, muls and divs
#    A049996 diffs
#    A049998 diffs
#    A049999 diff index
#    A065885 triplets of consecutive k,k+1,k+2 all Fibonacci products
#
# use constant oeis_anum => 'A065108';


#------------------------------------------------------------------------------

sub pred {
  my ($self, $value) = @_;
  ### FibonacciProducts pred(): "$value"

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value != int($value) || $value < 1) {
    return 0;
  }
  if ($value == 1) {
    return 1;
  }

  my (@value,@i);
  my $limit = $value;
  my $fib = Math::NumSeq::Fibonacci->new;
  $fib->seek_to_i(3);  # starting from F[3]=2

  my ($i, $f);
  for (;;) {
    ($i, $f) = $fib->next;
    ### $i
    ### $f
    ### assert: $f >= 2

    if ($f <= $value) {
      while (($value % $f) == 0) {
        push @value, $value;
        push @i, $i;
        ### divide out ...
        $value /= $f;
        if ($value == 1) {
          ### found ...
          return 1;
        }
      }
    } else {
      ### backtrack ...
      if (@value) {
        $value = pop @value;
        $i = pop @i;
        $fib->seek_to_i($i+1);
      } else {
        ### no combination found ...
        return 0;
      }
    }
  }
}

1;
__END__

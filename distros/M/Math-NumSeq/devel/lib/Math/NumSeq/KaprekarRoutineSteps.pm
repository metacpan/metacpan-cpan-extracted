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

package Math::NumSeq::KaprekarRoutineSteps;
use 5.004;
use strict;
use List::Util 'min';

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Number of steps of the Kaprekar iteration digits ascending + digits descending until reaching a cycle.');
use constant i_start => 1;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

use constant values_min => 0;

#------------------------------------------------------------------------------
# A151949 - decimal one step
# A164734 - number of n-digit 2-cycles
# A164735 - number of n-digit 3-cycles
# A164736 - number of n-digit 5-cycles
#
# A164993 - base-3 one step
# A164994 - base-3 one step / 2
# A164995 - base-3 pre-periodic length
#
# A164727 - cycles 5
# A164731 - number of cycles
# A164732 - cycles
# A164727 - cycles 5

my @oeis_anum;
# $oeis_anum[]

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }

  my $radix = $self->{'radix'};
  my @digits = _digit_split($i, $radix);
  my %seen = (join(',',@digits) => undef);
  my $count = 0;
  for (;;) {
    ### at: "count=$count   ".join(', ', @digits)

    @digits = sort {$a<=>$b} @digits;
    ### sorted: join(', ', @digits)

    my @diff;
    my $borrow = 0;
    foreach my $i (0 .. $#digits) {  # low to high
      my $diff = $digits[$i] - $digits[-1-$i] - $borrow;
      if ($borrow = ($diff < 0)) {
        $diff += $radix;
      }
      $diff[$i] = $diff;
    }
    ### diff: join(', ', @diff)
    ### assert: $borrow == 0

    # while ($diff[-1] == 0) {
    #   ### strip high zero ...
    #   pop @diff;
    #   if (! @diff) {
    #     return $count;
    #   }
    # }

    @digits = @diff;
    my $key = join (',',@digits);
    if (exists $seen{$key}) {
      last;
    }
    $seen{$key} = undef;
    $count++;
  }
  return $count;
}

sub _digit_split {
  my ($n, $radix) = @_;
  ### _digit_split(): $n
  my @ret;
  while ($n) {
    push @ret, $n % $radix;
    $n = int($n/$radix);
  }
  return @ret;   # low to high
}

1;
__END__

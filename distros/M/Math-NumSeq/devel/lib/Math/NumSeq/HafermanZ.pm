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


package Math::NumSeq::HafermanZ;
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

use constant description => Math::NumSeq::__('0,1 of Haferman carpet for Z-Order base 3.');
use constant default_i_start => 0;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;
use constant values_min => 0;
use constant values_max => 1;

use constant parameter_info_array =>
  [
   { name    => 'start',
     display => Math::NumSeq::__('Start'),
     type    => 'integer',
     default => 0,
     minimum => 0,
     maximum => 1,
     width   => 1,
     description => Math::NumSeq::__('Starting 0 or 1.'),
   },
   { name    => 'all_even',
     display => Math::NumSeq::__('All Even'),
     type    => 'integer',
     default => 1,
     minimum => 0,
     maximum => 1,
     width   => 1,
   },
  ];

#------------------------------------------------------------------------------

# my @want_digit;
# foreach my $h (0 .. 8) {
#   foreach my $l (0 .. 8) {
#     my $want = (($h % 2 == 0) || ($l % 2 != 0));
#     my $hx = ($h % 3);
#     my $hy = int($h/3);
#     my $lx = ($l % 3);
#     my $ly = int($l/3);
#     my $x = $hx*3 + $lx;
#     my $y = $hy*3 + $ly;
#     my $i = $y*9 + $x;
#     $want_digit[$i] = $want;
#   }
# }
# foreach my $h (reverse 0 .. 8) {
#   foreach my $l (0 .. 8) {
#     print $want_digit[$h*9+$l] ? '*' : ' ';
#   }
#   print "\n";
# }

# state=0 high skip
# state=1 second odd  -> state=1
#                even -> state=0
# run of odd keep state=1
#
#  ___,odd,odd,odd,odd,even,___,odd,odd,odd,even,___
# 0   1   1   1   1   1    0   1   1   1   1   0    1
# value=0 if end odd,even
#
#  ___,even,___,even,___,even
# 0   1   0    1    0   1    0
# value=0 if end any,even with even above

# i=0 to 8  0=even,any  value=1

my @end;
foreach my $h (0 .. 8) {
  foreach my $l (0 .. 8) {
    if ($l % 2 == 1) {
      $end[9*$h + $l] = 1;  # any,odd
    } elsif ($h % 2 == 1) {
      $end[9*$h + $l] = 0;  # odd,even
    }
  }
}

sub ith {
  my ($self, $i) = @_;
  ### ith(): $i

  if ($i < 0 || _is_infinite($i)) {  # don't loop forever if $i is +infinity
    return undef;
  }

  {
    # value=0 if lowest odd base-9 digit is at an odd position
    # value=1 if not, including if no odd digits
    my $pos = $self->{'start'};  # initial position
    while ($i > 0) {
      my $digit = $i % 9;
      if ($digit % 2) { return $pos; }
      $i = int(($i-$digit)/9);
      $pos ^= 1;
    }
    return $self->{'all_even'};
  }

  {
    my @digits = digit_split_lowtohigh($i,9);
    while (@digits) {
      if ($digits[0] % 2 == 1) {
        return 1;  # end any,odd
      }
      if (($digits[1]||0) % 2 == 1) {
        return 0;  # end odd,even
      }
      shift @digits;
      shift @digits;
    }
    return 0;   # start 010,101,010
    return 1;   # start 111,111,111
  }

  {
    my @digits = digit_split_lowtohigh($i,9);
    if ($#digits & 1) { push @digits, 0; }  # ensure even num digits
    # if (@digits & 1) { push @digits, 0; }  # ensure odd num digits
    my $state = 0;
    foreach my $digit (reverse @digits) { # high to low
      if ($state) {
        $state = ($digit % 2);
      } else {
        $state = 1;
      }
    }
    return $state;
  }

  {
    my @digits = digit_split_lowtohigh($i,81);
    if ($#digits & 1) { push @digits, 0; }
    foreach my $digit (digit_split_lowtohigh($i,81)) {
      if (defined (my $end = $end[$digit])) {
        return $end;
      }
    }
    return 0;
  }
}

sub pred {
  my ($self, $value) = @_;
  return ($value == 0 || $value == 1);
}

1;
__END__

# Local variables:
# compile-command: "math-image --wx --values=HafermanZ --path=ZOrderCurve,radix=3"
# End:
#

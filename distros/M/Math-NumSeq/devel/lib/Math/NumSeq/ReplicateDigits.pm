# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::ReplicateDigits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Replicate the digits of i, so i=123 gives value 112233.');
use constant default_i_start => 0;
use constant characteristic_integer => 1;
use constant characteristic_increasing => 1;

use Math::NumSeq::DigitCount 4;
use constant parameter_info_array =>
  [ Math::NumSeq::Base::Digits::parameter_common_radix(),
    { name    => 'replicate',
      type    => 'integer',
      minimum => 1,
      default => 2,
      width   => 1,
    },
  ];

sub values_min {
  my ($self) = @_;
  return $self->ith($self->i_start);
}

# cf A044836 decimal odd/even runs
#
my @oeis_anum;
$oeis_anum[0]->[10]->[1] = 'A001477';
# OEIS-Other: A001477 replicate=1             # integers 0 upwards

$oeis_anum[1]->[10]->[1] = 'A000027';
# OEIS-Other: A000027 replicate=1 i_start=1   # integers 1 upwards

# no, these repeat whole values, not individual digits
#
# $oeis_anum[1]->[10]->[2] = 'A020338';
# # OEIS-Catalogue: A020338 i_start=1    # doublets 1010,1111,1212
# 
# $oeis_anum[1]->[10]->[3] = 'A074842';
# # OEIS-Catalogue: A074842  replicate=3 i_start=1    # triplets
# 
# $oeis_anum[1]->[10]->[4] = 'A074843';
# # OEIS-Catalogue: A074843  replicate=4 i_start=1    # quadruplets

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->i_start]->[$self->{'radix'}]->[$self->{'replicate'}];
}

sub ith {
  my ($self, $i) = @_;
  ### ReplicateDigits ith(): $i

  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }

  my $value = ($i * 0);   # inherit bignum 0
  my $power = $value + 1; # inherit bignum 1
  if ($i < 0) {
    $power = -$power;
    $i = - $i;
  }

  my $radix = $self->{'radix'};
  my $replicate = $self->{'replicate'};

  while ($i) {
    my $digit = $i % $radix;
    $i = int($i/$radix);
    foreach (1 .. $replicate) {
      $value += $power * $digit;
      $power *= $radix;
    }
  }
  return $value;
}

sub pred {
  my ($self, $value) = @_;
  my $radix = $self->{'radix'};
  my $replicate = $self->{'replicate'};
  $value = abs($value);
  while ($value) {
    my $digit = $value % $radix;
    $value = int($value/$radix);
    foreach (2 .. $replicate) {
      if (($value % $radix) != $digit) {
        return 0;
      }
      $value = int($value/$radix);
    }
  }
  return 1;
}

1;
__END__

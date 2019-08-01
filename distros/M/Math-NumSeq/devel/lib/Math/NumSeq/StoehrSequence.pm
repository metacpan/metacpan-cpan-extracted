# slow keeping all past terms




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

package Math::NumSeq::StoehrSequence;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq;
use List::Util 'min';
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# 3: 1, 2, 4, 8, 15, 22, 29, 36
# 3=1+2
# 5=1+4
# 6=2+4
# 7=1+2+4


# use constant name => Math::NumSeq::__('...');
# use constant description => Math::NumSeq::__('Stoehr sequence, ...');
use constant i_start => 1;
use constant characteristic_integer => 1;
use constant parameter_info_array =>
  [
   {
    name        => 'terms',
    type        => 'integer',
    default     => 3,
    minimum     => 2,
    width       => 2,
    # description => Math::NumSeq::__('...'),
   },
  ];

use constant values_min => 1;


my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,
                 undef,
                 'A033627', # terms=2
                 'A026474', # terms=3
                 'A051039', # terms=4
                 'A051040', # terms=5

                 # OEIS-Catalogue array end
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'terms'}];
}

# each 2-bit vec() value is
#    0 not a sum
#    1 sum one
#    2 sum two or more
#    3 (unused)

# sums[0] a
# sums[1] a+b
# sums[2] a+b+c
# sums[3] a+b+c+d

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'prev_value'} = 0;
  $self->{'sums'} = [ ('') x $self->{'terms'} ];
}

sub next {
  my ($self) = @_;
  ### next(): $self->{'i'}
  ### sums: dump_sums()

  my $terms = $self->{'terms'};
  my $sums = $self->{'sums'};
  my $value = $self->{'prev_value'};

 VALUE: for (;;) {
    $value++;
    foreach my $sum (@$sums) {
      next VALUE if vec($sum, $value, 1);
    }
    last;
  }
  ### $value

  foreach my $t (reverse 0 .. $terms-2) {
    ### loop: "t=$t max=".(8*length($sums->[$t])-1)
    foreach my $i (0 .. 8*length($sums->[$t])-1) {
      if (vec($sums->[$t], $i,1)) {
        ### add: "$i+$value = ".($i+$value)
        vec ($sums->[$t+1], $i+$value, 1) = 1;
      }
    }
  }
  vec ($sums->[0], $value, 1) = 1;

  return ($self->{'i'}++, $value);
}

sub dump_sums {
  my ($self) = @_;
  my $str = "\n";
  my $sums = $self->{'sums'};
  foreach my $t (0 .. $#$sums) {
    $str .= "$t: ";
    foreach my $i (0 .. 8*length($sums->[$t])) {
      if (vec($sums->[$t], $i,1)) {
        $str .= "$i,";
      }
    }
    $str .= "\n";
  }
  return $str;
}
1;
__END__

# Calculate in integers not float rounding.
# 'custom' or expression for spectrum value.


# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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


package Math::NumSeq::Spectrum;
use 5.004;
use strict;
use List::Util 'max';
use POSIX 'ceil';

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');


# uncomment this to run the ### lines
#use Smart::Comments;

use constant PHI => (1 + sqrt(5)) / 2;

# use constant name => Math::NumSeq::__('Spectrum');
# use constant description => Math::NumSeq::__('');
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [ { name    => 'spectrum',
      display => Math::NumSeq::__('Spectrum'),
      type    => 'float',
      width   => 12,
      default => PHI,
      description => Math::NumSeq::__('The to show the spectrum of, usually an irrational.'),
    },
  ];

#------------------------------------------------------------------------------
# cf A178482 Golden Patterns Phi-antipalindromic 
#    A007067 nearest(i*PHI)
#    A187389 floor of r=sqrt(6)+sqrt(7)
sub oeis_anum {
  my ($self) = @_;
  my $spectrum = (ref $self
                  ? $self->{'spectrum'}
                  : $self->parameter_default('spectrum'));
  if ($spectrum == PHI) {
    return 'A000201'; # Golden Sequence 1,3,4,6,8,9,11,12
    # OEIS-Catalogue: A000201
  }
  if ($spectrum == sqrt(2)) {
    return 'A001951'; # Golden Sequence 1,3,4,6,8,9,11,12
    # # OEIS-Catalogue: A000201 spectrum=sqrt(2)
  }
  return undef;
}

#------------------------------------------------------------------------------


# integer part of sqrt(5*i*i) so as not to depend on multiplying up the
# float sqrt(5)
#
# i*(1+sqrt(5))/2
# = (i+sqrt(5*i*i))/2
# = i/2 + sqrt(5*i*i)/2

sub rewind {
  my ($self) = @_;
  ### Spectrum rewind() ...

  my $lo = $self->{'lo'} || 0;
  $lo = max (1, $lo);

  my $spectrum = $self->{'spectrum'} || PHI;
  ### $spectrum
  $self->{'i'} = ceil ($lo / $spectrum);
}

sub next {
  my ($self) = @_;
  ### Spectrum next() ...
  ### i: $self->{'i'}

  my $i = $self->{'i'}++;
  my $spectrum = $self->{'spectrum'};
  if ($spectrum == PHI) {
    ### i*PHI: $i*PHI
    ### int: int( ($i + sqrt(5*$i*$i)) / 2 )
    return ($i, int( ($i + sqrt(5*$i*$i)) / 2 ));
  } else {
    ### i*spectrum: $i * $spectrum
    return ($i, int($i * $spectrum));
  }
}

sub pred {
  my ($self, $value) = @_;
  if ($value <= 0) { return 0; }
  return (int($self->inv_floor($value) * $self->{'spectrum'}) == $value);
}
sub inv_floor {
  my ($self, $value) = @_;
  return ceil($value/$self->{'spectrum'});
}

1;
__END__


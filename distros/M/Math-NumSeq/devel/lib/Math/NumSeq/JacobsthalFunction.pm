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


# https://github.com/hvds/seq/tree/master/jacobsthal
#

package Math::NumSeq::JacobsthalFunction;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::PrimeFactorCount;;
*_prime_factors = \&Math::NumSeq::PrimeFactorCount::_prime_factors;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Jacobsthal Function');
# use constant description => Math::NumSeq::__('');
use constant default_i_start => 1;
use constant characteristic_integer => 1;
use constant characteristic_smaller => 1;

use constant parameter_info_array =>
  [ { name    => 'jacobsthal_type',
      display => Math::NumSeq::__('Jacobsthal Type'),
      type    => 'enum',
      default => 'all',
      choices => ['all','less'],
      # description => Math::NumSeq::__('...'),
    },
  ];

sub values_min {
  my ($self) = @_;
  return 1;
}

#------------------------------------------------------------------------------
# cf A048670 Jacobsthal on primorial
#    A058989 run divisible by prime < nth
#    A070971 first time maximal gap occurs at n
#    A049298 Jacobsthal
#    A049298 as first diffs of reduced residues
#    A132468 counting the skipped values not endpoints, so A048669(n)-1
#    

my %oeis_anum = ('all,1'  => 'A048669',
                 'less,3' => 'A070194',
                 
                 # OEIS-Catalogue: A048669
                 # OEIS-Catalogue: A070194 jacobsthal_type=less i_start=3
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'jacobsthal_type'}.','.$self->i_start};
}


#------------------------------------------------------------------------------

my %minimum = (all  => 2,  # from i-1 to i+1
               less => 1,
              );

sub ith {
  my ($self, $i) = @_;
  ### JacobsthalFunction ith(): $i

  if (_is_infinite($i)) {
    return undef;
  }
  if ($i == 1) {
    return 1;
  }

  my $limit = int(($i+1)/2);
  my $vec = '';
  vec($vec,$limit,1) = 0; # pre-extend

  {
    my $prev = 0;
    my ($good, @primes) = _prime_factors($i);
    return undef unless $good;

    foreach my $prime (@primes) {
      next if $prime == $prev;
      for (my $g = $prime; $g <= $limit; $g += $prime) {
        vec($vec,$g,1) = 1;  # flag common factor
      }
      $prev = $prime;
    }
  }

  my $max = $minimum{$self->{'jacobsthal_type'}};
  my $prev = 1;
  foreach my $g (2 .. $limit) {
    if (! vec($vec,$g,1)) {
      ### coprime: $g
      ### diff: defined $prev && $g-$prev
      if (defined $prev) {
        $max = max ($max, $g-$prev);
      }
      $prev = $g;
    }
  }

  ### across middle is prev to i-prev: $i-2*$prev
  return max ($max, $i-2*$prev);
}

1;
__END__



  # use Math::NumSeq::DuffinianNumbers;
  # *_coprime = \&Math::NumSeq::DuffinianNumbers::_coprime;

  # {
  #   my $prev = 1;
  #   my $max = $minimum{$self->{'jacobsthal_type'}};
  #
  #   foreach my $g (2 .. int(($i+1)/2)) {
  #     if (_coprime ($g, $i)) {
  #       ### coprime: $g
  #       ### diff: defined $prev && $g-$prev
  #       if (defined $prev) {
  #         $max = max ($max, $g-$prev);
  #       }
  #       $prev = $g;
  #     }
  #   }
  #
  #   ### across middle, prev to i-prev: $i-2*$prev
  #   $max = max ($max, $i-2*$prev);
  #
  #   return $max;
  # }

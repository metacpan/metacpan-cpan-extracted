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

package Math::NumSeq::EratosthenesStage;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
use List::Util 'max';
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Primes;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Stages of the sieve of Eratosthenes.');
use constant i_start => 1;
use constant characteristic_smaller => 0;
use constant characteristic_integer => 1;
use constant parameter_info_array =>
  [
   {
    name        => 'stage',
    type        => 'integer',
    default     => '3',
    width       => 4,
    # description => Math::NumSeq::__('...'),
   },
  ];

use constant values_min => 2;

#------------------------------------------------------------------------------
# cf A179546 first a(n) numbers killed
#    A179545 sum jump
#    A066680 sieve up to p^2 only
#    A083140 diagonals of stages

my @oeis_anum = (undef,      # 0, all integers 2 upwards
                 'A004280',  # 1
                 'A038179',  # 2
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'stage'}];
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my $stage = $self->{'stage'};
  my @primes;
  my $seq = Math::NumSeq::Primes->new;
  $seq->next; # not 2
  foreach (2 .. $stage) {
    my ($i, $value) = $seq->next;
    push @primes, $value;
  }
  $self->{'primes'} = \@primes;
  ### @primes
  return $self;
}
sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'a'} = 2;
  $self->{'size'} = 5;
  $self->{'lo'} = 0;
  $self->{'hi'} = 0;
}

sub next {
  my ($self) = @_;

  my $flags = $self->{'flags'};
  my $lo = $self->{'lo'};
  my $hi = $self->{'hi'};
  for (;;) {
    my $a = $self->{'a'}++;
    ### $a

    if ($a > $hi) {
      my $size = $self->{'size'} = int (1.08 * $self->{'size'});

      # lo to hi inclusive,
      # flags 0 to size=hi-lo inclusive
      $lo = $self->{'lo'} = $a;
      $hi = $self->{'hi'} = $lo + $size;
      my $flags_str = '';
      vec($flags_str,$size,1) = 0; # pre-extend
      $flags = $self->{'flags'} = \$flags_str;

      if ($self->{'stage'} > 0) {
        for (my $n = max (4-$lo, -$lo % 2); $n <= $size; $n += 2) {
          ### flag even: "n=$n is ".($n+$lo)
          vec($flags_str,$n,1) = 1;
        }
        foreach my $prime (@{$self->{'primes'}}) {
          my $p2 = 2*$prime;
          for (my $n = max (3*$prime - $lo,
                            -$lo % $prime);
               $n <= $size;
               $n += $p2) {
            vec($flags_str,$n,1) = 1;
          }
        }
      }
    }
    if (vec($$flags,$a-$lo,1)) {
      ### skip: $a
      next;
    }
    ### return: "i=$self->{'i'}  a=$a"
    return ($self->{'i'}++, $a);
  }
}

1;
__END__

stage 0: 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
stage 1: 2,3,5,7,9,11,13,15,17
stage 2: 2,3,5,7,11,13,17

# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::CunninghamPrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq::Primes');

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [
   { name    => 'length',
     display => Math::NumSeq::__('Length'),
     type    => 'integer',
     default => '3',
     minimum => 1,
     description => Math::NumSeq::__('Prime chain length required.'),
   },
   { name    => 'which',
     display => Math::NumSeq::__('Which'),
     type    => 'enum',
     default => 'first',
     choices => ['first','last'],
     choices_display => [Math::NumSeq::__('First'),
                         Math::NumSeq::__('Last'),
                         Math::NumSeq::__('All'),
                        ],
     description => Math::NumSeq::__('Which the chain values to show.'),
   },
   { name    => 'kind',
     display => Math::NumSeq::__('Kind'),
     type    => 'enum',
     default => 'first',
     choices => ['first','second'],
     choices_display => [Math::NumSeq::__('First'),
                         Math::NumSeq::__('Second')],
     description => Math::NumSeq::__('Which "kind" of chain, first kind 2*P+1 or second kind 2*P-1.'),
   },
  ];

# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Cunningham chains of primes where P, 2*P+1, 4*P+3 etc are all prime.');
use constant i_start => 1;
use constant characteristic_increasing => 1;

# FIXME: find the first value in the sequence ... maybe save it
my %values_min =
  (first =>
   { first => [undef,
               2,  # length=1  all primes p
               2,  # length=2  sophie germain p,2p+1
               2,  # length=3  p,2p+1,4p+3 all primes
               2,  # length=4
               2,  # length=5
               89, # length=6
              ],
     last => [undef,
              2,  # length=1  all primes p
              5,  # length=2  safe primes 2p+1
              11, # length=3
             ],
   },
   # second => {},
  );
sub values_min {
  my ($self) = @_;
  ### kind: $self->{'kind'}
  ### which: $self->{'which'}
  ### length: $self->{'length'}
  return $values_min{$self->{'kind'}}->{$self->{'which'}}->[$self->{'length'}];
}

#------------------------------------------------------------------------------
my %oeis_anum =
  (first =>
   { first => [undef,
               'A000040',  # length=1  all primes p
               'A005384',  # length=2  sophie germain p,2p+1
               'A007700',  # length=3  p,2p+1,4p+3 all primes
               # OEIS-Other:     A000040 length=1 kind=first which=first
               # OEIS-Other:     A005384 length=2 kind=first which=first
               # OEIS-Catalogue: A007700 length=3 kind=first which=first

               'A023272',
               # OEIS-Catalogue: A023272 length=4 kind=first which=first

               'A023302',
               # OEIS-Catalogue: A023302 length=5 kind=first which=first
               'A023330',
               # OEIS-Catalogue: A023330 length=6 kind=first which=first
              ],
     last => [undef,
              'A000040',  # length=1  all primes p
              'A005385',  # length=2  safe primes 2p+1
              # OEIS-Other: A000040 length=1 kind=first which=last
              # OEIS-Catalogue: A005385 length=2 kind=first which=last
             ],
   },
   # second => {},
  );
sub oeis_anum {
  my ($self) = @_;
  ### kind: $self->{'kind'}
  ### which: $self->{'which'}
  ### length: $self->{'length'}
  return $oeis_anum{$self->{'kind'}}->{$self->{'which'}}->[$self->{'length'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->SUPER::rewind;

  ### length: $self->{'length'}
  my $sa = $self->{'chain_seqarray'}
    = [ map {Math::NumSeq::Primes->new()} (2 .. $self->{'length'}) ];
  @{$self->{'chain_ahead'}} = (0) x @$sa;

  $self->{'chain_inc'} = ($self->{'kind'} eq 'second' ? -1 : 1);

  $self->{'chain_i'} = 1;
  ### sa length: scalar(@$sa)
}

sub next {
  my ($self) = @_;

  my $sa = $self->{'chain_seqarray'};
  my $ah = $self->{'chain_ahead'};
  my $inc = $self->{'chain_inc'};
 OUTER: for (;;) {
    (undef, my $prime) = $self->SUPER::next
      or return;

    my $target = $prime;
    foreach my $i (0 .. $#$sa) {
      $target = 2*$target + $inc;
      ### $target

      while ($ah->[$i] < $target) {
        (undef, $ah->[$i]) = $sa->[$i]->next
          or return;
        ### step: "$i to $ah->[$i]"
      }
      if ($ah->[$i] != $target) {
        next OUTER;
      }
    }
    ### found ...
    return ($self->{'chain_i'}++, ($self->{'which'} eq 'last'
                                   ? $target : $prime));
  }
}

sub pred {
  my ($self, $value) = @_;
  ### pred(): "$value with len=$self->{'length'}"
  unless ($self->SUPER::pred($value)) {
    ### not a prime ...
    return 0;
  }
  my $inc = $self->{'chain_inc'};
  if ($self->{'which'} eq 'last') {
    foreach (2 .. $self->{'length'}) {
      $value -= $inc;
      return 0 unless $value >= 4 && ($value % 2) == 0;
      $value /= 2;
      ### consider: $value
      $self->SUPER::pred($value) or return 0;
    }
  } else {
    foreach (2 .. $self->{'length'}) {
      $value = 2*$value +  $inc;
      ### consider: $value
      $self->SUPER::pred($value) or return 0;
    }
  }
  return 1;
}

1;
__END__

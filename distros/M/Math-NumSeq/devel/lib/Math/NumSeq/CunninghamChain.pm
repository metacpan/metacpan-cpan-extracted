# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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


# cf A006562 balance primes
#

package Math::NumSeq::CunninghamChain;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [
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
use constant characteristic_increasing => 0;
use constant values_min => 0;

sub rewind {
  my ($self) = @_;
  $self->{'chain_queue'} = [];
  my $primeseq = $self->{'primeseq'} = Math::NumSeq::Primes->new();
  $self->{'chain_inc'} = ($self->{'kind'} eq 'second' ? -1 : 1);
  $self->{'chain_i'} = 1;
  (undef, $self->{'chain_prime'}) = $primeseq->next;
}

sub next {
  my ($self) = @_;
  my $i = $self->{'chain_i'}++;

  if ($self->{'chain_prime'} != $i) {
    return ($i, 0);
  }

  ### prime: $i
  (undef, $self->{'chain_prime'}) = $self->{'primeseq'}->next
    or return;

  my $queue = $self->{'chain_queue'};
  ### $queue

  while (@$queue && $queue->[0] < $i) {
    shift @$queue;
    shift @$queue;
  }

  my $count;
  if (@$queue && $queue->[0] == $i) {
    ### match: $queue->[0], $queue->[1]
    shift @$queue;
    $count = shift @$queue;
  } else {
    $count = 0;
  }

  push @$queue, 2*$i+$self->{'chain_inc'}, $count+1;
  ### $queue

  return ($i, $count);
}

sub ith {
  my ($self, $value) = @_;
  my $count = 0;
  if (Math::NumSeq::Primes->pred($value)) {
    for (;;) {
      last unless $value % 2;
      $value = ($value - $self->{'chain_inc'}) / 2;
      last unless Math::NumSeq::Primes->pred($value);
      $count++;
    }
  }
  return $count;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 0 && $value==int($value));
}

1;
__END__

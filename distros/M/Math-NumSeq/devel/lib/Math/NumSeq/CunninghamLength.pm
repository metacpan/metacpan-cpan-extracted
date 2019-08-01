# Copyright 2010, 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

package Math::NumSeq::CunninghamLength;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
use Math::NumSeq::Primes;

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
use constant description => Math::NumSeq::__('Cunningham chain length P,2P+1,4P+3,etc, or 0 if not prime.');
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant values_min => 0;

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'chain_inc'} = ($self->{'kind'} eq 'second' ? -1 : 1);
  return $self;
}

sub ith {
  my ($self, $value) = @_;
  my $count = 0;
  if (Math::NumSeq::Primes->pred($value)) {
    $count = 1;
    for (my $back = $value; ; ) {
      last unless $back % 2;
      $back = ($back - $self->{'chain_inc'}) / 2;
      last unless Math::NumSeq::Primes->pred($back);
      $count++;
    }
    for (;;) {
      if ($value >= 0xFFFF_FFFF) {
        return undef;
      }
      $value = 2*$value + $self->{'chain_inc'};
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

# bit slow maybe
# all numbers past some point are undulants ...




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


package Math::NumSeq::BinaryUndulants;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant name => Math::NumSeq::__('Binary Undulants');
use constant description => Math::NumSeq::__('Binary undulants, numbers k where 2^k written in decimal contains digits 101 or 010.');
use constant default_i_start => 1;
use constant characteristic_increasing => 1;

use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [
   Math::NumSeq::Base::Digits::parameter_common_radix(),
  ];

sub values_min {
  my ($self) = @_;
  if (! $self->{'values_min'}) {
    for (my $value = 1; ; $value++) {
      if ($self->pred($value)) {
        $self->{'values_min'} = $value;
        last;
      }
    }
  }
  return $self->{'values_min'};
}

#------------------------------------------------------------------------------
my @oeis_anum;
$oeis_anum[10] = 'A046076';
# OEIS-Catalogue: A046076   # radix=10
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------
my %radix_to_stringize_method = ((Math::NumSeq::_bigint()->can('as_bin')
                                  ? (2  => 'as_bin')
                                  : ()),
                                 (Math::NumSeq::_bigint()->can('as_oct')
                                  ? (8  => 'as_oct')
                                  : ()),
                                 (Math::NumSeq::_bigint()->can('bstr')
                                  ? (10 => 'bstr')
                                  : ()),
                                 (Math::NumSeq::_bigint()->can('as_hex')
                                  ? (16 => 'as_hex')
                                  : ()));

sub rewind {
  my ($self) = @_;

  my $radix = $self->{'radix'};
  if ($radix < 2) { $radix = 10; }
  $self->{'radix'} = $radix;

  $self->{'radix_is_pow2'} = (($radix & ($radix-1)) == 0);

  my $method;
  $self->{'bigint_check'}
    = (($method = $radix_to_stringize_method{$radix})
       ? sub {
         my ($bigint) = @_;
         ### check by string: $bigint->$method
         return ($bigint->$method =~ /010|101/);
       }
       : sub {
         my ($bigint) = @_;
         $bigint = $bigint->copy;
         ### check by division: "$bigint"
         my $dp = my $dpp = 0;
         while ($bigint) {
           ($bigint, my $d) = $bigint->bdiv($radix);
           ### $d;
           ### $bigint
           if (($d == 0 && $dp == 1 && $dpp == 0)
               || ($d == 1 && $dp == 0 && $dpp == 1)) {
             ### yes ...
             return 1;
           }
           $dpp = $dp;
           $dp = $d;
         }
         ### no ...
         return 0;
       });

  $self->{'pow'} = _to_bigint(2);
  $self->{'value'} = 1;
  $self->{'i'}     = 1;
}

sub next {
  my ($self) = @_;
  ### BinaryUndulants next() ...

  my $radix = $self->{'radix'};
  if ($self->{'radix_is_pow2'}) {
    return;
  }

  my $bigint_check = $self->{'bigint_check'};
  do {
    ### at value: $self->{'value'}
    $self->{'value'}++;
  } until ($bigint_check->($self->{'pow'} *= 2));

  return ($self->{'i'}++, $self->{'value'});
}

sub pred {
  my ($self, $value) = @_;

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value != int($value)
      || $self->{'radix_is_pow2'}) {
    return 0;
  }
  return $self->{'bigint_check'}->(_to_bigint(2)->bpow($value));
}

1;
__END__

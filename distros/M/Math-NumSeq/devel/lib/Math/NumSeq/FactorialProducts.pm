# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


# SB RationalsTree straight lines

package Math::NumSeq::FactorialProducts;
use 5.004;
use strict;
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('...');
use constant default_i_start => 1;
use constant characteristic_integer => 1;
use constant values_min => 1;

use constant parameter_info_array =>
  [
   { name      => 'multiplicity',
     share_key => 'multiplicity_product',
     display   => Math::NumSeq::__('Multiplicity'),
     type      => 'enum',
     default   => 'repeated',
     choices   => [ 'repeated',
                    'distinct',
                  ],
     choices_display => [ Math::NumSeq::__('Repeated'),
                          Math::NumSeq::__('Distinct'),
                        ],
     description => Math::NumSeq::__('Whether to allow repeated factorials in the product, or only distinct.'),
   },
  ];

#------------------------------------------------------------------------------
# cf A115746 products of p! for any prime p, excluding 1
#    A001013 Jordan-Polya products of factorials
#    A034878 n! is product of smaller factorials, with repeats
#    A075082 n! is product of smaller factorials, no repeats
#    A058295 products of distinct factorials
#    A000178 superfactorials, product of first n factorials
#    A098694 double-superfactorials, product first 2n factorials
#    A074319 product next n factorials
#    A000197 (n!)!
#
my %oeis_anum = (repeated => 'A001013',
                 distinct => 'A058295',
                );
# # OEIS-Catalogue: A001013
# # OEIS-Catalogue: A058295 multiplicity=distinct

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'multiplicity'}};
}

# use constant oeis_anum => 'A115746';  # p!


#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'value'} = 0;
}

sub next {
  my ($self) = @_;
  return ($self->{'i'}++,
          $self->{'value'} = $self->value_ceil($self->{'value'}+1));
}  

sub value_ceil {
  my ($self, $value) = @_;
  ### FactorialProducts value_ceil(): "$value"

  if ($value < 1) {
    return 1;
  }
  if (_is_infinite($value)) {
    return $value;
  }
  my $distinct = ($self->{'multiplicity'} eq 'distinct');
  
  my $found;
  my $prod = 1;
  my $limit = 2**31;
  my (@prod,@limit);
  my $f = 1;
  for (;;) {
    ### at: "f=$f prod=$prod limit=$limit"
    ### prod: join('',@prod)
    ### limit: join('',@limit)
    if ($prod >= $value) {
      if (! $found || $prod < $found) {
        ### found: $prod
        $found = $prod;
      }
      $prod = pop @prod || last;
      $limit = pop @limit;
      $f = 1;
      next;
    }
    $f++;
    if ($f > $limit) {
      if ($limit > 2) {
        $limit--;
        $f = 1;
      } else {
        $prod = pop @prod || last;
        $limit = pop @limit;
        $f = 1;
      }
    } else {
      $prod *= $f;
      push @prod, $prod;
      push @limit, $f - $distinct;
    }
  }
  return $found;
}

sub pred {
  my ($self, $value) = @_;
  ### FactorialProducts pred(): "$value"

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value != int($value)) {
    return 0;
  }
  if ($value < 2) {
    return ($value == 1);
    return 0;
  }
  my $distinct = ($self->{'multiplicity'} eq 'distinct');

  # The loop divides out a factorial n! by counting $f from 2 upwards.
  # If $value % $f != 0 then that's a factorial ($f-1)! divided out.

  my (@value,@limit);
  my $limit = 2**31;
  my $f = 1;
  for (;;) {
    $f++;
    if ($f > $limit || $value % $f) {
      ### backtrack ...
      if (@value) {
        $f = 1;
        $value = pop @value;
        $limit = pop @limit;
      } else {
        return 0;
      }
    } else {
      $value /= $f;
      if ($value <= 1) {
        return 1;
      }

      push @value, $value;
      push @limit, $f - $distinct;
      if (is_prime($f)) {
      }
    }
  }
}

1;
__END__

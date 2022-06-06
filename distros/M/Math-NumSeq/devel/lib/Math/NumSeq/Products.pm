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


# SB RationalsTree straight lines

package Math::NumSeq::Products;
use 5.004;
use strict;
use Module::Load;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant default_i_start => 1;
use constant characteristic_integer => 1;
use constant values_min => 1;

use constant parameter_info_array =>
  [
   { name      => 'of',
     share_key => 'of_products',
     display   => Math::NumSeq::__('Of'),
     type      => 'enum',
     default   => 'Factorials',
     choices   => [ 'Factorials',
                    'Primorials',
                    'Fibonacci',
                    'Catalan',
                  ],
     choices_display => [ Math::NumSeq::__('Factorials'),
                          Math::NumSeq::__('Primorials'),
                          Math::NumSeq::__('Fibonacci'),
                          Math::NumSeq::__('Catalan'),
                        ],
     description => Math::NumSeq::__('The values to make products of.'),
   },
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
     description => Math::NumSeq::__('Whether to allow repeated multipliers in the product, or only distinct.'),
   },
  ];

sub description {
  my ($self) = @_;
  if (ref $self) {
    return ($self->{'multiplicity'}
            ? (Math::NumSeq::__('Products of ') . $self->{'of'}
               . Math::NumSeq::__(', with repetition.'))
            : (Math::NumSeq::__('Products of distinct ') . $self->{'of'}));
  } else {
    return Math::NumSeq::__('Products formed from a set of values.');
  }
}

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
#    A160009 fib prod distinct primorials A129912
#
# Factorials repeated   1,2,4,6,8,12,16,24,32,36,48,64,72,96,120,128,144,192
# Factorials distinct   1,2,6,12,24,48,120,144,240,288,720,1440,2880,4320,5040

# Primorials 1,2,6,30,210,
# Primorials repeated   1,2,4,6,8,12,16,24,30,32,36,48,60,64,72,96,120,128,144
#
my %oeis_anum = ('Factorials,repeated' => 'A001013',
                 'Factorials,distinct' => 'A058295',
                 # OEIS-Catalogue: A001013
                 # OEIS-Catalogue: A058295 multiplicity=distinct

                 'Primorials,repeated' => 'A025487',
                 'Primorials,repeated' => 'A129912',
                 # OEIS-Catalogue: A025487 of=Primorials
                 # OEIS-Catalogue: A129912 of=Primorials multiplicity=distinct

                 'Fibonacci,repeated' => 'A065108',
                 'Fibonacci,distinct' => 'A160009',
                 # OEIS-Catalogue: A065108 of=Fibonacci
                 # OEIS-Catalogue: A160009 of=Fibonacci multiplicity=distinct
                );

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{"$self->{'of'},$self->{'multiplicity'}"};
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  my $seq_class = "Math::NumSeq::$self->{'of'}";
  Module::Load::load($seq_class);
  $self->{'seq'} = $seq_class->new;
  return $self;
}

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

my %seq_i_start = (Factorials => 2,
                   Primorials => 1,
                   Fibonacci  => 3,
                   Catalan    => 2);

sub value_ceil {
  my ($self, $value) = @_;
  ### Products value_ceil(): "$value"

  if ($value < 1) {
    return 1;
  }
  if (_is_infinite($value)) {
    return $value;
  }
  my $distinct = ($self->{'multiplicity'} eq 'distinct');

  my $seq = $self->{'seq'};
  my $seq_i_start = $seq_i_start{$self->{'of'}} || 0;
  # my $seq_i_start = $seq->value_to_i_ceil(2);
  ### $seq_i_start
  ### seq first: $seq->ith($seq_i_start)
  ### seq second: $seq->ith($seq_i_start+1)
  ### assert: $seq->ith($seq_i_start) > 1
  ### assert: $seq->ith($seq_i_start+1) > 1

  my @seq_ith;
  my $ceil;
  my $prod = 1;
  my (@prod,@f);
  my $f = $seq_i_start;

  for (;;) {
    ### at: "f=$f prod=$prod   pending f=".join(',',@f)." prod=".join(',',@prod)

    if ($prod >= $value) {
      ### prod above target ...
      if (! $ceil || $prod < $ceil) {
        ### new ceil: $prod
        $ceil = $prod;
      }
      $prod = pop @prod || last;
      $f = pop @f;
      ### pop to: "f=$f prod=$prod"
      next;
    }

    my $term = ($seq_ith[$f] ||= $seq->ith($f));
    ### $term
    if ($term < $value) {
      push @prod, $prod;
      push @f, $f+1;
    }
    $f += $distinct;
    $prod *= $term;
  }
  return $ceil;
}

sub pred {
  my ($self, $value) = @_;
  ### Products pred(): "$value"

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value != int($value)) {
    return 0;
  }
  if ($value < 2) {
    return ($value == 1);
  }
  my $distinct = ($self->{'multiplicity'} eq 'distinct');

  my $seq = $self->{'seq'};
  my $seq_i_start = $seq_i_start{$self->{'of'}} || 0;
  my @seq_ith;
  my (@value,@f);
  my $f = $seq_i_start;

  for (;;) {
    ### at: "f=$f value=$value   pending f=".join(',',@f)." value=".join(',',@value)

    my $term = ($seq_ith[$f] ||= $seq->ith($f));
    ### $term

    if ($value % $term) {
      ### not divisible ...
      if ($term > $value) {
        ### term bigger than remainder, backtrack ...
        if (@value) {
          $value = pop @value;
          $f = pop @f;
        } else {
          return 0;
        }
      } else {
        $f++;
      }
    } else {
      ### divisible ...
      push @value, $value;
      push @f, $f+1;
      $value /= $term;
      if ($value <= 1) {
        return 1;
      }
      $f += $distinct;
    }
  }
  $f++;
}

1;
__END__

L<Math::NumSeq::Primorials>

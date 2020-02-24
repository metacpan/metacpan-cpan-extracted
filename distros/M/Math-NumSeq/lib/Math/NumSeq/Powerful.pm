# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::Powerful;
use 5.004;
use strict;
use List::Util 'min';

use vars '$VERSION','@ISA';
$VERSION = 74;
use Math::NumSeq 7; # v.7 for _is_infinite()
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
# use Smart::Comments;


# use constant name => Math::NumSeq::__('Powerful Numbers');
use constant i_start => 1;

sub description {
  my ($self) = @_;
  if (ref $self) {
    return ("Integers with $self->{'powerful_type'} prime factors "
            . ($self->{'power'} == 2 ? "squared"
               : $self->{'power'} == 3 ? "cubed"
               : "$self->{'power'}th power")
            . " or higher.");
  } else {
    return Math::NumSeq::__('Integers which some prime factors squared or higher.');
  }
}

use constant parameter_info_array =>
  [
   { name    => 'powerful_type',
     type    => 'enum',
     default => 'some',
     choices => ['some','all'],
     choices_display => [Math::NumSeq::__('Some'),
                         Math::NumSeq::__('All'),
                        ],
     # description => Math::NumSeq::__(''),
   },
   { name    => 'power',
     type    => 'integer',
     default => '2',
     minimum => 2,
     width   => 2,
     # description => Math::NumSeq::__(''),
   },
  ];

sub values_min {
  my ($self) = @_;
  return ($self->{'powerful_type'} eq 'some'
          ? 2 ** $self->{'power'}
          : 1);
}

# cf A168363 squares and cubes of primes, the primitives of "all" power=2
#    A112526 0/1 charactistic of A001694 all k>=2
#    A005934 highly powerful - new highest product of exponents
#    A005117 the squarefrees, all k<2, complement of some k>=2
#    A001597 perfect powers m^k for k>=2
#    A052485 weak, non-powerful, some k<2
#
my %oeis_anum = (some => [undef,
                          undef,
                          'A013929', # 2 non squarefree, divisible by some p^2
                          'A046099', # 3 non cubefree, divisible by some p^3
                          'A046101', # 4 non 4th-free
                          # OEIS-Catalogue: A013929
                          # OEIS-Catalogue: A046099 power=3
                          # OEIS-Catalogue: A046101 power=4
                         ],
                 all  => [undef,
                          undef,
                          'A001694', # 2 all p^k has k >= 2
                          'A036966', # 3 all p^k has k >= 3
                          'A036967', # 4 all p^k has k >= 4
                          'A069492', # 5 all p^k has k >= 5
                          'A069493', # 6
                          # OEIS-Catalogue: A001694 powerful_type=all
                          # OEIS-Catalogue: A036966 powerful_type=all power=3
                          # OEIS-Catalogue: A036967 powerful_type=all power=4
                          # OEIS-Catalogue: A069492 powerful_type=all power=5
                          # OEIS-Catalogue: A069493 powerful_type=all power=6
                         ],
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'powerful_type'}}->[$self->{'power'}];
}

sub pred {
  my ($self, $value) = @_;
  ### SquareFree pred(): $value

  $value = abs($value);
  unless ($value >= 0) {
    return 0;
  }
  if ($value <= 0xFFFF_FFFF) {
    $value = "$value"; # numize Math::BigInt for speed
  }

  if ($value < 1 || $value != int($value)) {
    return 0;
  }

  my $power = $self->{'power'};
  my $limit = "$value" ** (1/$power) + 3;
  my $reduced_limit = min($limit,65535);

  my $p = 2;
  for ( ; $p <= $reduced_limit; $p += 2-($p==2)) {
    next if ($value % $p);
    ### prime factor: $p

    $value /= $p;
    my $count = 1;
    while (($value % $p) == 0) {
      ++$count;
      if ($count >= $power && $self->{'powerful_type'} eq 'some') {
        ### found some factor of desired power ...
        return 1;
      }
      $value /= $p;
    }
    if ($count < $power && $self->{'powerful_type'} ne 'some') {
      ### all/all_prim prime without desired power ...
      return 0;
    }

    $limit = "$value" ** (1/$power) + 3;
    $reduced_limit = min($limit,65535);
    ### divided out: "$p, now value=$value, new limit $limit reduced $reduced_limit"
  }
  ### final value: $value

  if ($p < $limit) {
    ### value too big to check ...
    return undef;
  }
  if ($self->{'powerful_type'} eq 'some') {
    ### some, no suitable power found ...
    return 0;
  } else {
    ### all, ok if reduced to value==1 ...
    return ($value == 1);
  }
}

1;
__END__

# Did this work?
#
# # each 2-bit vec() value is
# #    0   unset
# #    1   composite
# #    2,3 square factor
# 
# sub rewind {
#   my ($self) = @_;
#   $self->{'i'} = $self->i_start;
#   $self->{'done'} = 0;
#   _restart_sieve ($self, 20);
# }
# sub _restart_sieve {
#   my ($self, $hi) = @_;
#   ### _restart_sieve() ...
#   $self->{'hi'} = $hi;
#   $self->{'string'} = "\0" x (($hi+1)/4);  # 4 of 2 bits each
#   vec($self->{'string'}, 0,2) = 2;  # N=0 square
#   vec($self->{'string'}, 1,2) = 1;  # N=1 composite
#   # N=2,N=3 primes
# }
# 
# sub next {
#   my ($self) = @_;
# 
#   my $v = $self->{'done'};
#   my $sref = \$self->{'string'};
#   my $hi = $self->{'hi'};
# 
#   for (;;) {
#     ### consider: "v=".($v+1)."  cf done=$self->{'done'}"
#     if (++$v > $hi) {
#       _restart_sieve ($self,
#                       ($self->{'hi'} = ($hi *= 2)));
#       $v = 2;
#       ### restart to v: $v
#     }
# 
#     my $vec = vec($$sref, $v,2);
#     ### $vec
#     if ($vec == 0) {
#       ### prime: $v
# 
#       # composites
#       for (my $j = 2*$v; $j <= $hi; $j += $v) {
#         ### composite: $j
#         vec($$sref, $j,2) |= 1;
#       }
#       # powers
#       my $vpow = $v ** $self->{'power'};
#       for (my $j = $vpow; $j <= $hi; $j += $vpow) {
#         ### power: $j
#         vec($$sref, $j,2) = 2;
#       }
#     }
# 
#     if ($vec >= 2 && $v > $self->{'done'}) {
#       ### ret: $v
#       $self->{'done'} = $v;
#       return ($self->{'i'}++, $v);
#     }
#   }
# }

=for stopwords Ryde Math-NumSeq squarefrees non-squarefrees squareful

=head1 NAME

Math::NumSeq::Powerful -- numbers with certain prime powers

=head1 SYNOPSIS

 use Math::NumSeq::Powerful;
 my $seq = Math::NumSeq::Powerful->new (powerful_type => 'some',
                                        power => 2);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is integers with a minimum prime power.  The C<powerful_type> option (a
string) can be

    "some"       some exp >= power
    "all"        all exp >= power

The default is "some" and power=2, which means there must be some prime
factor which is a square or higher,

    # default powerful_type="some" power=2

    4, 8, 9, 12, 16, 18, 20, ...
    starting i=1

These are the non-squarefrees.  The squarefrees have no square factor, and
these non-squarefrees have at least one square factor.  (Sometimes this is
called "squareful" but this can be confused with the "all" style where all
primes must be a square or better.)

The "all" option with power=2 demands that all primes are square or higher.

    powerful_type="all" power=2
    1, 4, 8, 9, 16, 25, 27, 32, 36, ...

Notice for example 12=2*2*3 is excluded because its prime factor 3 is not
squared or better.  1 is included on the basis that it has no prime factors.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Powerful-E<gt>new (powerful_type =E<gt> $str, power =E<gt> $integer)>

Create and return a new sequence object.  C<powerful_type> can be

    "some"    (the default)
    "all"

C<power> must be 2 or more.

=back

=head2 Random Access

=over

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> has prime powers of the given type.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Squares>,
L<Math::NumSeq::Cubes>,
L<Math::NumSeq::PowerPart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut


#     "all_prim"   all 2*power > exp >= power
# This sequence is multiplicative in the sense that for any two elements their
# product is also in the sequence.  The "all_prim" selects just primitive
# elements meaning those not a product of earlier terms.  This means each
# prime has an exponent expE<gt>=power but expE<lt>2*power.

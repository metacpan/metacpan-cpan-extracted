# Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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


# http://www.cs.uwaterloo.ca/journals/JIS/VOL12/Broughan/broughan16.pdf
# http://www.borve.org/primeness/FOP.html


package Math::NumSeq::PrimeIndexPrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::Primes;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant description => Math::NumSeq::__('The primes whose index in the list of primes is also a prime.');
use constant characteristic_increasing => 1;

use constant parameter_info_array =>
  [ { name      => 'level',
      share_key => 'prime_index_primes_level',
      display   => Math::NumSeq::__('Level'),
      type      => 'integer',
      default   => 2,
      minimum   => 0,
      width     => 2,
      description => Math::NumSeq::__('The level of prime-index repetition.'),
    },
    { name      => 'level_type',
      display   => Math::NumSeq::__('Level Type'),
      type      => 'enum',
      default   => 'minimum',
      choices   => ['minimum','exact',
                    # 'maximum'
                   ],
    },
  ];

#------------------------------------------------------------------------------
# cf A175247 primes at non-composite, including 1 as non-composite
#    A007097 a(n+1) = a(n)'th prime, growing recurrence
#    A058010 order of primeness diagonal

my %oeis_anum
  = (minimum => [
                 'A000027',  # level=0  # integers 1 up
                 # OEIS-Other: A000027 level=0

                 'A000040',  # level=1  # all primes, F(p) >= 1
                 # OEIS-Other: A000040 level=1

                 # OEIS-Catalogue array begin
                 'A006450',  #          # prime index primes  F(p) >= 2
                 'A038580',  # level=3  # F(p) >= 3
                 'A049090',  # level=4  # F(p) > 3 is F(p) >= 4
                 'A049203',  # level=5
                 'A049202',  # level=6
                 'A057849',  # level=7
                 'A057850',  # level=8
                 'A057851',  # level=9
                 'A057847',  # level=10
                 'A058332',  # level=11
                 'A093047',  # level=12 # F(p)>11 is F(p)>=12
                 'A093046',  # level=13
                 # OEIS-Catalogue array end
                ],
     exact => [
               # OEIS-Catalogue array begin
               'A018252',  # level_type=exact level=0   # composites 1 up
               'A007821',  # level_type=exact level=1   # primes at compos ind
               'A049078',  # level_type=exact           # F(p)=2
               'A049079',  # level_type=exact level=3
               'A049080',  # level_type=exact level=4
               'A049081',  # level_type=exact level=5
               # OEIS-Catalogue array end
              ],
    );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'level_type'}}->[$self->{'level'}];
}

#------------------------------------------------------------------------------

# First value of desired order is exactly that order, so same values_min()
# for level_type "minimum" or "exact".
#
sub values_min {
  my ($self) = @_;

  if (! defined $self->{'values_min'}) {
    my $seq = Math::NumSeq::Primes->new;
    my $target = 1;
    foreach (1 .. $self->{'level'}) {
      my ($i, $prime);
      do {
        ($i, $prime) = $seq->next;
      } until ($i >= $target);
      $target = $prime;
    }
    $self->{'values_min'} = $target;
  }
  return $self->{'values_min'};
}

# primes, level=0
# 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
# 1  2  3  4   5   6   7   8   9  10  11  12  13
#    ^  ^      ^       ^               ^       ^
# prime-index-primes, level=1
#    3, 5,    11,     17,             31,     41,             59,     67,
#
# prime-index-primes, level=2
# 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
# 1  2  3  4   5   6   7   8   9  10  11  12  13  14  15  16  17
#       ^      ^                       ^                       ^
#       5,    11,                     31,                     59,

#
# exact level=1 A007821 2,7,13,19,23,29,37,43,47,53,61,71,73,79,
# exact level=2 A049078 3,17,41,67,83,109,157,191,211,241,283,353,
#

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'target'} = 1;
  $self->{'seqs'} = [ map { Math::NumSeq::Primes->new } 1 .. $self->{'level'} ];
  if ($self->{'level_type'} ne 'minimum') {
    $self->{'initial_seq'} = Math::NumSeq::Primes->new; # pop @$seqs;
    $self->{'initial_prime'} = 0;
    $self->{'target'} = 0;
  }
}

sub next {
  my ($self) = @_;
  ### PrimeIndexPrimes next(): $self->{'i'}

  my $seqs = $self->{'seqs'};
  my $target = $self->{'target'}++;

  if ($self->{'level_type'} eq 'maximum') {

  } else {
    if ($self->{'level_type'} eq 'exact') {
      while ($target >= $self->{'initial_prime'}) {
        (undef, $self->{'initial_prime'}) = $self->{'initial_seq'}->next;
        $target = $self->{'target'}++;
      }
    }
    foreach my $seq (@$seqs) {
      ### $target
      my ($i, $prime);
      do {
        ($i, $prime) = $seq->next;
      } until ($i >= $target);
      $target = $prime;
    }
  }
  return ($self->{'i'}++, $target);
}

sub value_to_i_estimate {
  my ($self, $value) = @_;

  foreach (1 .. $self->{'level'}) {
    $value = Math::NumSeq::Primes->value_to_i_estimate($value);
  }
  if ($self->{'level_type'} eq 'exact') {
    $value = $value - Math::NumSeq::Primes->value_to_i_estimate($value);
  }
  return int($value);
}

1;
__END__

=for stopwords Ryde Math-NumSeq primeness

=head1 NAME

Math::NumSeq::PrimeIndexPrimes -- primes with prime number indexes

=head1 SYNOPSIS

 use Math::NumSeq::PrimeIndexPrimes;
 my $seq = Math::NumSeq::PrimeIndexPrimes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the sequence of primes which are at prime indexes,

    3, 5, 11, 17, 31, 41, 59, 67, 83, 109, 127, 157, 179, 191, ...
    starting i=1

The primes begin

    index  prime
      1      2
      2      3     <--+ primes at prime indexes
      3      5     <--+
      4      7        |
      5     11     <--+
      6     13        |
      7     17     <--+
      8     19

The primes marked "<--" have an index which is prime too.

=head2 Level

Optional C<level> controls how many repetitions of the prime indexing is to
be applied.  The level is based on the order of primeness by Neil Fernandez
in the PrimeIndexOrder sequence.

=over

L<http://www.borve.org/primeness/FOP.html>

=back

The default is level=2, asking for primes with an order of primeness
E<gt>=2.  level=1 gives all primes, and level=0 gives all integers.

The next higher level=3 restricts to primes whose index is prime, and then
in addition demands that prime is at an index which is prime.

    level => 3
    5, 11, 31, 59, 127, 179, 277, 331, 431, 599, ...

Successive levels filter further and the remaining values soon become quite
large.  For example level=11 starts at 9737333 (and is quite slow to
generate).

=head2 Level Exact

Optional C<level_type=E<gt>'exact'> asks for values which have exactly
C<level> as their order of primeness.

With the default level 2 this means primes whose index is a prime, but then
the index of that index is not a prime, ie. the iterations of prime index
stops there,

    level_type => 'exact', level => 2
    3, 17, 41, 67, 83, 109, 157, 191, 211, 241, 283, 353, ...

Here 11 is not in the sequence because its order of primeness is 3, since 11
is at index 5, 5 is at index 3, 3 is at index 2.

level_type=exact,level=1 means those primes which are at composite indexes.
This is all the primes which are not prime index primes, ie. primes not in
the default prime-index-primes sequence.

    level_type => 'exact', level => 1
    2, 7, 13, 19, 23, 29, 37, 43, 47, 53, 61, 71, 73, 79, ...

level_type=exact,level=0 means integers which have order of primeness 0,
which is the composites, ie. the non-primes.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PrimeIndexPrimes-E<gt>new (level =E<gt> $n)>

Create and return a new sequence object.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  C<$value> can be
any size.

=back

=head1 Formulas

=head2 Value to i Estimate

The i for a given value can be estimated by applying the prime-to-i estimate
of the plain primes sequence (L<Math::NumSeq::Primes/Value to i Estimate>)
according to the C<level> parameter.

    repeat level many times
      value = Primes value_to_i_estimate(value)

    if level_type eq "exact"
      value = value - Primes value_to_i_estimate(value)

    i_estimate = value

For example the default level=2 prime index primes applies the Primes
estimate twice.  A given value is presumed to be a prime, it's index is
estimated.  Then that index also has to be a prime (so the original value is
a prime index prime), and the index of that is again estimated by the Primes
module.

For C<level_type=E<gt>'exact'> the final index must be a composite, as
opposed to "minimum" where it can be either prime or composite.  That
restriction means an extra final Composite value to i, derived from the
Primes by simply

    Composite value_to_i_estimate(x)
      = value - Primes value_to_i_estimate(x)

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::PrimeIndexOrder>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016 Kevin Ryde

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

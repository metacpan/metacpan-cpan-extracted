# Copyright 2011, 2012, 2013, 2014, 2016, 2018, 2019 Kevin Ryde

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


package Math::NumSeq::ConcatNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');

*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::NumAronson 8; # new in v.8
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;


# use constant name => Math::NumSeq::__('Concatenate Numbers');
use constant description =>
  Math::NumSeq::__('Concatenate i and i+1, eg. at i=99 value is 99100.');
use constant default_i_start => 0;

use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [
   {
    name    => 'concat_count',
    type    => 'integer',
    default => 2,
    minimum => 1,
    width   => 2,
    description => Math::NumSeq::__('How many numbers to concatenate.'),
   },
   Math::NumSeq::Base::Digits->parameter_info_list, # radix
  ];

#------------------------------------------------------------------------------

# cf A033308 - concatenate primes
#    A127421 - concat 2 starting n=1 for value 1, 12, 23 etc so n-1,n
#    A074991 -   concat 3, divided by 3
#    A030655 - concat 2, step by 2, starting 1
#    A193492 - concat 4
#    A077298 - concat 5, step by 5
#
#    A098080 - digits making an increasing sequence
#
#    A058935 - binary concatenate successively, to make bignums
#    A047778 - binary in decimal
#    A001855 - binary number of digits
#    A007908 - decimal concatenate successively, to make bignums
#
my @oeis_anum;

$oeis_anum[1]->[2]->[2] = 'A087737'; # binary i,i+1 i=1
# OEIS-Catalogue: A087737 radix=2 i_start=1

# A127421 OFFSET=1 so i-1,i rather than i,i+1
# $oeis_anum[0]->[10]->[2] = 'A127421'; # decimal i,i+1 starting i=1
# # OEIS-Catalogue: A127421

$oeis_anum[1]->[10]->[2] = 'A001704'; # decimal i,i+1 starting i=1
# OEIS-Catalogue: A001704 i_start=1

$oeis_anum[1]->[10]->[3] = 'A001703'; # decimal i,i+1,i+2 starting i=1
# OEIS-Catalogue: A001703 i_start=1 concat_count=3

$oeis_anum[1]->[10]->[4] = 'A279204'; # decimal i,i+1,i+2,i+3 starting i=1
# OEIS-Catalogue: A279204 i_start=1 concat_count=4

$oeis_anum[1]->[10]->[10] = 'A287747'; # decimal i,i+1,... 10 values starting i=1
# OEIS-Catalogue: A287747 i_start=1 concat_count=10

sub oeis_anum {
  my ($self) = @_;

  if ($self->{'concat_count'} == 1) {
    # all integers, starting from 0 or 1 according to i_start
    require Math::NumSeq::All;
    return $self->Math::NumSeq::All::oeis_anum;
    # OEIS-Other: A001477 concat_count=1
    # OEIS-Other: A001477 concat_count=1 radix=2
    # OEIS-Other: A000027 concat_count=1 i_start=1
    # OEIS-Other: A000027 concat_count=1 i_start=1 radix=2
  }

  return $oeis_anum[$self->i_start]
    ->[$self->{'radix'}]
      ->[$self->{'concat_count'}];
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### ConcatNumbers ith(): $i
  if ($i < 0) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  my $radix = $self->{'radix'};
  my $count = $self->{'concat_count'};

  my $value = $i + --$count;
  ### initial value: "$value"

  if ($count > 0) {
    my $v = $value;
    if ($count > 1 && ! ref $i) {
      $value = _to_bigint($value);
    }

    my ($pow) = _round_down_pow ($v, $radix);
    ### $pow
    my $value_pow = $pow * $radix;

    for (;;) {
      ### $v
      $v -= 1;
      $value += $value_pow * $v;
      last unless --$count > 0;

      if ($v < $pow) {
        $pow /= $radix;
      }
      $value_pow *= $pow * $radix;
    }
    ### final value: "$value"

    ### assert: $v == $i
  }

  return $value;
}

# sub _NOTWORKING_pred {
#   my ($self, $value) = @_;
#   ### ConcatNumbers pred(): $value
# 
#   my $int = int($value);
#   if ($value != $int) {
#     return 0;
#   }
# 
#   my $count = $self->{'concat_count'};
#   if ($count <= 1) {
#     return ($count == 1);
#   }
# 
#   my $radix = $self->{'radix'};
#   my ($pow, $exp) = _round_down_pow ($int, $radix);
# 
#   $exp = int(($exp+1)/$count);
#   $pow = $radix ** $exp;
# 
#   my $v = $value % $pow;
#   my $rem = $value;
#   for (;;) {
#     $rem = int($rem/$pow);
#     $v2 = $rem % $pow;
#   }
#   ### half exp: $exp
#   ### half pow: $pow
#   ### high: int($value/$pow)
#   ### low: $value % $pow
# 
# #  return ( + 1 == ());
# }

# 123124 round down pow=100_000 exp=5 want to chop low 3 digits
# 999_1000 round down pow=100_0000 exp=6 want to chop low 4 digits
# so floor (exp+2)/2
#
# 123_124_125 round down pow=100_000_000 exp=8 want to chop low 6 digits
# 999_1000_1001 round down pow=100_0000_0000 exp=4+4+2=10 want to chop low 8
# so floor (exp+2)*2/3
#
# 123_124_125_126 round down pow=100_000_000_000 exp=11 want to chop low 9
# 999_1000_1001_1002 round down pow=100_0000_0000_0000 exp=14 chop low 12
# so floor (exp+2)*3/4
#
# usual case multiple of k digits, get exp=k*ilen-1 so ilen=(exp+1)/k
# in between round up, so ilen=(exp+1+k-1)/k = 1+floor(exp/k)
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate(): "$value"

  my $radix = $self->{'radix'};
  my $count = $self->{'concat_count'};
  $value = int($value);

  my ($pow, $exp) = _round_down_pow ($value, $radix);
  # if $value==infinity then $exp==$pow==infinity here

  $exp += 1;
  my $ilen = int($exp/$count);
  ### $ilen

  if ($exp % $count) {
    ### intermediate accumulation, treat as i=100-1 ...
    return $radix ** $ilen - 1;
  } else {
    ### keep high ilen digits of value ...
    return int ($value / ($radix ** ($exp-$ilen)))
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq Concat

=head1 NAME

Math::NumSeq::ConcatNumbers -- concatenate digits of i, i+1

=head1 SYNOPSIS

 use Math::NumSeq::ConcatNumbers;
 my $seq = Math::NumSeq::ConcatNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The concatenation of i and i+1 as digits, starting from i=0,

    1, 12, 23, 34, 45, 56, 67, 78, 89, 910, 1011, 1112, ...

The default is decimal, or optional C<radix> parameter selects another base.

Since the two i and i+1 usually have the same number of digits, the
resulting concatenated value has an even number of digits.  The exception is
at i=9 i+1=10, or i=99 i+1=100, etc, i=99..99 when the resulting value has
an odd number of digits.

Being an even number of digits makes power gaps between for instance 89 and
1011, then 998999 and 10001001.

=head2 Concat Count

Option C<concat_count =E<gt> $c> selects how many of i,i+1,i+2,i+3,etc are
concatenated.  For example C<concat_count =E<gt> 3> gives

    12, 123, 234, 345, 456, 567, 678, 789, 8910, 91011, 101112, 111213, ...

C<concat_count =E<gt> 1> means all integers (the same as L<Math::NumSeq::All>).

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for the behaviour common to all path classes.

=over 4

=item C<$seq = Math::NumSeq::ConcatNumbers-E<gt>new ()>

=item C<$seq = Math::NumSeq::ConcatNumbers-E<gt>new (radix =E<gt> $r, concat_count =E<gt> $c)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the concatenation of C<$i>, C<$i+1>, etc.

=cut

# =item C<$bool = $seq-E<gt>pred($value)>
# 
# Return true if C<$value> is a concatenation of consecutive integers.

=back

=head1 SEE ALSO

L<Math::NumSeq::All>,
L<Math::NumSeq::AllDigits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2018, 2019 Kevin Ryde

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

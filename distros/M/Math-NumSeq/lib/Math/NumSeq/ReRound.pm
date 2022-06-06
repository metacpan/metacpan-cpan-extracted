# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::ReRound;
use 5.004;
use strict;
use POSIX 'ceil';
use List::Util 'max';

use vars '$VERSION','@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Repeated Rounding');
use constant description => Math::NumSeq::__('Repeated rounding up to multiple of N, N-1, ..., 1.');
use constant values_min => 1; # at i=1
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [
   { name    => 'extra_multiples',
     display => Math::NumSeq::__('Extra Multiples'),
     type    => 'integer',
     default => '0',
     minimum => 0,
     width   => 2,
      description => Math::NumSeq::__('Extra multiples to round up at each stage.'),
   },
  ];

#------------------------------------------------------------------------------
# cf A007952 sieve+1
#    A099361 sieve by primes
#    A099204 sieve by primes
#    A099207 sieve by primes
#    A099243 sieve by primes
#    A002960 square sieve
#
#    A056533 sieve out even every 2nd,4th,6th,etc
#    A039672 sieve fibonacci style i+j prev terms
#    A056530 Flavius Josephus after 2nd round
#    A056531 Flavius Josephus after 4th round
#    A119446 cf A100461
#
#    A113749 k multiples
#
my @oeis_anum
  = (
     # OEIS-Catalogue array begin
     'A002491',   #                     # Mancala stones
     'A000960',   # extra_multiples=1   # Flavius Josephus
     'A112557',   # extra_multiples=2   # more Mancala stones ...
     'A112558',   # extra_multiples=3   # more Mancala stones ...
     'A113742',   # extra_multiples=4   # more Mancala stones ...
     'A113743',   # extra_multiples=5   # more Mancala stones ...
     'A113744',   # extra_multiples=6   # more Mancala stones ...
     'A113745',   # extra_multiples=7   # more Mancala stones ...
     'A113746',   # extra_multiples=8   # more Mancala stones ...
     'A113747',   # extra_multiples=9   # more Mancala stones ...
     'A113748',   # extra_multiples=10  # more Mancala stones ...
     # OEIS-Catalogue array end
    );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'extra_multiples'}];
}

#------------------------------------------------------------------------------


sub ith {
  my ($self, $i) = @_;
  ### ReRound ith(): $i

  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }

  my $extra_multiples = $self->{'extra_multiples'};
  ### $extra_multiples

  for (my $m = $i-1; $m >= 1; $m--) {
    ### add: (-$i % $m) + $extra_multiples*$m

    $i += (-$i % $m) + $extra_multiples*$m;
  }
  return $i;
}

# 1,3,7,13,19
# 2->2+1=3
# 3->4+2=6->6+1=7
# 4->6+m3=9->10+m2=12->12+m1=13
#
# next = prev + (-prev mod m) + k*m
# next-k*m = prev + (-prev mod m)

sub pred {
  my ($self, $value) = @_;
  ### ReRound pred(): $value

  my $extra_multiples = $self->{'extra_multiples'};

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value <= 1 || $value != int($value)) {
    return ($value == 1);
  }

  # special case m=1 stepping down to an even number
  if (($value -= $extra_multiples) % 2) {
    return 0;
  }

  my $m = 2;
  while ($value > $m) {
    ### at: "value=$value  m=$m"

    if (($value -= $extra_multiples*$m) <= 0) {
      ### no, negative: $value
      return 0;
    }
    ### subtract to: "value=$value"

    ### rem: "modulus=".($m+1)." rem ".($value%($m+1))
    my $rem;
    if (($rem = ($value % ($m+1))) == $m) {
      ### no, remainder: "rem=$rem  modulus=".($m+1)
      return 0;
    }

    $value -= $rem;
    $m++;
  }

  ### final ...
  ### $value
  ### $m

  return ($value == $m);
}

# # v1.02 for leading underscore
use constant 1.02 _PI => 4*atan2(1,1); # similar to Math::Complex pi()

# value = m*1+m*2+m*3+...+m*i
# value = m*i*(i+1)/2
# i*i + i - 2v/m = 0
# i = (-1 + sqrt(1 + 4*2v/m)) / 2
#   = -1/2 + sqrt(1 + 4*2v/m)/2
#   = -1/2 + sqrt(4 + 2v/m)
# i -> sqrt(2v/m)
#
# as extra_multiples dominates the estimate changes from
#     extra_multiples==0         est = sqrt(pi*value)
# up to
#     extra_multiples==m large   est = sqrt(2*value/m)
#
# What formula that progressively morphs pi to 2/m ?
#
sub value_to_i_estimate {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }

  if ($self->{'extra_multiples'} == 0) {
    # use sqrt(pi)~=296/167 to preserve Math::BigInt
    return int( (sqrt(int($value)) * 296) / 167);
  } else {
    return int(sqrt(int (2 * $value / $self->{'extra_multiples'})));

    # return int(sqrt(int ($value * _PI/($self->{'extra_multiples'}+1)**2))
    #            + ($self->{'extra_multiples'} > 0
    #               ? -0.5 + sqrt(4 + 2*$value/$self->{'extra_multiples'})
    #               : 0));
  }



  # # large extra_multiples
  # return int(sqrt(int (2 * $value
  #                      / ($self->{'extra_multiples'}+1))));
  #
  # return int(sqrt(int (($value * 355)
  #                      / (113 * ($self->{'extra_multiples'}+1)))));
  #
  #
  # # extra_multiples==14
  # return int(sqrt(int (_PI * $value)) * 429/2048); #        429=13*11*3
  #
  # # extra_multiples==12
  # return int(sqrt(int (_PI * $value)) * 462/2048); # 231/1024) # 11*7*3=231
  #
  # # extra_multiples==10
  # return int(sqrt(int (_PI * $value))) * 126/512; # 63/256;  # 7*3*2=126
  #
  # # extra_multiples==8
  # return int(sqrt(int (_PI * $value))) * 35/128;             # 7*5=35
  #
  # # extra_multiples==6
  # return int(sqrt(int (_PI * $value))) * 10/32; # 5/16       # 5*2=10
  #
  # # extra_multiples==4
  # return int(sqrt(int (_PI * $value))) * 3/8;
  #
  # # extra_multiples==2
  # return int(sqrt(int (_PI * $value))) * 1/2;
  #
  # # extra_multiples==0
  # return int(sqrt(int (_PI * $value))) * 1/1;
  #
  #  2 1
  #  4 11
  #  6 1010
  #  8 100011
  # 10 1111110
  # 12 111001110
  # 14 110101101

  #
  #
  # # extra_multiples==11
  # return int(sqrt(int (1/_PI * $value)) * 1024/1386); # 512/693);
  #
  # # extra_multiples==9
  # return int(sqrt(int (1/_PI * $value)) * 256/315);
  #
  # # extra_multiples==7
  # return int(sqrt(int (1/_PI * $value)) * 64/70); # 32/35;
  #
  # # extra_multiples==5
  # return int(sqrt(int (1/_PI * $value))) * 16/15;
  #
  # # extra_multiples==3
  # return int(sqrt(int (1/_PI * $value))) * 4/3;
  #
  # # extra_multiples==1
  # return int(sqrt(int (1/_PI * $value ))) * 2/1;

}

1;
__END__

=for stopwords Math-NumSeq Ryde 2nd 4th Flavius ReRound ok

=head1 NAME

Math::NumSeq::ReRound -- sequence from repeated rounding up

=head1 SYNOPSIS

 use Math::NumSeq::ReRound;
 my $seq = Math::NumSeq::ReRound->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the sequence of values formed by repeatedly rounding up to a
multiple of i-1, i-2, ..., 2, 1.

    1, 2, 4, 6, 10, 12, 18, 22, 30, 34, 42, 48, 58, 60, 78, ...
    starting i=1

For example i=5 start at 5, round up to a multiple of 4 to give 8, then
round up to a multiple of 3 to give 9, then round up to a multiple of 2 to
give 10, and finally round up to a multiple of 1 is no change value=10 at
i=5.

When rounding up if a value is already a suitable multiple then it's
unchanged.  That always happens for the final round up to a multiple of 1,
but it can happen in intermediate places too.  For example i=4 start at 4,
round up to a multiple of 3 to give 6, then 6 round up to a multiple of 2 is
6 unchanged since it's already a multiple of 2.

For iE<gt>=3 the last step is always a round up to a multiple of 2 so the
values are all even.  They're also always increasing and end up
approximately

    value ~= i^2 / pi

though there's values both bigger and smaller than this approximation.

=head2 Extra Multiples

The C<extra_multiples> option can round up by extra multiples at each step.
For example,

    # extra_multiples => 2
    1, 4, 10, 18, 30, 42, 58, 78, 102, 118, 150, 174, ...

At i=5 start 5, round up to a multiple of 4 which is 8, and then two extra
multiples of 4 to give 16, then round up to a multiple of 3 is 18 and two
extra multiples of 3 to give 24, then round up to a multiple of 2 is 24
already and two extra multiples of 2 gives 28, then round up to a multiple
of 1 is 28 already and two extra multiples of 1 gives finally value=30 at
i=5.

When C<extra_multiples> is 0 the final round up to a multiple of 1 can be
ignored, but with extra multiples there's a fixed extra amount to add there.

=head2 Sieve

The sequence can also be constructed as a sieve.  Start with the integers,

    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,...

Delete every 2nd, starting counting from the 2nd.  So at 2 keep that 2, drop
value 3, keep value 4, drop value 5, etc, which leaves the even integers.

    1,2,4,6,8,10,12,14,16,18,20,22,24,26,28...

Then delete every 3rd starting counting from the 3rd.  So starting at value
4 keep 4,6, drop 8, keep 10,12, drop 14, etc.

    1,2,4,6,10,12,16,18,22,24,28,...

Then delete every 4th starting counting from the 4th.  So starting at 6 keep
6,10,12, drop 16, keep 18,22,24, drop 28, etc.

    1,2,4,6,10,12,18,22,24,...

And so on deleting every increasing multiples.  At the "delete every k-th"
stage the first 2*k-1 values are unchanged, so the procedure can stop when
the stage is past the desired number of values.

This sieve process makes it clear the values always increase, which is not
quite obvious from the repeated rounding-up.

=head2 Flavius Josephus Sieve

When C<extra_multiples =E<gt> 1> the sequence is the sieve of Flavius
Josephus,

    # extra_multiples => 1
    1, 3, 7, 13, 19, 27, 39, 49, 63, 79, 91, 109, 133, 147, 181, ...

This sieve again begins with the integers

    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,...

Drop every 2nd number,

    1,3,5,7,9,11,13,15,17,19,...

Drop every 3rd from the remaining, so

    1,3,7,9,13,15,19,...

Drop every 4th from the remaining, so

    1,3,7,13,15,19,...

And so on, dropping an every increasing multiple.  Unlike the sieve for the
default case above the start point for the drop counting is the start of the
remaining values.

This case can also be calculated by working downwards from the square i^2

    value = i^2
    for m = i-1 down to 1
      value = next smaller multiple of m < value

The next smaller multiple is strictly less than value, so if value is
already a multiple of m then it changes to value-m, the next lower multiple.
The last step is m=1.  In that case value is always a multiple of 1 and the
next lower multiple always means value-1.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::ReRound-E<gt>new ()>

=item C<$seq = Math::NumSeq::ReRound-E<gt>new (extra_multiples =E<gt> $integer)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i> rounded up to multiples of i-1,...,2.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a ReRound value.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.  See L</Value to i
Estimate> below.

=back

=head1 FORMULAS

=head2 Predicate

The rounding procedure can be reversed to test for a ReRound value.

    for i=2,3,4,etc
      value -= extra_multiples*i
      if value < 0 then not a ReRound

      remainder = value mod i
      if remainder==i-1 then not a ReRound

      value -= remainder    # round down to multiple of i

    stop when value <= i
    is a ReRound if value==i, and i is its index

For example to test 28, it's a multiple of 2, so ok for the final rounding
step.  It's predecessor in the rounding steps was a multiple of 3, so round
down to a multiple of 3 which is 27.  The predecessor of 27 was a multiple
of 4 so round down to 24.  But at that point there's a contradiction because
if 24 was the value then it's already a multiple of 3 and so wouldn't have
gone up to 27.  This case where a round-down gives a multiple of both i and
i-1 is identified by the remainder = value % i == i-1.  If value is already
a multiple of i-1 then subtracting an i-1 would leave it still so.

=head2 Value to i Estimate

For the default sequence as noted above the values grow roughly as

    value ~= i^2 / pi

so can be estimated as

    i ~= sqrt(value) * sqrt(pi)

There's no need for high accuracy in pi.  The current code uses an
approximation sqrt(pi)~=296/167 for faster calculation if the value is a
C<Math::BigInt> or C<Math::BigRat>.

    i ~= sqrt(value) * 296/167

C<extra_multiples =E<gt> m> adds a fixed amount i*m at each step, for a
total

    value_EM = m + 2*m + 3*m + 4*m + ... + i*m
             = m * i*(i+1)/2

As m becomes large this part of the value dominates, so

    value =~ m * i*(i+1)/2     for large m

    i =~ sqrt(value*2/m)

As m increases the factor sqrt(pi) progressively morphs towards sqrt(2/m).
For m even it might be sqrt(pi)/2, 3/8*sqrt(pi), 5/16*sqrt(pi),
35/128*sqrt(pi), etc, and for m odd it might be 2*sqrt(1/pi),
4/3*sqrt(1/pi), 16/15*sqrt(1/pi), 32/35*sqrt(1/pi), 256/315*sqrt(1/pi), etc.
What's the pattern?

The current code uses the "large m" formula for any mE<gt>0, which is no
more than roughly a factor 1.25 too big.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::ReReplace>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

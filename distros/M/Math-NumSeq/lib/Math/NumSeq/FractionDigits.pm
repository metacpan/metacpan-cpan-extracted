# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::FractionDigits;
use 5.004;
use strict;
use List::Util 'max';

use Math::NumSeq;
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq::Base::Digits;
@ISA = ('Math::NumSeq::Base::Digits');

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Fraction Digits');
use constant description => Math::NumSeq::__('A given fraction number written out in binary.');
use constant i_start => 0;

use constant parameter_info_array =>
  [ Math::NumSeq::Base::Digits->parameter_info_list,
    { name       => 'fraction',
      display    => Math::NumSeq::__('Fraction'),
      type       => 'string',
      type_hint  => 'fraction',
      width      => 10,
      default    => '5/29', # an arbitrary choice
      description => Math::NumSeq::__('The fraction to show, for example 5/29.  Press Return when ready to display the expression.'),
    },
  ];

#------------------------------------------------------------------------------

my @oeis_anum;

$oeis_anum[10] =
  {
   # Any fixed-length repeating sequence is a fraction of some sort in
   # some radix.  There's many more not expressed here, and constant
   # digits sequences can be done by more than one fraction, etc.

   '1/7'   => 'A020806',   # 1/7 decimal
   # OEIS-Catalogue: A020806 fraction=1/7

   # OFFSET=1, unlike other fractions which are OFFSET=0
   # # '22/7'  => 'A068028',   # 22/7 decimal
   # # # OEIS-Catalogue: A068028 fraction=22/7

   '1/9'   => 'A000012',   # 1/9 decimal, is just 1,1,1,1
   # pending something better for a constant sequence
   # OEIS-Catalogue: A000012 fraction=1/9

   '1/11'  => 'A010680',   # 1/11 decimal
   # OEIS-Catalogue: A010680 fraction=1/11

   # OEIS-Catalogue: A021015 fraction=1/11 # duplicate of A010680
   # OEIS-Catalogue: A021016 fraction=1/12
   # OEIS-Catalogue: A021017 fraction=1/13
   # OEIS-Catalogue: A021018 fraction=1/14
   # OEIS-Catalogue: A021019 fraction=1/15
   # OEIS-Catalogue: A021020 fraction=1/16

   '1/17'  => 'A007450',   # 1/17 decimal
   # OEIS-Catalogue: A007450 fraction=1/17

   # Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits has A021022
   # through A021999, being 1/18 to 1/995.
   # A022000 is not 1/996, that fraction missing apparently.
   #
   # OEIS-Catalogue: A022001 fraction=1/997
   # OEIS-Catalogue: A022002 fraction=1/998
   # OEIS-Catalogue: A022003 fraction=1/999

   # OFFSET ?
   # '1/999999'  => 'A172051',
   # # OEIS-Catalogue: A172051 fraction=1/999999

   #---------------

   # extra 10 in the denominator to give the leading 0
   '13717421/1111111110' => 'A010888',  # .012345678912...
   # OEIS-Catalogue: A010888 fraction=13717421/1111111110

   #---------------

   # constant digits 3,3,3,...
   '10/3' => 'A010701',
   # ENHANCE-ME: of course can generate 3s more efficiently just as a
   # constant sequence, in which case would prefer that over this for the
   # catalogue.
   # OEIS-Catalogue: A010701 fraction=10/3
  };
sub oeis_anum {
  my ($self) = @_;
  ### oeis_anum() ...
  my $radix = $self->{'radix'};
  my $fraction = $self->{'fraction'};
  if (my $anum = $oeis_anum[$radix]->{$fraction}) {
    return $anum;
  }
  if ($radix == 10
      && $fraction =~ m{(\d+)/(\d+)}
      && $1 == 1
      && $2 >= 12 && $2 <= 999 && $2 != 996
      && ($2 % 10) != 0
      && $2 != 25) {
    return 'A0'.($2 + 21016-12);
  }
  ### $fraction
  return undef;
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my $radix = $self->{'radix'};
  my $fraction = $self->{'fraction'};

  my $num = 0;  # 0/0 if unrecognised
  my $den = 0;
  ($num, $den) = ($fraction =~ m{^\s*
                                 ([.[:digit:]]+)?
                                 \s*
                                 (?:/\s*
                                   ([.[:digit:]]+)?
                                 )?
                                 \s*$}x);
  if (! defined $num) { $num = 1; }
  if (! defined $den) { $den = 1; }
  ### $num
  ### $den
  $fraction = "$num/$den";

  # decimals like 1.5/2.75 become 150/275
  {
    ($num, my $num_decimals) = _to_int_and_decimals ($num);
    ($den, my $den_decimals) = _to_int_and_decimals ($den);
    $num .= '0' x max(0, $den_decimals - $num_decimals);
    $den .= '0' x max(0, $num_decimals - $den_decimals);
  }

  if (max(length($num),length($den)) >= length(int (~0 / $radix))) {
    $num = _to_bigint($num);
    $den = _to_bigint($den);
  }

  # increase den so first digit is 0 to radix-1
  while ($den != 0 && $num >= $den) {
    $den *= $radix;
  }

  ### create
  ### $num
  ### $den
  $self->{'fraction'} = $fraction;
  $self->{'initial_num'} = $num;
  $self->{'den'} = $den;

  $self->rewind;
  return $self;
}

sub _to_int_and_decimals {
  my ($n) = @_;
  if ($n =~ m{^(\d*)\.(\d*?)0*$}) {
    return ($1 . $2,
            length($2));
  } else {
    return ($n, 0);
  }
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'num'} = $self->{'initial_num'};
}

sub next {
  my ($self) = @_;

  my $num   = $self->{'num'} || return;  # num==0 exact radix frac
  my $den   = $self->{'den'} || return;  # den==0 invalid
  my $radix = $self->{'radix'};
  ### FractionDigits next(): "$self->{'i'}  $num/$den"

  $num *= $radix;
  my $quot = int ($num / $den);
  $self->{'num'} = $num - $quot * $den;

  ### $quot
  ### rem: $self->{'num'}

  return ($self->{'i'}++, $quot);
}

sub ith {
  my ($self, $i) = @_;

  if ($i < 0 || _is_infinite($i)) {
    return undef;
  }

  my $radix = $self->{'radix'};
  my $den = $self->{'den'};
  my $num = (($self->{'initial_num'} * _modpow ($self->{'radix'}, $i, $den))
             % $den);
  return int (($num * $radix) / $den);
}

use constant 1.02 _UV_MAX_SQRT => do {
  my $uv_max = ~0;
  my $bit = 1;
  my $shift = 0;
  for (;;) {
    $shift++;
    my $try_bit = $bit << 1;
    if ($uv_max >> $shift < $try_bit) {
      last;
    }
    $bit = $try_bit;
  }
  ### $bit

  my $uv_max_sqrt = $bit;
  for (;;) {
    $bit >>= 1;
    last if $bit == 0;
    my $try_sqrt = $uv_max_sqrt + $bit;
    if (int($uv_max / $try_sqrt) <= $try_sqrt) {
      $uv_max_sqrt = $try_sqrt;
    }
  }

  ### $uv_max_sqrt
  ### uv_max_sqrt: sprintf '%#X', $uv_max_sqrt
  ### squared: $uv_max_sqrt*$uv_max_sqrt
  ### squared: sprintf '%#X', $uv_max_sqrt*$uv_max_sqrt

  $uv_max_sqrt
};

sub _modpow {
  my ($base, $exp, $mod) = @_;
  ### _modpow(): "$base $exp $mod"

  my $ret = 1;
  if (ref $mod || $mod > _UV_MAX_SQRT) {
    return _to_bigint($base)->bmodpow($exp,$mod);
  }

  # only if base and mod have no common factor ...
  # $exp %= $mod-1;

  my $power = $base;
  for (;;) {
    ### $exp
    if ($exp % 2) {
      ### step: "power=$power"
      $ret = ($ret * $power) % $mod;
    }
    $exp = int($exp/2) || last;
    $power = ($power*$power) % $mod;
  }
  return $ret;
}


# ENHANCE-ME: only some digits occur, being the modulo den residue class
# containing num.
# sub pred {
#   my ($self, $value) = @_;
# }
#
# =item C<$bool = $seq-E<gt>pred($value)>
# 
# Return true if C<$value> occurs as a digit in the fraction.

1;
__END__

=for stopwords Ryde Math-NumSeq radix-1 ie xx.yy num radix Ith bmodpow

=head1 NAME

Math::NumSeq::FractionDigits -- the digits of a fraction p/q

=head1 SYNOPSIS

 use Math::NumSeq::FractionDigits;
 my $seq = Math::NumSeq::FractionDigits->new (fraction => '2/11');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of digits which are a given fraction.  For example 1/7 in
decimal, being 0.14285714...

    1, 4, 2, 8, 5, 7, 1, 4, etc

After any integer part, the fraction digits are a repeating sequence.  If
the fraction is num/den and is in least terms (num and den have no common
factor) then the period is either den-1 or some divisor of den-1.

A particular a repeating sequence a,b,c,d,a,b,c,d,etc can be cooked up with
fraction abcd/9999, the denominator being as many 9s as digits to repeat.
For a base other than decimal the "9" is radix-1.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::FractionDigits-E<gt>new (fraction =E<gt> $f)>

=item C<$seq = Math::NumSeq::FractionDigits-E<gt>new (fraction =E<gt> $f, radix =E<gt> $r)>

Create and return a new sequence object giving the digits of C<$f>.  C<$f>
is a string "num/den", or a decimal "xx.yy",

    2/29
    29.125
    1.5/3.25

The default sequence values are decimal digits, or the C<radix> parameter
can select another base.  (But the C<fraction> parameter is still decimal.)

If the numerator or denominator of the fraction is bigger than fits Perl
integer calculations then C<Math::BigInt> is used automatically.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th digit of the fraction.

=back

=head1 FORMULAS

=head2 Next

For a given num/den, with num < den, the next digit below the radix point is
formed by

    num *= radix               # now 0 <= num/den < radix
    quot,rem = num divide den
    digit = quot               # 0 <= digit < radix
    new num = rem

=head2 Ith

For an arbitrary digit i, the repeated num*=radix can be applied by a
modular powering

    rpower = radix^i mod den
    num = num * rpower mod den

i here acts as a count of how many digits to skip.  For example if i=0 then
rpower=1 and doesn't change the numerator at all.  With that big skip the
digit is then the same as for "next" above,

    num *= radix             # now 0 <= num/den < radix
    digit = floor(num/den)   # 0 <= digit < radix

The usual modular powering techniques can be applied to calculate radix^i
mod den.  C<Math::BigInt> has a bmodpow which is used in the code if the
inputs are big.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::SqrtDigits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

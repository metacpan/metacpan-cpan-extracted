# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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


# Christopher Williamson, "An Overview of the Thue-Morse Sequence",
# www.math.washington.edu/~morrow/336_12/papers/christopher.pdf


package Math::NumSeq::DigitSumModulo;
use 5.004;
use strict;
use List::Util 'sum';

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
#use Smart::Comments;


use Math::NumSeq::Base::Digits;
use constant parameter_info_array =>
  [ Math::NumSeq::Base::Digits->parameter_info_list,
    { name        => 'modulus',
      share_key   => 'modulus_0',
      type        => 'integer',
      display     => Math::NumSeq::__('Modulus'),
      default     => 0,
      minimum     => 0,
      width       => 3,
      description => Math::NumSeq::__('Modulus, or 0 to use the radix.'),
    },
  ];

use constant i_start => 0;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;
sub values_max {
  my ($self) = @_;
  if (my $modulus = $self->{'modulus'}) {
    return $modulus - 1;
  }
  return $self->{'radix'} - 1;
}

# use constant name => Math::NumSeq::__('Digit Sum Modulo');
sub description {
  my ($self) = @_;
  if (ref $self) {
    my $radix = $self->{'radix'};
    my $modulus = ($self->{'modulus'} ? $self->{'modulus'} : $radix);
    return Math::NumSeq::__('Sum digits of i in base ') . $radix
      . Math::NumSeq::__(', then that sum taken modulo ') . $modulus
        . ($radix == 2 && $modulus == 2
           ? Math::NumSeq::__(", which means bitwise parity.")
           : Math::NumSeq::__('.'));
  } else {
    return Math::NumSeq::__('Sum of the digits in the given radix, modulo that radix or a given modulus.  Eg. for binary this is the bitwise parity.');
  }
}

# cf A001969  "evil" numbers with even 1s
#    A000069  "odious" numbers with odd 1s
#    A026147  position of n'th thue-morse parity 1
#    A059448  1,0 parity of number of 0 digits when written in binary
#    A001285  Thue-Morse as 1,2
#    A010059  Thue-Morse as 1,0
#    A010060  Thue-Morse as 0,1
#    A106400  Thue-Morse as 1,-1            1, -1, -1,  1, -1,  1
#    A186032  Thue-Morse as -1,1 offset one     1,  1, -1,  1, -1
#    A108784  Thue-Morse as -1,1                1, 1,  -1,  1, -1
#    A076826  Thue-Morse as 0,2 with a(2n+1)=1 in between
#    A080813  lexico is 1,1,0,1,1,0 then thue-morse 0,1 thue-morse
#
# A143579 alternately odious and evil, permutation of the integers
# A143580 alternately, modulo 2
# seems A143580 == A010059 thue-morse 1,0
#
my %oeis_anum = ('2,2'   => 'A010060',
                 '3,3'   => 'A053838',
                 '4,4'   => 'A053839', # radix=4
                 '5,5'   => 'A053840', # radix=5
                 '6,6'   => 'A053841', # radix=6
                 '7,7'   => 'A053842', # radix=7
                 '8,8'   => 'A053843', # radix=8
                 '9,9'   => 'A053844', # radix=9
                 '10,10' => 'A053837',
                 # OEIS-Catalogue: A053837
                 # OEIS-Catalogue: A053844 radix=9
                 # OEIS-Catalogue: A053843 radix=8
                 # OEIS-Catalogue: A053842 radix=7
                 # OEIS-Catalogue: A053841 radix=6
                 # OEIS-Catalogue: A053840 radix=5
                 # OEIS-Catalogue: A053839 radix=4
                 # OEIS-Catalogue: A053838 radix=3
                 # OEIS-Catalogue: A010060 radix=2  # binary, Thue-Morse

                 '10,2' => 'A179081',
                 # OEIS-Catalogue: A179081 modulus=2

                 '2,3' => 'A071858',
                 '2,4' => 'A179868',
                 # OEIS-Catalogue: A071858 radix=2 modulus=3
                 # OEIS-Catalogue: A179868 radix=2 modulus=4

                 '3,4' => 'A051329', # ternary modulo 4
                 # OEIS-Catalogue: A051329 radix=3 modulus=4
                );
sub oeis_anum {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  my $modulus = ($self->{'modulus'} || $radix);

  if ($modulus == 1) {
    return 'A000004'; # all zeros
    # OEIS-Other: A000004 modulus=1
  }

  # radix==M+1, 2M+1 etc any radix==1modM is same as whole modulo M.
  # Including radix=odd modulus=2 is 0,1 repeating.
  if (($radix % $modulus) == 1) {
    ### ENHANCE-ME: Modulo a-num without creating object, maybe
    require Math::NumSeq::Modulo;
    return Math::NumSeq::Modulo->new(modulus=>$modulus)->oeis_anum;

    # OEIS-Other: A000035 radix=3 modulus=2     # n mod 2, parity
    # OEIS-Other: A000035 radix=5 modulus=2
    # OEIS-Other: A000035 radix=37 modulus=2
    # OEIS-Other: A010872 radix=4 modulus=3     # n mod 3
  }

  return $oeis_anum{"$radix,$modulus"};
}

# ENHANCE-ME:
# next() is +1 mod m, except when xx09 wraps to xx10 which is +2,
# or when x099 to x100 then +3, etc extra is how many low 9s
#
# sub next {
#   my ($self) = @_;
#   my $radix = $self->{'radix'};
#   my $sum = $self->{'sum'} + 1;
#   if (++$self->{'digits'}->[0] >= $radix) {
#     $self->{'digits'}->[0] = 0;
#     my $i = 1;
#     for (;;) {
#       $sum++;
#       if (++$self->{'digits'}->[$i] < $radix) {
#         last;
#       }
#     }
#   }
#   return ($self->{'i'}++, ($self->{'sum'} = ($sum % $radix)));
# }

sub ith {
  my ($self, $i) = @_;

  if (_is_infinite ($i)) {
    return $i;
  }
  my $radix = $self->{'radix'};
  return sum(0,_digit_split_lowtohigh($i,$radix))
    % ($self->{'modulus'} || $radix);
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0
          && $value <= $self->values_max);
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix Thue-Morse

=head1 NAME

Math::NumSeq::DigitSumModulo -- digit sum taken modulo a given modulus

=head1 SYNOPSIS

 use Math::NumSeq::DigitSumModulo;
 my $seq = Math::NumSeq::DigitSumModulo->new (radix => 10,
                                              modulus => 9);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sum of digits in each i, taken modulo the radix or a given modulus.  For
example at i=123 with modulus 5 the value is 1+2+3=6, mod 5 = 1.

Modulus 0, which is the default, means modulo the radix.

=head2 Thue-Morse Sequence

X<Odious numbers>X<Evil numbers>For C<radix=E<gt>2, modulus=E<gt>2> this is
the Thue-Morse "parity" sequence, being 1 if i has an odd number of 1 bits
or 0 if an even number of 1 bits.  Numbers where it's 1 are sometimes called
"odious" numbers and where it's 0 called "evil" numbers.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitSumModulo-E<gt>new (radix =E<gt> $r, modulus =E<gt> $d)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the sum of the digits in C<$i> written in C<radix>, modulo the
C<modulus>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> might occur as value in the sequence, which means
simply C<$value >= 0> and C<$value E<lt>= modulus> (the given C<modulus> or
the C<radix> if modulus=0).

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>,
L<Math::NumSeq::MephistoWaltz>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

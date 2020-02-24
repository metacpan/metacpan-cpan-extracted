# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::SqrtDigits;
use 5.004;
use strict;
use Carp;
use Math::NumSeq;

use vars '$VERSION','@ISA';
$VERSION = 74;

use Math::NumSeq::Base::Digits;
@ISA = ('Math::NumSeq::Base::Digits');

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Square Root Digits');
use constant description => Math::NumSeq::__('The square root of a given number written out in decimal or a given radix.');
use constant i_start => 1;
use constant parameter_info_array =>
  [
   {
    name    => 'sqrt',
    display => Math::NumSeq::__('Sqrt'),
    type    => 'integer',
    default => 2,
    minimum => 2,
    width   => 5,
    description => Math::NumSeq::__('Number to take the square root of.  If this is a perfect square then there\'s just a handful of digits, non squares go on infinitely.'),
   },
   Math::NumSeq::Base::Digits->parameter_info_list,
  ];

#------------------------------------------------------------------------------
# cf
#   A020807 - sqrt(1/50) decimal
#   A020811 - sqrt(1/54) decimal
#   A010503 - sqrt(1/2) decimal == sqrt(2)/2 = sqrt(50)/10
#   A155781 - log15(22) decimal
#   A011368 - 16^(1/9) decimal
#
#   A092855 - the bit positions of sqrt(2)-1 in binary
#   A029683 - nth digit of cbrt(n)
#
my @oeis_anum;

# sqrt 2
$oeis_anum[2]->[2] = 'A004539';   # base 2, sqrt2
$oeis_anum[3]->[2] = 'A004540';   # base 3, sqrt2
$oeis_anum[4]->[2] = 'A004541';   # base 4, sqrt2
$oeis_anum[5]->[2] = 'A004542';   # base 5, sqrt2
$oeis_anum[6]->[2] = 'A004543';   # base 6, sqrt2
$oeis_anum[7]->[2] = 'A004544';   # base 7, sqrt2
$oeis_anum[8]->[2] = 'A004545';   # base 8, sqrt2
$oeis_anum[9]->[2] = 'A004546';   # base 9, sqrt2
$oeis_anum[10]->[2] = 'A002193';   # decimal, sqrt2
$oeis_anum[60]->[2] = 'A070197';  # base 60, sqrt2
# OEIS-Catalogue: A004539 sqrt=2 radix=2
# OEIS-Catalogue: A004540 sqrt=2 radix=3
# OEIS-Catalogue: A004541 sqrt=2 radix=4
# OEIS-Catalogue: A004542 sqrt=2 radix=5
# OEIS-Catalogue: A004543 sqrt=2 radix=6
# OEIS-Catalogue: A004544 sqrt=2 radix=7
# OEIS-Catalogue: A004545 sqrt=2 radix=8
# OEIS-Catalogue: A004546 sqrt=2 radix=9
# OEIS-Catalogue: A002193 sqrt=2
# OEIS-Catalogue: A070197 sqrt=2 radix=60

# sqrt 3
$oeis_anum[2]->[3] = 'A004547';   # base 2, sqrt3
$oeis_anum[3]->[3] = 'A004548';   # base 3, sqrt3
$oeis_anum[4]->[3] = 'A004549';   # base 3, sqrt3
$oeis_anum[5]->[3] = 'A004550';   # base 3, sqrt3
$oeis_anum[6]->[3] = 'A004551';   # base 3, sqrt3
$oeis_anum[7]->[3] = 'A004552';   # base 3, sqrt3
$oeis_anum[8]->[3] = 'A004553';   # base 3, sqrt3
$oeis_anum[9]->[3] = 'A004554';   # base 3, sqrt3
$oeis_anum[10]->[3] = 'A002194';  # decimal, sqrt3
# OEIS-Catalogue: A004547 sqrt=3 radix=2
# OEIS-Catalogue: A004548 sqrt=3 radix=3
# OEIS-Catalogue: A004549 sqrt=3 radix=4
# OEIS-Catalogue: A004550 sqrt=3 radix=5
# OEIS-Catalogue: A004551 sqrt=3 radix=6
# OEIS-Catalogue: A004552 sqrt=3 radix=7
# OEIS-Catalogue: A004553 sqrt=3 radix=8
# OEIS-Catalogue: A004554 sqrt=3 radix=9
# OEIS-Catalogue: A002194 sqrt=3

# sqrt 5
$oeis_anum[2]->[5] = 'A004555';   # base 2, sqrt5
$oeis_anum[3]->[5] = 'A004556';   # base 3, sqrt5
$oeis_anum[4]->[5] = 'A004557';   # base 4, sqrt5
$oeis_anum[5]->[5] = 'A004558';   # base 5, sqrt5
$oeis_anum[6]->[5] = 'A004559';   # base 6, sqrt5
$oeis_anum[7]->[5] = 'A004560';   # base 7, sqrt5
$oeis_anum[8]->[5] = 'A004561';   # base 8, sqrt5
$oeis_anum[9]->[5] = 'A004562';   # base 9, sqrt5
$oeis_anum[10]->[5] = 'A002163';  # decimal, sqrt5
# OEIS-Catalogue: A004555 sqrt=5 radix=2
# OEIS-Catalogue: A004556 sqrt=5 radix=3
# OEIS-Catalogue: A004557 sqrt=5 radix=4
# OEIS-Catalogue: A004558 sqrt=5 radix=5
# OEIS-Catalogue: A004559 sqrt=5 radix=6
# OEIS-Catalogue: A004560 sqrt=5 radix=7
# OEIS-Catalogue: A004561 sqrt=5 radix=8
# OEIS-Catalogue: A004562 sqrt=5 radix=9
# OEIS-Catalogue: A002163 sqrt=5

# sqrt 6
$oeis_anum[2]->[6] = 'A004609';   # base 2, sqrt6
$oeis_anum[3]->[6] = 'A004610';   # base 3, sqrt6
$oeis_anum[4]->[6] = 'A004563';   # base 4, sqrt6
$oeis_anum[5]->[6] = 'A004564';   # base 5, sqrt6
$oeis_anum[6]->[6] = 'A004565';   # base 6, sqrt6
$oeis_anum[7]->[6] = 'A004566';   # base 7, sqrt6
$oeis_anum[8]->[6] = 'A004567';   # base 8, sqrt6
$oeis_anum[9]->[6] = 'A004568';   # base 9, sqrt6
$oeis_anum[10]->[6] = 'A010464';  # decimal, sqrt6
# OEIS-Catalogue: A004609 sqrt=6 radix=2
# OEIS-Catalogue: A004610 sqrt=6 radix=3
# OEIS-Catalogue: A004563 sqrt=6 radix=4
# OEIS-Catalogue: A004564 sqrt=6 radix=5
# OEIS-Catalogue: A004565 sqrt=6 radix=6
# OEIS-Catalogue: A004566 sqrt=6 radix=7
# OEIS-Catalogue: A004567 sqrt=6 radix=8
# OEIS-Catalogue: A004568 sqrt=6 radix=9
# OEIS-Catalogue: A010464 sqrt=6

# sqrt 7
$oeis_anum[2]->[7] = 'A004569';   # base 2, sqrt7
$oeis_anum[3]->[7] = 'A004570';   # base 3, sqrt7
$oeis_anum[4]->[7] = 'A004571';   # base 4, sqrt7
$oeis_anum[5]->[7] = 'A004572';   # base 5, sqrt7
$oeis_anum[6]->[7] = 'A004573';   # base 6, sqrt7
$oeis_anum[7]->[7] = 'A004574';   # base 7, sqrt7
$oeis_anum[8]->[7] = 'A004575';   # base 8, sqrt7
$oeis_anum[9]->[7] = 'A004576';   # base 9, sqrt7
$oeis_anum[10]->[7] = 'A010465';  # decimal, sqrt7
# OEIS-Catalogue: A004569 sqrt=7 radix=2
# OEIS-Catalogue: A004570 sqrt=7 radix=3
# OEIS-Catalogue: A004571 sqrt=7 radix=4
# OEIS-Catalogue: A004572 sqrt=7 radix=5
# OEIS-Catalogue: A004573 sqrt=7 radix=6
# OEIS-Catalogue: A004574 sqrt=7 radix=7
# OEIS-Catalogue: A004575 sqrt=7 radix=8
# OEIS-Catalogue: A004576 sqrt=7 radix=9
# OEIS-Catalogue: A010465 sqrt=7

# sqrt 8
# sqrt8 in binary is sqrt2 in binary
$oeis_anum[3]->[8] = 'A004578';   # base 3, sqrt8
$oeis_anum[4]->[8] = 'A004579';   # base 4, sqrt8
$oeis_anum[5]->[8] = 'A004580';   # base 5, sqrt8
$oeis_anum[6]->[8] = 'A004581';   # base 6, sqrt8
$oeis_anum[7]->[8] = 'A004582';   # base 7, sqrt8
$oeis_anum[8]->[8] = 'A004583';   # base 8, sqrt8
$oeis_anum[9]->[8] = 'A004584';   # base 9, sqrt8
$oeis_anum[10]->[8] = 'A010466';  # sqrt8
# OEIS-Catalogue: A004578 sqrt=8 radix=3
# OEIS-Catalogue: A004579 sqrt=8 radix=4
# OEIS-Catalogue: A004580 sqrt=8 radix=5
# OEIS-Catalogue: A004581 sqrt=8 radix=6
# OEIS-Catalogue: A004582 sqrt=8 radix=7
# OEIS-Catalogue: A004583 sqrt=8 radix=8
# OEIS-Catalogue: A004584 sqrt=8 radix=9
# OEIS-Catalogue: A010466 sqrt=8

# sqrt 10
$oeis_anum[2]->[10] = 'A004585';   # base 2, sqrt10
$oeis_anum[3]->[10] = 'A004586';   # base 3, sqrt10
$oeis_anum[4]->[10] = 'A004587';   # base 4, sqrt10
$oeis_anum[5]->[10] = 'A004588';   # base 5, sqrt10
# OEIS-Catalogue: A004585 sqrt=10 radix=2
# OEIS-Catalogue: A004586 sqrt=10 radix=3
# OEIS-Catalogue: A004587 sqrt=10 radix=4
# OEIS-Catalogue: A004588 sqrt=10 radix=5

my %perfect_square = (16 => 1,
                      25 => 1,
                      36 => 1,
                      49 => 1,
                      64 => 1,
                      81 => 1);
sub oeis_anum {
  my ($self) = @_;
  ### oeis_anum() ...
  my $sqrt = $self->{'sqrt'};
  my $radix = $self->{'radix'};

  # No, the values are the same, but i is offset by the power removed ...
  # # so that sqrt(8) gives A-num of sqrt(2), etc
  # {
  #   my $radix_squared = $radix * $radix;
  #   while (($sqrt % $radix_squared) == 0) {
  #     $sqrt /= $radix_squared;
  #   }
  # }
  # # OEIS-Other: A004539 sqrt=8 radix=2
  # # OEIS-Other: A004547 sqrt=12 radix=2
  # # OEIS-Other: A004569 sqrt=28 radix=2
  # # OEIS-Other: A004585 sqrt=40 radix=2

  if ($radix == 10
      && $sqrt >= 10 && $sqrt <= 99
      && $sqrt != 50 && $sqrt != 75
      && ! $perfect_square{$sqrt}) {
    ### calculated ...
    my $offset = 0;
    foreach my $i (11 .. $sqrt) {
      $offset += ! $perfect_square{$i};
    }
    return 'A0'.(10467+$offset);
  }
  return $oeis_anum[$radix]->[$sqrt];
}
# these in sequence, but skipping perfect squares 9,16,25,36,49,64,81
# OEIS-Catalogue: A010467 sqrt=10
# OEIS-Catalogue: A010468 sqrt=11
# OEIS-Catalogue: A010469 sqrt=12
# OEIS-Catalogue: A010470 sqrt=13
# OEIS-Catalogue: A010471 sqrt=14
# OEIS-Catalogue: A010472 sqrt=15
# not 16
# OEIS-Catalogue: A010473 sqrt=17
# OEIS-Catalogue: A010474 sqrt=18
# OEIS-Catalogue: A010475 sqrt=19
# OEIS-Catalogue: A010476 sqrt=20
# OEIS-Catalogue: A010477 sqrt=21
# OEIS-Catalogue: A010478 sqrt=22
# OEIS-Catalogue: A010479 sqrt=23
# OEIS-Catalogue: A010480 sqrt=24
# not 25
# OEIS-Catalogue: A010481 sqrt=26
# OEIS-Catalogue: A010482 sqrt=27
# OEIS-Catalogue: A010483 sqrt=28
# OEIS-Catalogue: A010484 sqrt=29
# OEIS-Catalogue: A010485 sqrt=30
# OEIS-Catalogue: A010486 sqrt=31
# OEIS-Catalogue: A010487 sqrt=32
# OEIS-Catalogue: A010488 sqrt=33
# OEIS-Catalogue: A010489 sqrt=34
# OEIS-Catalogue: A010490 sqrt=35
# not 36
# OEIS-Catalogue: A010491 sqrt=37
# OEIS-Catalogue: A010492 sqrt=38
# OEIS-Catalogue: A010493 sqrt=39
# OEIS-Catalogue: A010494 sqrt=40
# OEIS-Catalogue: A010495 sqrt=41
# OEIS-Catalogue: A010496 sqrt=42
# OEIS-Catalogue: A010497 sqrt=43
# OEIS-Catalogue: A010498 sqrt=44
# OEIS-Catalogue: A010499 sqrt=45
# OEIS-Catalogue: A010500 sqrt=46
# OEIS-Catalogue: A010501 sqrt=47
# OEIS-Catalogue: A010502 sqrt=48
# # OEIS-Catalogue: A010503 sqrt=50   OFFSET=0 ...
# OEIS-Catalogue: A010504 sqrt=51
# OEIS-Catalogue: A010505 sqrt=52
# OEIS-Catalogue: A010506 sqrt=53
# OEIS-Catalogue: A010507 sqrt=54
# OEIS-Catalogue: A010508 sqrt=55
# OEIS-Catalogue: A010509 sqrt=56
# OEIS-Catalogue: A010510 sqrt=57
# OEIS-Catalogue: A010511 sqrt=58
# OEIS-Catalogue: A010512 sqrt=59
# OEIS-Catalogue: A010513 sqrt=60
# OEIS-Catalogue: A010514 sqrt=61
# OEIS-Catalogue: A010515 sqrt=62
# OEIS-Catalogue: A010516 sqrt=63
# not 64
# OEIS-Catalogue: A010517 sqrt=65
# OEIS-Catalogue: A010518 sqrt=66
# OEIS-Catalogue: A010519 sqrt=67
# OEIS-Catalogue: A010520 sqrt=68
# OEIS-Catalogue: A010521 sqrt=69
# OEIS-Catalogue: A010522 sqrt=70
# OEIS-Catalogue: A010523 sqrt=71
# OEIS-Catalogue: A010524 sqrt=72
# OEIS-Catalogue: A010525 sqrt=73
# OEIS-Catalogue: A010526 sqrt=74
# # OEIS-Catalogue: A010527 sqrt=75   OFFSET=0 for sqrt(3)/2
# OEIS-Catalogue: A010528 sqrt=76
# OEIS-Catalogue: A010529 sqrt=77
# OEIS-Catalogue: A010530 sqrt=78
# OEIS-Catalogue: A010531 sqrt=79
# OEIS-Catalogue: A010532 sqrt=80
# not 81
# OEIS-Catalogue: A010533 sqrt=82
# OEIS-Catalogue: A010534 sqrt=83
# OEIS-Catalogue: A010535 sqrt=84
# OEIS-Catalogue: A010536 sqrt=85
# OEIS-Catalogue: A010537 sqrt=86
# OEIS-Catalogue: A010538 sqrt=87
# OEIS-Catalogue: A010539 sqrt=88
# OEIS-Catalogue: A010540 sqrt=89
# OEIS-Catalogue: A010541 sqrt=90
# OEIS-Catalogue: A010542 sqrt=91
# OEIS-Catalogue: A010543 sqrt=92
# OEIS-Catalogue: A010544 sqrt=93
# OEIS-Catalogue: A010545 sqrt=94
# OEIS-Catalogue: A010546 sqrt=95
# OEIS-Catalogue: A010547 sqrt=96
# OEIS-Catalogue: A010548 sqrt=97
# OEIS-Catalogue: A010549 sqrt=98
# OEIS-Catalogue: A010550 sqrt=99


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
  $self->{'i_extended'} = $self->{'i'} = $self->i_start;
}

sub _extend {
  my ($self) = @_;

  my $sqrt = $self->{'sqrt'};
  if (defined $sqrt) {
    if ($sqrt =~ m{^\s*(\d+)\s*$}) {
      $sqrt = $1;
    } else {
      croak 'Unrecognised SqrtDigits parameter: ', $self->{'sqrt'};
    }
  } else {
    $sqrt = $self->parameter_default('sqrt');
  }

  my $calcdigits = int(2*$self->{'i_extended'} + 32);

  my $radix = $self->{'radix'};
  my $power;
  my $root;
  my $halfdigits = int($calcdigits/2);
  if ($radix == 2) {
    $root = Math::NumSeq::_to_bigint(1);
    $root->blsft ($calcdigits);
  } else {
    $power = Math::NumSeq::_to_bigint($radix);
    $power->bpow ($halfdigits);
    $root = Math::NumSeq::_to_bigint($power);
    $root->bmul ($root);
  }
  $root->bmul ($sqrt);
  ### $radix
  ### $calcdigits
  ### root of: "$root"
  $root->bsqrt();
  ### root is: "$root"

  if (my $method = $radix_to_stringize_method{$radix}) {
    $self->{'string'} = $root->$method();
    ### string: $self->{'string'}

    # one leading zero for i=1 start
    if ($radix == 2 || $radix == 16) {
      substr($self->{'string'},0,2) = '0';  # replacing 0b or 0x
    } elsif ($radix != 8) {
      # decimal insert 0, cf as_oct() already gives leading zero
      substr($self->{'string'},0,0) = '0';
    }

  } else {
    $self->{'root'} = $root;

    if ($radix > 1) {
      while ($power <= $root) {
        $power->bmul($radix);
      }
    }
    if (my $i = $self->{'i'} - 1) {
      my $div = Math::BigInt->new($radix);
      $div->bpow ($i);
      $power->bdiv ($div);
      $root->bmod ($power);
    }
    $self->{'root'} = $root;
    $self->{'power'} = $power;
  }
}

sub next {
  my ($self) = @_;

  my $radix = $self->{'radix'};
  if ($radix < 2) {
    return;
  }

  if ($self->{'i'} >= $self->{'i_extended'}) {
    $self->{'i_extended'} = int(($self->{'i_extended'} + 100) * 1.5);
    _extend($self);
  }

  ### SqrtDigits next(): $self->{'i'}
  if (defined $self->{'string'}) {
    my $i = $self->{'i'}++;
    if ($i > length($self->{'string'})) {
      ### oops, past end of string ...
      return;
    }
    ### string char: "i=$i substr=".substr($self->{'string'},$i,1)
    return ($i, hex(substr($self->{'string'},$i,1)));

  } else {
    # digit by digit from the top like this is a bit slow, should chop into
    # repeated halves instead

    my $power = $self->{'power'};
    if ($power == 0) {
      return;
    }
    my $root  = $self->{'root'};
    ### root: "$root"
    ### power: "$power"

    $self->{'power'}->bdiv($self->{'radix'});
    (my $digit, $self->{'root'}) = $root->bdiv ($self->{'power'});
    ### digit: "$digit"
    return (++$self->{'i'}, $digit);
  }
}

# ENHANCE-ME: which digits can occur? all of them?
# sub pred {
#   my ($self, $n) = @_;
#   return ($n < $self->{'radix'});
# }

1;
__END__

=for stopwords Ryde Math-NumSeq radicand BigInt radix de

=head1 NAME

Math::NumSeq::SqrtDigits -- the digits of a square root

=head1 SYNOPSIS

 use Math::NumSeq::SqrtDigits;
 my $seq = Math::NumSeq::SqrtDigits->new (sqrt => 7);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The sequence of digits which are the square root of a given radicand.  For
example sqrt(2) in decimal 1, 4, 1, 4, 2, 1, etc, being 1.41421 etc.

The default is decimal, or a C<radix> can be given.  In the current code
C<Math::BigInt> is used.  (For radix 2, 8 and 10 the specific digit
conversion methods in BigInt are used, which might be faster than the
general case.)

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SqrtDigits-E<gt>new (sqrt =E<gt> $s)>

=item C<$seq = Math::NumSeq::SqrtDigits-E<gt>new (sqrt =E<gt> $s, radix =E<gt> $r)>

Create and return a new sequence object giving the digits of C<sqrt($s)>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> might occurs as a digit in the square root.

Currently this presumes all digits occur, so simply C<$value E<gt>= 0> and
C<$value < $radix>.  For a perfect square this might be wrong, for a
non-square do all digits in fact occur?

=back

=head1 BUGS

The current code requires C<Math::BigInt> C<bsqrt()>, which may mean BigInt
1.60 or higher (which comes with Perl 5.8.0 and up).

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::SqrtEngel>,
L<Math::NumSeq::FractionDigits>

Norman L. de Forest, "The Square Root of 4 to a Million Places", at Project
Gutenberg, L<http://www.gutenberg.org/ebooks/3651>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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

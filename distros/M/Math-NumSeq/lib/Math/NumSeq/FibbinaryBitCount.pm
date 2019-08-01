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


package Math::NumSeq::FibbinaryBitCount;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;


# uncomment this to run the ### lines
# use Smart::Comments;

# use constant name => Math::NumSeq::__('Fibbinary Bit Count');
use constant description => Math::NumSeq::__('Bit count of fibbinary numbers (the numbers without adjacent 1 bits).');
use constant default_i_start => 0; # same as Fibbinary.pm
use constant characteristic_increasing => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;

use constant parameter_info_array =>
  [ { name      => 'digit',
      display   => Math::NumSeq::__('Digit'),
      share_key => 'digit_1_0_00',
      type      => 'enum',
      default   => '1',
      choices   => ['1','0','00'],
      description => Math::NumSeq::__('What digit to count.'),
    },
  ];

sub values_min {
  my ($self) = @_;
  if ($self->{'digit'} eq 'all') {
    return $self->ith($self->i_start);
  } else {
    return 0;
  }
}

#------------------------------------------------------------------------------
# cf A027941 new highest bit count positions, being Fibonacci(2i+1)-1
#    A095111 bit count parity, 1/0
#    A020908 bit count of 2^k
#
#    A072649 n occurs Fibonacci(n) times
#             is fibbinary bit length
#    A130233 maximum index k for which F(k) <= n, fibbinary length + 1
#    A131234 1 then n occurs Fib(n) times
#             is length(Zeck)+1
#    A049839 max in row of Euclidean steps table A049837
#              
#
my %oeis_anum = (1    => 'A007895', # fibbinary 1-bit count
                 0    => 'A102364',
                 '00' => 'A212278', # count "00" adjacent, possibly overlapping
                 all  => 'A072649',
                 # OEIS-Catalogue: A007895
                 # OEIS-Catalogue: A102364 digit=0
                 # OEIS-Catalogue: A212278 digit=00
                 # OEIS-Catalogue: A072649 digit=all i_start=1
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'digit'}};
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### FibbinaryBitCount ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }

  # f1+f0 > i
  # f0 > i-f1
  # check i-f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my @fibs;
  {
    my $f0 = ($i * 0);  # inherit bignum 0
    my $f1 = $f0 + 1;   # inherit bignum 1
    while ($f0 <= $i-$f1) {
      ($f1,$f0) = ($f1+$f0,$f1);
      push @fibs, $f1;
    }
  }
  ### @fibs

  my $digit = $self->{'digit'};
  if ($digit eq 'all') {
    return scalar(@fibs);
  }

  my $ones = 0;
  my $onezeros = 0;
  my $sepzeros = 0;
  while (my $f = pop @fibs) {
    ### at: "$f  i=$i"
    if ($i >= $f) {
      $ones++;
      $i -= $f;
      ### sub: "$f to i=$i"

      # never consecutive fibs, so pop without comparing to i
      if (pop @fibs) {
        $onezeros++;
      }
      unless ($i) {
        ### stop at i=0 ...
        $sepzeros += scalar(@fibs);
        last;
      }
    } else {
      $sepzeros++;
    }
  }
  ### $ones
  ### $onezeros
  ### $sepzeros

  if ($digit eq '0') {
    return $sepzeros + $onezeros;
  }
  if ($digit eq '00') {
    return $sepzeros;
  }
  return $ones;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 0 && $value == int($value));
}

1;
__END__

=for stopwords Ryde Math-NumSeq fibbinary Zeckendorf k's Ith i'th

=head1 NAME

Math::NumSeq::FibbinaryBitCount -- number of bits in each fibbinary number

=head1 SYNOPSIS

 use Math::NumSeq::FibbinaryBitCount;
 my $seq = Math::NumSeq::FibbinaryBitCount->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The number of 1 bits in the i'th fibbinary number.

    0, 1, 1, 1, 2, 1, 2, 2, 1, 2, 2, 2, 3, 1, 2, 2, 2, 3, 2, ...
    starting i=0

For example i=9 is Fibbinary "1001" so value=2 for 2 1-bits.

The count is 1 for the Fibonacci numbers, as they're "100..00" with a single
1-bit in fibbinary.

=head2 Digit 0

Option C<digit =E<gt> "0"> counts instead the 0-bits

    # digit=>"0"   starting i=0
    0, 0, 1, 2, 1, 3, 2, 2, 4, 3, 3, 3, 2, 5, 4, 4, 4, 3, 4, ...

i=0 is considered to be an empty set of digits, so it has value=0.  This is
the same as the C<DigitCount> sequence treats i=0.

=head2 Digit 00

Option C<digit =E<gt> "00"> counts the 0-bits which don't follow a 1-bit,
which is equivalent to "00" pairs (including overlapping pairs).

    # digit=>"00"   starting i=0
    0, 0, 0, 1, 0, 2, 1, 0, 3, 2, 1, 1, 0, 4, 3, 2, 2, 1, 2, ...

For example i=42 is fibbinary "10010000" (42=34+8).  It has value=4 for 4
0-bits not counting the two which immediately follow the two 1-bits.  Or
equivalently 4 "00" pairs

             v  vvv    four 0s which don't follow a 1
    i=42   10010000
            ^^ ^^      four "00" pairs, overlaps allowed
                ^^
                 ^^

Fibbinary numbers by definition never have consecutive 1-bits, so there's
always a 0 following a 1.  Excluding those leaves a count of genuinely
skipped positions.

When passing the "00" option don't forget to quote it as a string, since a
literal number 00 is an octal 0.

    $seq = Math::NumSeq::FibbinaryBitCount->new (digit => "00");  # good
    $seq = Math::NumSeq::FibbinaryBitCount->new (digit => 00);    # bad

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::FibbinaryBitCount-E<gt>new ()>

=item C<$seq = Math::NumSeq::FibbinaryBitCount-E<gt>new (digit =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the bit count of the C<$i>'th fibbinary number.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a bit count, which simply means C<$value
E<gt>= 0>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibbinary>,
L<Math::NumSeq::DigitCount>,
L<Math::NumSeq::Fibonacci>

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

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

package Math::NumSeq::Xenodromes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Numbers with all digits distinct.');

# This is i_start=1 value=0 following the OEIS and Palindromes.pm.
use constant default_i_start => 1;
use constant values_min => 0;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

sub values_max {
  my ($self) = @_;
  my $radix = $self->{'radix'};
  return _digit_join_lowtohigh([reverse 0 .. $radix-1],
                               $radix);
}

#------------------------------------------------------------------------------
# cf A036918 total count of xenodromes in base n
#    A073531 count xenodromes with n digits
#    A109303 non-xenodromes in decimal, at least one duplicate digit
#    A178788 0/1 characteristic decimal distinct digits
#    A029743 primes with distinct digits
#    A001339   count xenodromes of n digits
#       Sum (k+1)! * C(n,k), k = 0..n.
#              = Sum (k+1)! * n!/k!*(n-k)!, k = 0..n.
#              = Sum (k+1) * n!/(n-k)!, k = 0..n.
#              = Sum k = 0..n of (k+1)*n*(n-1)*...*(n-k+1)
#    A043537 how many distinct digits

# OFFSET=1 for value=0
my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,     #   # 0
                 undef,     #   # 1
                 undef,     #   # radix=2 no seq with 0,1,2 only
                 'A023798', # radix=3
                 'A023799', # radix=4
                 'A023800', # radix=5
                 'A023801', # radix=6
                 'A023802', # radix=7
                 'A023803', # radix=8
                 'A023804', # radix=9
                 'A010784', #
                 'A023805', # radix=11
                 'A023806', # radix=12
                 'A023807', # radix=13
                 'A023808', # radix=14
                 'A023809', # radix=15
                 'A023810', # radix=16
                 # OEIS-Catalogue array end
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'digits'} = [ -1 ];
  $self->{'skip'} = [ '' ];
}
sub next {
  my ($self) = @_;

  my $radix = $self->{'radix'};
  my $digits = $self->{'digits'}; # arrayref of integers
  my $skip = $self->{'skip'}; # arrayref of strings

  ### Xenodromes next() ...
  ### $digits

  my $pos = 0;
  for (;;) {
    ### at: "pos=$pos digits=".join(',',@$digits)

    my $digit = ++$digits->[$pos];
    if (vec($skip->[$pos],$digit,1)) {
      next;
    }

    if ($digit >= $radix) {
      ### ascend ...
      $pos++;
      if ($pos > $radix) {
        return;
      }
      if ($pos > $#$digits) {
        ### extend to pos: $pos
        $skip->[$pos] = '';
        $digits->[$pos] = 0;
      }
    } else {
      ### use digit: $digit
      $digits->[$pos] = $digit;
      if (--$pos < 0) {
        return ($self->{'i'}++, _digit_join_lowtohigh($digits,$radix));
      }
      ### descend to pos: $pos
      $digits->[$pos] = -1;
      $skip->[$pos] = $skip->[$pos+1];
      vec($skip->[$pos],$digit,1) = 1;
    }
  }
}

# grand total
# 9 + 9*9 + 9*9*8 + 9*9*8*7 + ... + 9*9*8*7*6*5*4*3*2*1
# = 9*(1 + 9 + 9*8 + 9*8*7 + ... + 9*8*7*6*5*4*3*2*1)
# = 9*(1 + 9*(1 + 8 + 8*7 + ... + 8*7*6*5*4*3*2*1))
# = 9*(1 + 9*(1 + 8*(1 + 7 + ... + 7*6*5*4*3*2*1)))
# = 9*(1 + 9*(1 + 8*(1 + 7*(1 + ... + 2*(1 + 1)))))

# radix=6
# 1   2     3       4         5           6
# 5 + 5*5 + 5*5*4 + 5*5*4*3 + 5*5*4*3*2 + 5*5*4*3*2*1 = 1630
# 5*(1 + 5 + 5*4 + 5*4*3 + 5*4*3*2 + 5*4*3*2*1) = 1630
# 5*(1 + 5*(1 + 4 + 4*3 + 4*3*2 + 4*3*2*1)) = 1630
# 5*(1 + 5*(1 + 4*(1 + 3*(1 + 2*(1 + 1))))) = 1630
# 5*(1 + 5*(1 + 4*(1 + 3*(1 + 2*(1 + 1))))) = 1630
#    1      2      3      4      5   6


# 0 to 9  is 10 values
# 10 to 98 is 9*9=81
sub ith {
  my ($self, $i) = @_;
  ### Xenodromes ith(): $i

  my $radix = $self->{'radix'};
  if ($i <= $radix) {
    # i=1 to i=radix
    return $i-1;
  }

  $i -= $radix+1;
  my $total = my $this = $radix-1;
  my $len = 1;
  for (;;) {
    $total *= $this;
    $this--;
    $len++;
    ### compare: "i=$i total=$total"
    if ($i < $total) {
      my @index;
      foreach my $pos ($this+1 .. $radix-1) {
        push @index, $i % $pos;      # low to high
        $i = int($i/$pos);
      }
      push @index, $i+1;
      ### @index
      ### assert: $i+1 < $radix

      my @xeno = (0 .. $radix-1);
      my @digits;
      while (@index) {
        my $i = pop @index;
        push @digits, $xeno[$i];   # high to low
        splice @xeno, $i, 1; # remove
      }
      @digits = reverse @digits;  # now low to high
      return _digit_join_lowtohigh(\@digits,$radix);
    }
    if ($len >= $radix) {
      return undef;
    }
    $i -= $total;
  }
}

sub pred {
  my ($self, $value) = @_;
  ### Xenodromes pred(): $value

  if ($value != int($value) || _is_infinite($value)) {
    return 0;
  }
  $value = abs($value);

  my %seen;
  foreach my $digit (_digit_split_lowtohigh($value, $self->{'radix'})) {
    if ($seen{$digit}++) {
      return 0;
    }
  }
  return 1;
}

# $aref->[0] low digit
sub _digit_join_lowtohigh {
  my ($aref, $radix) = @_;
  my $n = 0;
  foreach my $digit (reverse @$aref) { # high to low
    $n *= $radix;
    $n += $digit;
  }
  return $n;
}

1;
__END__

=for stopwords Ryde Math-PlanePath

=head1 NAME

Math::NumSeq::Xenodromes -- integers with all digits unique

=head1 SYNOPSIS

 use Math::NumSeq::Xenodromes;
 my $seq = Math::NumSeq::Xenodromes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is integers which have all digits different,

    0, ..., 9, 10, 12, 13, ..., 19, 20, 21, 23, 24, ...
    # starting i=1 value=0

For example 11 is not in the sequence because it has digit 1 appearing
twice.

This is a finite sequence since the maximum value with distinct digits is
9876543210.

The optional C<radix> parameter controls the base used for the digits
(default decimal).  In binary for example there's just three values, 0,
1, 2.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Xenodromes-E<gt>new ()>

=item C<$seq = Math::NumSeq::Xenodromes-E<gt>new (radix =E<gt> $integer)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th xenodrome, or C<undef> if C<$i> is beyond the end of the
sequence.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a xenodrome, ie. an integer with all digits
distinct.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Palindromes>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

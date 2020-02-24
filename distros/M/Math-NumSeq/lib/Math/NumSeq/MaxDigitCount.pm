# Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::MaxDigitCount;
use 5.004;
use strict;
use List::Util 'max';

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Maximum count of a given digit in any radix.');
use constant default_i_start => 1;
use constant parameter_info_array =>
  [
   {
    name      => 'digit',
    share_key => 'digit_0',
    type      => 'integer',
    display   => Math::NumSeq::__('Digit'),
    default   => 0,
    minimum   => 0,
    width     => 2,
    description => Math::NumSeq::__('Digit to count.'),
   },
   {
    name        => 'values_type',
    share_key => 'values_type_cr',
    type        => 'enum',
    default     => 'count',
    choices     => ['count','radix'],
    choices_display => [Math::NumSeq::__('Count'),
                        Math::NumSeq::__('Radix')],
    description => Math::NumSeq::__('Whether to give the digit count or the radix the count occurs in.'),
   },
  ];

sub characteristic_count {
  my ($self) = @_;
  return $self->{'values_type'} eq 'count';
}
sub characteristic_value_is_radix {
  my ($self) = @_;
  return $self->{'values_type'} eq 'radix';
}
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

sub values_min {
  my ($self) = @_;
  if ($self->{'values_type'} eq 'count') {
    if ($self->{'digit'} == 1) {
      return 1;
    }
  } else { # values_type=='radix'
    return 2;
  }
  return 0;
}

#------------------------------------------------------------------------------
# cf A033093 number of zeros in triangle of base 2 to n+1

my %oeis_anum;
$oeis_anum{'count'}->[0] = 'A062842'; # max 0s count
$oeis_anum{'count'}->[1] = 'A062843'; # max 1s count
# OEIS-Catalogue: A062842
# OEIS-Catalogue: A062843 digit=1
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'values_type'}}->[$self->{'digit'}];
}

#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### MaxDigitCount ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  $i = abs($i);

  my $digit = $self->{'digit'};
  my $found_count = 0;
  my $found_radix = 2;
  foreach my $radix (2 .. max($i,2)) {
    my $digits = _digit_split($i,$radix); # low to high

    ### $radix
    ### $digits

    if (@$digits < $found_count) {
      last;  # fewer digits now than already found
    }
    my $count = grep {$_ == $digit} @$digits;
    if ($count > $found_count) {
      $found_count = $count;
      $found_radix = $radix;

      # all "ddddd" digits, is the maximum possible
      # or  "X0000" when digit=0 is the maximum possible
      if ($count == scalar(@$digits) - ($digit==0)) {
        last;
      }
    }
  }
  return ($self->{'values_type'} eq 'radix' ? $found_radix : $found_count);
}

sub _digit_split {
  my ($n, $radix) = @_;
#  ### _digit_split(): $n
  my @ret;
  while ($n) {
    push @ret, $n % $radix;
    $n = int($n/$radix);
  }
  return \@ret;   # array[0] low digit
}

sub pred {
  my ($self, $value) = @_;
  unless ($value == int($value)) {
    return 0;
  }
  if ($self->{'values_type'} eq 'count') {
    if ($self->{'digit'} == 1) {
      return ($value >= 1);
    }
  } else { # values_type=='radix'
    if ($value == 1) {
      return 0;
    }
  }
  return ($value >= 0);
}

1;
__END__

=for stopwords Ryde Math-NumSeq radix Radix

=head1 NAME

Math::NumSeq::MaxDigitCount -- maximum count of a given digit in any radix

=head1 SYNOPSIS

 use Math::NumSeq::MaxDigitCount;
 my $seq = Math::NumSeq::MaxDigitCount->new (values_type => 'count');
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the maximum count of a given digit which occurs when i is written in
any radix.  The default digit is 0.

    0, 1, 1, 2, 1, 1, 1, 3, 2, 2, 1, 2, 1, 1, 1, 4, 3, 3, 2, ...
    starting i=1

For example i=15 is 1 because 15 = ternary "120" which has 1 zero, and no
other base has more than that.  i is "10" in base i itself so there's always
at least 1 zero, after i=1.

=head2 Radix

Option C<values_type =E<gt> 'radix'> gives the radix where the maximum
occurs,

    # values_type => "radix"
    2, 2, 3, 2, 2, 2, 7, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, ...

If the maximum count occurs in more than one radix the value is the smallest
where it occurs.  i=1 has no zeros in any radix and the return is 2 for
binary since the count 0 occurs in that radix.

=head2 Digit

Option C<digit =E<gt> $n> selects another digit to count, for example

    # digit => 1
    1, 1, 2, 2, 2, 2, 3, 2, 2, 2, 3, 2, 3, 3, 4, 2, 2, 2, 3, ...

For example at i=7 the count is 3 since 7 in binary is "111" with 3 digit
1s.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::MaxDigitCount-E<gt>new ()>

=item C<$seq = Math::NumSeq::MaxDigitCount-E<gt>new (digit =E<gt> $d, values_type =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the count or radix for the selected digit when C<$i> is written in
any radix.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.  This simply means
C<$value> an integer, but excluding 0 when seeking digit=1, or excluding 1
when seeking the radix.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitCount>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

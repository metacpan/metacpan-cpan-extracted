# Copyright 2012, 2015 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.


# cf A000787 - strobogramatic rotate 180
#    A007284 - symmetric flipped across horizontal line, digits 0,1,3,8 only




package Math::NumSeq::SevenSegments;
use 5.004;
use strict;
use List::Util 'min','max','sum';

use vars '$VERSION', '@ISA';
$VERSION = 3;
use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Repdigits;
*_digit_split_lowtohigh = \&Math::NumSeq::Repdigits::_digit_split_lowtohigh;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Number of segments for i written in 7-segment calculator display.');
use constant default_i_start => 0;
use constant values_min => 2; # "1" using 2 segments
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant parameter_info_array =>
  [
   {
    name    => 'seven',
    display => ('Seven'),
    type    => 'integer',
    default => 3,
    minimum => 3,
    maximum => 4,
    description => ('How many segments to count for "7".'),
   },
   {
    name    => 'nine',
    display => ('Nine'),
    type    => 'integer',
    default => 5,
    minimum => 5,
    maximum => 6,
    description => ('How many segments to count for "9".'),
   },
  ];

#------------------------------------------------------------------------------

# 7 choice of  ---     ---
#                 |   |   |
#
#                 |       |
#
# 9 choice of  ---     ---
#             |   |   |   |
#              ---     ---
#                 |       |
#                      ---
#
#         0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19
# A063720 6, 2, 5, 5, 4, 5, 5, 3, 7, 5, 8, 4, 7, 7, 6, 7, 7, 5, 9, 7, 11, 7, 10
# A006942 6, 2, 5, 5, 4, 5, 6, 3, 7, 6, 8, 4, 7, 7, 6, 7, 8, 5, 9, 8, 11, 7, 10
# A074458 6, 2, 5, 5, 4, 5, 6, 4, 7, 5
# A010371 6, 2, 5, 5, 4, 5, 6, 4, 7, 6, 8, 4, 7, 7, 6, 7, 8, 6, 9, 8, 11, 7, 10
# A000787 Strobogrammatic
# A018846 Strobogrammatic same upside down
# A018848 same upside down squares, not seven seg
# A018847 same upside down primes
# A018849 same upside down squares, seven-seg
# A053701 vertically symmetric
# A007284 - horizontally symmetric
# A074459 num segments changed to display n+1
#
# A027389 count endpoints of digits, so 0 has none, 6 has one, others have 2

my %oeis_anum = ('5,3,5' => 'A063720',
                 '6,3,6' => 'A006942',
                 '6,4,5' => 'A074458',
                 '6,4,6' => 'A010371',
                );
sub oeis_anum {
  my ($self) = @_;
  my $digit_segments = $self->{'digit_segments'};
  return $oeis_anum{join(',',@{$digit_segments}{'6','7','9'})}; # hash slice
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  ### $self
  $self->{'digit_segments'} = { 0   => 6,
                                1   => 2,
                                2   => 5,
                                3   => 5,
                                4   => 4,
                                5   => 5,
                                6   => ($self->{'six'} || 6),
                                7   => $self->{'seven'},
                                8   => 7,
                                9   => $self->{'nine'},
                                '-' => 1,  # secret support for negatives
                              };
  return $self;
}

sub ith {
  my ($self, $i) = @_;
  ### SevenSegments ith(): "$i"

  if (_is_infinite($i)) {
    return undef;
  }
  my $digit_segments = $self->{'digit_segments'};
  return sum (0, map {$digit_segments->{$_}||0} split(//,$i));
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::SevenSegments -- count of segments to display by 7-segment LED 

=head1 SYNOPSIS

 use Math::NumSeq::SevenSegments;
 my $seq = Math::NumSeq::SevenSegments->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is how many segments are lit to display i in 7-segment LEDs

    i     = 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 ...
    value = 6, 2, 5, 5, 4, 5, 6, 3, 7, 5, 8, 4, 7, 7, 6, 7, 8 ...

The segments for each digit are

     ---                 ---       ---           
    |   |         |         |         |     |   |
                         ---       ---       --- 
    |   |         |     |             |         |
     ---                 ---       ---           

     ---       ---       ---       ---       --- 
    |         |             |     |   |     |   |
     ---       ---                 ---       --- 
        |     |   |         |     |   |         |
     ---       ---                 ---           

Options C<seven =E<gt> $integer> and C<nine =E<gt> $integer> options give
how many segments those digits should be reckoned.  Sometimes 7 and 9 have
"serif" segments like the following.  C<seven =E<gt> 4> and C<nine =E<gt> 6>
gives this style

     ---        --- 
    |   |      |   |
                --- 
        |          |
                --- 

Total segments for i is similar to L<Math::NumSeq::DigitSum>, but with
digits mapped through a table of segment counts 0-E<gt>6, 1-E<gt>2,
2-E<gt>5, etc.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SevenSegments-E<gt>new ()>

=item C<$seq = Math::NumSeq::SevenSegments-E<gt>new (seven =E<gt> $int, nine =E<gt> $int)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number of segments to display C<$i> in 7-segment LEDs.

=item C<$i = $seq-E<gt>i_start ()>

Return 0, the first term in the sequence being at i=0.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>,
L<Math::NumSeq::DigitLength>,
L<Math::NumSeq::AlphabeticalLength>

L<Tk::SevenSegmentDisplay>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2015 Kevin Ryde

Math-NumSeq-Alpha is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq-Alpha is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq-Alpha.  If not, see L<http://www.gnu.org/licenses/>.

=cut

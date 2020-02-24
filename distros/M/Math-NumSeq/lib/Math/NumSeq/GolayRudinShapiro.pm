# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2019 Kevin Ryde

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


# ENHANCE-ME: "alternate" parameter for (-1)^i factor ...


package Math::NumSeq::GolayRudinShapiro;
use 5.004;
use strict;
use List::Util 'max','min';

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


# use constant name => Math::NumSeq::__('Golay-Rudin-Shapiro');
use constant default_i_start => 0;

use constant parameter_info_array =>
  [ {
     name    => 'values_type',
     share_key => 'values_type_1-101',
     type    => 'enum',  # but the code takes any pair with , between
     default => '1,-1',
     choices => ['1,-1',
                 '0,1',
                ],
     # TRANSLATORS: "1,-1" is here for translation in case the "," might look like a decimal point, otherwise can be left unchanged
     choices_display => [Math::NumSeq::__('1,-1'),
                         Math::NumSeq::__('0,1'),
                        ],
     description => Math::NumSeq::__('The values to give for even or odd parity.'),
    },
  ];

sub description {
  my ($self) = @_;
  my ($even,$odd) = (ref $self ? @{$self->{'values'}} : (1,-1));
  # ENHANCE-ME: use __x(), maybe
  return sprintf(Math::NumSeq::__('Golay/Rudin/Shapiro parity of adjacent 11 bit pairs, %s if even count %s if odd count.'),
                 $even, $odd);
}

sub characteristic_integer {
  my ($self) = @_;
  return (_is_integer($self->{'values_min'})  # the two values
          && _is_integer($self->{'values_max'}));
}
sub characteristic_pn1 {
  my ($self) = @_;
  return ($self->{'values_min'} == -1 && $self->{'values_max'} == 1);
}
sub _is_integer {
  my ($n) = @_;
  return ($n == int($n));
}

#------------------------------------------------------------------------------
# cf A022155 - positions of -1
#    A203463 - positions of +1
#    A014081 - count of 11 bit pairs
#    A020991 - position of last occurrence of n in the partial sums
#    A005943 - number of subwords length n
#
my %oeis_anum = ('1,-1' => 'A020985',  # 1 and -1
                 '0,1'  => 'A020987',  # 0 and 1
                 # OEIS-Catalogue: A020985
                 # OEIS-Catalogue: A020987 values_type=0,1
                );
sub oeis_anum {
  my ($self) = @_;
  if ($self->{'alternate'}) { return undef; }
  return $oeis_anum{$self->{'values_type'}};
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  my @values = split /,/, $self->{'values_type'};
  $self->{'values'} = \@values;
  $self->{'values_min'} = min(@values);
  $self->{'values_max'} = max(@values);
  ### $self
  return $self;
}

# ENHANCE-ME: use unpack() checksum 1-bit count as described by
# perlfunc.pod, if fit a UV or C "int" or whatever
#
#     # N & Nshift leaves bits with a 1 below them, then parity of bit count
#     $i &= ($i >> 1);
#     return (1 & unpack('%32b*', pack('I', $i)));
#
sub ith {
  my ($self, $i) = @_;
  if ($i < 0) {
    return undef;
  }
  if (_is_infinite($i)) {
    return $i;
  }

  my $prev = 0;
  my $xor = ($self->{'alternate'} && ($i&1) ? 1 : 0);
  foreach my $bit (_digit_split_lowtohigh($i,2)) {
    $xor ^= ($prev & $bit);
    $prev = $bit;
  }
  return $self->{'values'}->[$xor];
}

sub pred {
  my ($self, $value) = @_;
  return ($value == $self->{'values'}->[0]
          || $value == $self->{'values'}->[1]);
}

# Jorg Arndt fxtbook next step by
# low 1s 0111 increment to become 1000
# if even number of 1s then that's a "11" parity change
# and if the 1000 has a 1 above it then that's a parity change too
# so flip if 10..00 is an odd bit position XOR the bit above it


#------------------------------------------------------------------------------

1;
__END__


=for stopwords Ryde Math-NumSeq OEIS GRS dX dY dX,dY ie

=head1 NAME

Math::NumSeq::GolayRudinShapiro -- parity of adjacent 11 bit pairs

=head1 SYNOPSIS

 use Math::NumSeq::GolayRudinShapiro;
 my $seq = Math::NumSeq::GolayRudinShapiro->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the Golay/Rudin/Shapiro sequence of +1 or -1 according as an even or
odd number of adjacent 11 bit pairs in i.

    GRS(i) = (-1) ^ (count 11 bit pairs)

    starting from i=0
    1, 1, 1, -1, 1, 1, -1, 1, 1, 1, 1, -1, ...

The first -1 is at i=3 which is binary 11 with a single 11 bit pair, then
i=6 binary 110 likewise -1.  Later for example i=14 is binary 1110 which has
two adjacent 11 pairs (overlapping pairs count), so value=1.

The value is also the parity of the number of even-length runs of 1-bits
in i.  An even length run has an odd number of 11 pairs, so each of them is
a -1 in the product.  An odd-length run of 1-bits is an even number of 11
pairs so is +1 and has no effect on the result.

Such a parity of even-length 1-bit runs and hence the GRS sequence arises as
the "dX,dY" change for each segment of the alternate paper folding curve.
See L<Math::PlanePath::AlternatePaper/dX,dY>.

=head2 Values Type

Parameter C<values_type =E<gt> '0,1'> gives values 0 and 1, being the count
of adjacent 11s taken modulo 2, so 0 if even, 1 if odd.

    values_type => '0,1'
    0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::GolayRudinShapiro-E<gt>new ()>

=item C<$seq = Math::NumSeq::GolayRudinShapiro-E<gt>new (values_type =E<gt> $str)>

Create and return a new sequence object.  The C<values_type> parameter (a
string) can be

    "1,-1"        1=even, -1=odd
    "0,1"         0=even, 1=odd

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence, being +1 or -1 (or per
C<values_type>) according to the number of adjacent 11 bit pairs in C<$i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, which simply means C<$value
== 1> or C<$value == -1>.  Or if C<values_type=E<gt>'0,1'> then 0 or 1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::GolayRudinShapiroCumulative>,
L<Math::NumSeq::BaumSweet>,
L<Math::NumSeq::Fibbinary>

L<Math::PlanePath::AlternatePaper>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2017, 2019 Kevin Ryde

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

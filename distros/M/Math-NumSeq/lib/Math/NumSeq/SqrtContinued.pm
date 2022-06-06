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


# cf Knuth volume 2 Seminumerical Algorithms section 4.5.3 exercise 12.
#

package Math::NumSeq::SqrtContinued;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use List::Util 'min','max';

use Math::NumSeq::Squares;
use Math::NumSeq::SqrtContinuedPeriod;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Sqrt Continued Fraction');
use constant description => Math::NumSeq::__('Continued fraction expansion of a square root.');
use constant default_i_start => 0;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
# use constant characteristic_continued_fraction => 1;

use Math::NumSeq::SqrtDigits;
use constant parameter_info_array =>
  [
   Math::NumSeq::SqrtDigits->parameter_info_hash->{'sqrt'},
  ];

#------------------------------------------------------------------------------

# http://oeis.org/index/Con#confC
#
my @oeis_anum = (
                 # A010171 to A010175 have OFFSET=1, unlike the rest
                 # OFFSET=0, but still include them in the catalogue for now

                 # OEIS-Catalogue array begin
                 undef,     # sqrt=0
                 undef,     # sqrt=1
                 'A040000', # sqrt=2
                 'A040001', # sqrt=3
                 undef,     # sqrt=4
                 'A040002', # sqrt=5
                 'A040003', # sqrt=6
                 'A010121', # sqrt=7
                 'A040005', # sqrt=8
                 undef,     # sqrt=9

                 'A040006', # sqrt=10
                 'A040007', # sqrt=11
                 'A040008', # sqrt=12
                 'A010122', # sqrt=13
                 'A010123', # sqrt=14
                 'A040011', # sqrt=15
                 undef,     # sqrt=16
                 'A040012', # sqrt=17
                 'A040013', # sqrt=18
                 'A010124', # sqrt=19

                 'A040015', # sqrt=20
                 'A010125', # sqrt=21
                 'A010126', # sqrt=22
                 'A010127', # sqrt=23
                 'A040019', # sqrt=24
                 undef,     # sqrt=25
                 'A040020', # sqrt=26
                 'A040021', # sqrt=27
                 'A040022', # sqrt=28
                 'A010128', # sqrt=29

                 'A040024', # sqrt=30
                 'A010129', # sqrt=31
                 'A010130', # sqrt=32
                 'A010131', # sqrt=33
                 'A010132', # sqrt=34
                 'A040029', # sqrt=35
                 undef,     # sqrt=36
                 'A040030', # sqrt=37
                 'A040031', # sqrt=38
                 'A040032', # sqrt=39

                 'A040033', # sqrt=40
                 'A010133', # sqrt=41
                 'A040035', # sqrt=42
                 'A010134', # sqrt=43
                 'A040037', # sqrt=44
                 'A010135', # sqrt=45
                 'A010136', # sqrt=46
                 'A010137', # sqrt=47
                 'A040041', # sqrt=48
                 undef,     # sqrt=49

                 'A040042', # sqrt=50
                 'A040043', # sqrt=51
                 'A010138', # sqrt=52
                 'A010139', # sqrt=53
                 'A010140', # sqrt=54
                 'A010141', # sqrt=55
                 'A040048', # sqrt=56
                 'A010142', # sqrt=57
                 'A010143', # sqrt=58
                 'A010144', # sqrt=59

                 'A040052', # sqrt=60
                 'A010145', # sqrt=61
                 'A010146', # sqrt=62
                 'A040055', # sqrt=63
                 undef,     # sqrt=64
                 'A040056', # sqrt=65
                 'A040057', # sqrt=66
                 'A010147', # sqrt=67
                 'A040059', # sqrt=68
                 'A010148', # sqrt=69

                 'A010149', # sqrt=70
                 'A010150', # sqrt=71
                 'A040063', # sqrt=72
                 'A010151', # sqrt=73
                 'A010152', # sqrt=74
                 'A010153', # sqrt=75
                 'A010154', # sqrt=76
                 'A010155', # sqrt=77
                 'A010156', # sqrt=78
                 'A010157', # sqrt=79

                 'A040071', # sqrt=80
                 undef,     # sqrt=81
                 'A040072', # sqrt=82
                 'A040073', # sqrt=83
                 'A040074', # sqrt=84
                 'A010158', # sqrt=85
                 'A010159', # sqrt=86
                 'A040077', # sqrt=87
                 'A010160', # sqrt=88
                 'A010161', # sqrt=89

                 'A040080', # sqrt=90
                 'A010162', # sqrt=91
                 'A010163', # sqrt=92
                 'A010164', # sqrt=93
                 'A010165', # sqrt=94
                 'A010166', # sqrt=95
                 'A010167', # sqrt=96
                 'A010168', # sqrt=97
                 'A010169', # sqrt=98
                 'A010170', # sqrt=99

                 undef,     # sqrt=100
                 undef,     # sqrt=101, is 10, 20,20,rep
                 undef,     # sqrt=102, is 10, 10,20,10,20,rep
                 'A010171', # sqrt=103
                 undef,     # sqrt=104, is 10, 5,20,5,20,rep
                 undef,     # sqrt=105
                 'A010172', # sqrt=106
                 'A010173', # sqrt=107
                 'A010174', # sqrt=108
                 'A010175', # sqrt=109

                 undef,     # sqrt=110
                 'A010176', # sqrt=111
                 'A010177', # sqrt=112
                 'A010178', # sqrt=113
                 'A010179', # sqrt=114
                 'A010180', # sqrt=115
                 'A010181', # sqrt=116
                 'A010182', # sqrt=117
                 'A010183', # sqrt=118
                 'A010184', # sqrt=119

                 undef,     # sqrt=120
                 undef,     # sqrt=121
                 undef,     # sqrt=122
                 undef,     # sqrt=123
                 'A010185', # sqrt=124
                 'A010186', # sqrt=125
                 'A010187', # sqrt=126
                 'A010188', # sqrt=127
                 'A010189', # sqrt=128
                 'A010190', # sqrt=129

                 undef,     # sqrt=130
                 'A010191', # sqrt=131
                 undef,     # sqrt=132
                 'A010192', # sqrt=133
                 'A010193', # sqrt=134
                 'A010194', # sqrt=135
                 'A010195', # sqrt=136
                 'A010196', # sqrt=137
                 'A010197', # sqrt=138
                 'A010198', # sqrt=139

                 'A010199', # sqrt=140
                 'A010200', # sqrt=141
                 'A010201', # sqrt=142
                 undef,     # sqrt=143
                 undef,     # sqrt=144
                 undef,     # sqrt=145
                 undef,     # sqrt=146
                 undef,     # sqrt=147
                 undef,     # sqrt=148
                 'A010202', # sqrt=149

                 undef,     # sqrt=150
                 'A010203', # sqrt=151
                 undef,     # sqrt=152
                 'A010204', # sqrt=153
                 'A010205', # sqrt=154
                 undef,     # sqrt=155
                 undef,     # sqrt=156
                 'A010206', # sqrt=157
                 'A010207', # sqrt=158
                 'A010208', # sqrt=159

                 'A010209', # sqrt=160
                 'A010210', # sqrt=161
                 'A010211', # sqrt=162
                 'A010212', # sqrt=163
                 undef,     # sqrt=164
                 'A010213', # sqrt=165
                 'A010214', # sqrt=166
                 'A010215', # sqrt=167
                 undef,     # sqrt=168
                 undef,     # sqrt=169

                 undef,     # sqrt=170
                 undef,     # sqrt=171
                 'A010216', # sqrt=172
                 'A010217', # sqrt=173
                 'A010218', # sqrt=174
                 'A010219', # sqrt=175
                 'A010220', # sqrt=176
                 'A010221', # sqrt=177
                 'A010222', # sqrt=178
                 'A010223', # sqrt=179

                 undef,     # sqrt=180
                 'A010224', # sqrt=181
                 undef,     # sqrt=182
                 'A010225', # sqrt=183
                 'A010226', # sqrt=184
                 'A010227', # sqrt=185
                 'A010228', # sqrt=186
                 'A010229', # sqrt=187
                 'A010230', # sqrt=188
                 'A010231', # sqrt=189

                 'A010232', # sqrt=190
                 'A010233', # sqrt=191
                 'A010234', # sqrt=192
                 'A010235', # sqrt=193
                 'A010236', # sqrt=194
                 undef,     # sqrt=195
                 undef,     # sqrt=196
                 undef,     # sqrt=197
                 undef,     # sqrt=198
                 'A010237', # sqrt=199
                 # OEIS-Catalogue array end
                );

sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'sqrt'}];
}

#------------------------------------------------------------------------------

sub values_min {
  my ($self) = @_;
  _values_min_max($self);
  return $self->{'values_min'};
}
sub values_max {
  my ($self) = @_;
  _values_min_max($self);
  return $self->{'values_max'};
}
sub _values_min_max {
  my ($self) = @_;
  return if defined $self->{'values_min'};

  my $period = ($self->{'period'}
                ||= Math::NumSeq::SqrtContinuedPeriod->ith($self->{'sqrt'}));
  my $values_min = $self->{'root'};
  my $values_max = $self->{'root'};

  my $sqrt = $self->{'sqrt'};
  my $root = $self->{'root'};
  my $p = $root;
  my $q = $sqrt - $root*$root;
  while ($period-- > 0) {
    my $value = int (($root + $p) / $q);
    $p = $value*$q - $p;
    $q = ($sqrt - $p*$p) / $q;
    $values_min = min($values_min, $value);
    $values_max = max($values_max, $value);
  }
  $self->{'values_min'} = $values_min;
  $self->{'values_max'} = $values_max;
}

#------------------------------------------------------------------------------

# V = floor[ (P+sqrt(S))/Q ]
#
# (P+sqrt(S))/Q = V + 1/x
# 1/x = (P+sqrt(S) - VQ)/Q
# x = Q/(P+sqrt(S) - VQ)
#   = Q/( sqrt(S) + (P-VQ))
#   = Q*( sqrt(S) - (P-VQ)) / ( S - (P-VQ)^2)
# newP = VQ-P
# newQ = (S - (P-VQ)^2)/Q
#      = (S- (P^2 - 2PVQ + VVQQ))/Q
#      = (S - P^2 + 2PVQ - VVQQ)/Q
#      = (S - P^2)/Q + (2PVQ - VVQQ)/Q
#      = (S - P^2)/Q + 2PV - VVQ
#
# T = (S-P^2)/Q
# newQ = T + 2PV - VVQ
# newT = (S-newP^2)/newQ
#      = (S-VQ+P)/(T + 2PV - VVQ)
#
sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;

  my $sqrt = $self->{'sqrt'};
  if ($sqrt <= 0) {
    $self->{'a'} = 0;
  } else {
    # ENHANCE-ME: 'root' and 'perfect_square' one-off in new()
    my $root = $self->{'root'} = sqrt($sqrt);
    my $int = int($root);
    if ($root == $int) {
      $self->{'perfect_square'} = 1;
      $self->{'P'} = $root;
    } else {
      $self->{'P'} = 0;
      $self->{'Q'} = 1;
      $self->{'root'} = $int;
    }
  }
}
sub next {
  my ($self) = @_;
  ### SqrtContinued next() ...

  my $p = $self->{'P'};
  my $value;
  if ($self->{'perfect_square'}) {
    if (defined $p) {
      delete $self->{'P'};
      return (1, $p);
    } else {
      # perfect square no more terms
      return;
    }
  }

  # always "+ 1" to round up because sqrt() is not an integer so the
  # numerator is not divisible by the denominator
  #
  my $q = $self->{'Q'};
  $value = int (($self->{'root'} + $p) / $q);

  ### $p
  ### $q
  ### $value

  $p -= $value*$q;
  $self->{'P'} =  -$p;
  $self->{'Q'} = ($self->{'sqrt'} - $p*$p) / $q;

  ### assert: $self->{'P'} >= 0
  ### assert: $self->{'Q'} >= 0
  ### assert: $self->{'P'} <= $self->{'root'}
  ### assert: $self->{'Q'} <= 2*$self->{'root'}+1
  ### assert: (($self->{'P'} * $self->{'P'} - $self->{'sqrt'}) % $self->{'Q'}) == 0

  return ($self->{'i'}++, $value);
}

# initial
# P=0 Q=1
# value = (root+P)/Q = root
# P=value*Q = root
# Q = (S - P*P)/Q = S-P*P
sub ith {
  my ($self, $i) = @_;

  my $root = $self->{'root'};
  if ($i == 0) {
    return $root;
  }

  if ($self->{'perfect_square'} || _is_infinite($i)) {
    return undef;
  }

  my $period = ($self->{'period'}
                ||= Math::NumSeq::SqrtContinuedPeriod->ith($self->{'sqrt'}));
  $i = ($i - 1) % $period;

  my $sqrt = $self->{'sqrt'};
  my $p = $root;
  my $q = $sqrt - $root*$root;
  for (;;) {
    my $value = int (($root + $p) / $q);
    if (--$i < 0) {
      return $value;
    }
    $p = $value*$q - $p;
    $q = ($sqrt - $p*$p) / $q;
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq BigInt SqrtContinuedPeriod i'th sqrt

=head1 NAME

Math::NumSeq::SqrtContinued -- continued fraction expansion of a square root

=head1 SYNOPSIS

 use Math::NumSeq::SqrtContinued;
 my $seq = Math::NumSeq::SqrtContinued->new (sqrt => 2);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is terms in the continued fraction expansion of a square root.  It
approaches the root by

                      1   
   sqrt(S) = a[0] + ----------- 
                    a[1] +   1
                           -----------
                           a[2] +   1
                                  ----------
                                  a[3] + ...

The first term a[0] is the integer part of the root, leaving a remainder
S<0 E<lt> r E<lt> 1> which is expressed as r=1/R with S<R E<gt> 1>

                     1   
   sqrt(S) = a[0] + ---
                     R

Then a[1] is the integer part of that R, and so on recursively.

Values a[1] onwards are always a fixed-period repeating sequence.  For
example sqrt(14) is a[0]=3 and then 1,2,1,6 repeating.  For some roots a
single value repeats.  For example sqrt(2) is a[0]=1 then 2 repeating.  See
SqrtContinuedPeriod for just the length of the period.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SqrtContinued-E<gt>new (sqrt =E<gt> $s)>

Create and return a new sequence object giving the Continued expansion terms of
C<sqrt($s)>.

=item C<$value = $seq-E<gt>ith ($i)>

Return the i'th term in the continued fraction, starting from i=0 for the
integer part of the sqrt.

=item C<$i = $seq-E<gt>i_start ()>

Return 0, the first term in the sequence being i=0.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::SqrtContinuedPeriod>,
L<Math::NumSeq::SqrtDigits>,
L<Math::NumSeq::SqrtEngel>

L<Math::ContinuedFraction>

=cut

# L<Math::Pell> not on cpan is it gone or always wrong?

=pod

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

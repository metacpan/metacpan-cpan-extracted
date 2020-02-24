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

package Math::NumSeq::SlopingExcluded;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::NumAronson;
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Sloping Excluded');
use constant description => Math::NumSeq::__('Integers not occurring as sloping binary, or other selected radix.');
use constant characteristic_increasing => 1;
use constant default_i_start => 1;

use constant parameter_info_array =>
  [ { name      => 'radix',
      share_key => 'radix_2',
      type      => 'integer',
      display   => Math::NumSeq::__('Radix'),
      default   => 2,
      minimum   => 2,
      width     => 3,
      description => Math::NumSeq::__('Radix, ie. base, for the values calculation.  Default is binary (base 2).'),
    } ];

sub values_min {
  my ($self) = @_;
  return $self->{'radix'} - 1;
}

#------------------------------------------------------------------------------

# cf A102370 sloping binary
#    A103529 sloping binary which go past a new 2^k
#    A103530   diff A103529-2^k which it went past
#    A102371 sloping binary excluded [this seq]
#    A103581 sloping binary excluded, written in binary
#
#    A103582 0,1,0,1 or 0,0,1,1 etc diagonals downwards
#    A103583 0,1,0,1 or 0,0,1,1 etc diagonals upwards
#
# 1,2,7,12,29,62,123,248,505,...
my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,
                 undef,
                 'A102371', #           # starting n=1 value=1
                 'A109682', # radix=3
                 # OEIS-Catalogue array end
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

# i-k = 0 mod 2^k
# always i itself counts +2^i
# others i<2^k
#
# n=2 start -2
# 2-1 mod 2 = 1
# 2-2 mod 4 = 0 count +4 total 4-2=2
#
# n=3 start -3
# 3-1 mod 2 = 0 count +2
# 3-2 mod 4 = 1
# 3-3 mod 8 = 0 count +8 total 8+2-3=7
#
# n=4 start -4
# 4-1 mod 2 = 1
# 4-2 mod 4 = 2
# 4-3 mod 8 = 1
# 4-4 mod 16 = 0 count +16 total 16-4=13

sub ith {
  my ($self, $i) = @_;

  if (_is_infinite($i)) {
    return $i;
  }

  # inherit bignum $i, or Math::BigInt otherwise
  my $zero = $i * 0;
  if (! ref $zero) { $zero = Math::NumSeq::_to_bigint($zero) }

  my $radix = $self->{'radix'};
  my $value = ($radix + $zero) ** $i - 1;
  my $offset = $i-1;
  my $power = 1 + $zero;  # bignum 1

  foreach (1 .. $i) {
    my $next_power = $power * $radix;
    my $digit = $offset % $next_power;
    $digit -= $digit % $power;
    $value -= $digit;

    $power = $next_power;
    last if $offset < $power;  # further digits all zero
    $offset--;
  }
  return $value;



  # my $one = ($i >= 30
  #             ? Math::NumSeq::_to_bigint(1)
  #             : 1);
  # my $value = ($one << $i) - $i;
  # my $k = 1;
  # my $mask = 1;
  # while ($mask < $i) {
  #   if ((($i-$k) & $mask) == 0) {
  #     $value += $mask + 1;
  #   }
  #   $k++;
  #   $mask = ($mask << 1) + 1;
  # }
  # return $value;
}

sub pred {
  my ($self, $value) = @_;
  ### pred(): "$value"

  if (_is_infinite($value)) {
    return undef;
  }
  my $radix = $self->{'radix'};
  if ($value < $radix) {
    return ($value == $radix-1);
  }

  my ($pow, $i) = _round_down_pow($value, $radix);
  ### pow: "$pow"
  ### i: "$i"
  ### ith(i+1): $self->ith($i+1).''

  return ($value == $self->ith($i+1));
}

sub value_to_i_estimate {
  my ($self, $value) = @_;
  ### value_to_i_estimate: $value

  my $log = _blog2_estimate($value);
  if (defined $log) {
    $log *= log(2);  # to natural log
  } else {
    $log = log($value);
  }
  return int($log / log($self->{'radix'}));
}

1;
__END__

=for stopwords Ryde

=head1 NAME

Math::NumSeq::SlopingExcluded -- numbers not occurring in sloping binary

=head1 SYNOPSIS

 use Math::NumSeq::SlopingExcluded;
 my $seq = Math::NumSeq::SlopingExcluded->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

This sequence is numbers not occurring when the integers are read by
diagonal sloping lines, as per

=over

David Applegate, Benoit Cloitre, Philippe DelE<233>ham and Neil Sloane,
"Sloping Binary Numbers: A New Sequence Related to the Binary Numbers",
Journal of Integer Sequences, volume 8, article 05.3.6, 2005.
L<https://cs.uwaterloo.ca/journals/JIS/VOL8/Sloane/sloane300.html>

=cut

# Also http://arxiv.org/abs/math.NT/0505295

=back

The sequence begins

    1, 2, 7, 12, 29, 62, 123, 248, 505, 1018, 2047, 4084, 8181, ...
    starting i=1

All integers are written in binary and the read on an upwards diagonal
slope,

    Integers     Sloping     Excluded
    in Binary
    --------     -------     --------
         0         0
         1                      1 = 1
        /                      10 = 2
       1 0        11 = 3
        /
       1 1       101 = 5
      / /
     1 0 0       110 = 6
      / /
     1 0 1       101 = 5
      / /
     1 1 0       100 = 4
      /                       111 = 7
     1 1 1
    /
   1 0 0 0      1111 = 15

The authors above show the sloping values give all the integers except one
near each power 2^k.  The sequence here is those excluded values.

At "1" the sloping value is reckoned as starting from the 1" in the
following "10".  The effect is that the value "1" which is overlapped this
way is excluded.  Similarly at "11" the sloping starts from the 1 in "100"
and the "10" which is overlapped is excluded.

=head2 Radix

Optional C<radix =E<gt> $integer> parameter selects a base other than
binary.  For example ternary is

    radix => 3
    2, 7, 24, 80, 238, 723, 2183, 5653, 19674, 59042, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::SlopingExcluded-E<gt>new ()>

=item C<$seq = Math::NumSeq::SlopingExcluded-E<gt>new (radix =E<gt> $integer)>

Create and return a new sequence object.  The default is binary, or another
C<radix> can be given.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value which is sloping excluded.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a sloping excluded.

=back

=head1 SEE ALSO

L<Math::NumSeq>

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

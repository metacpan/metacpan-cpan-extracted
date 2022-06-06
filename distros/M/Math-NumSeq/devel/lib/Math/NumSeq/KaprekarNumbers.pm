# same num digits


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

package Math::NumSeq::KaprekarNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq;
use List::Util 'min';
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;
*_to_bigint = \&Math::NumSeq::_to_bigint;

use Math::NumSeq::NumAronson;
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Number of steps of the Kaprekar iteration digits ascending + digits descending until reaching a cycle.');
use constant i_start => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

use constant values_min => 0;

#------------------------------------------------------------------------------
# cf A053816 - q and r must have same num digits, so 4879 not
#
#    A045913
#    A053394 - 3-Kap
#    A053395 - 4-Kap
#    A053396 - 5-Kap
#    A053397 - 6-Kap
#    A037042 - 2-White, adjacent digits
#
#    A006887 - triples value=a+b+c breakdown of square

my @oeis_anum;
$oeis_anum[10] = 'A006886';
# OEIS-Catalogue: A006886
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'radix'}];
}

#------------------------------------------------------------------------------

use constant _UV_LIMIT => int(sqrt(~0));

sub pred {
  my ($self, $value) = @_;
  ### KaprekarNumbers pred(): $value

  if (_is_infinite($value)) {
    return undef;
  }
  if ($value < 0 || $value != int($value)) {
    return 0;
  }

  if ($value > _UV_LIMIT) {
    $value = _to_bigint($value);
  }

  my $square = $value * $value;
  my $lo = 0;
  my $radix = $self->{'radix'};
  my $power = ($value * 0) + 1; # inherit bignum 1

  # split lo/hi at any power of 10
  for (;;) {
    my $digit = $square % $radix;
    $square = int($square/$radix);
    $lo += $digit * $power;

    ### $lo
    ### $square

    if ($lo # not power of 10
        && $lo+$square == $value) {
      ### yes ...
      return 1;
    }
    last unless $square;
    $power *= $radix;
  }
  ### no ...
  return 0;
}


# sub rewind {
#   my ($self) = @_;
#   $self->{'i'} = $self->i_start;
#   $self->{'queue'} = [0];
#   $self->{'power'} = 1;
# }
# 
# sub next {
#   my ($self) = @_;
#   ### next(): "queue=".($self->{queue}->[0] || '')
# 
#   my $queue = $self->{'queue'};
#   if (! @$queue || $queue->[0] >= $self->{'power'}) {
#     ### extend: $self->{'power'}
# 
#     my $radix = $self->{'radix'};
#     my $power = $self->{'power'};
#     my $next_power = $power * $radix;
#     my %values;
#     @values{@$queue} = (); # hash slice
#     foreach my $n ($power .. $next_power-1) {
#       my $square = $n * $n;
#       $values{int($square/$next_power) + ($square%$next_power)} = undef;
# 
#       ### sum: "n=$n  ".int($square/$next_power)." + ".($square%$next_power)
#     }
#     $self->{'power'} = $next_power;
#     @$queue = sort {$a<=>$b} keys %values;  # ascending
# 
#     ### new queue: join(',',@$queue)
#   }
# 
#   return ($self->{'i'}++, shift @$queue);
# }

1;
__END__

=for stopwords Ryde Math-NumSeq Kaprekar

=head1 NAME

Math::NumSeq::KaprekarNumbers -- digits of square add to the original

=head1 SYNOPSIS

 use Math::NumSeq::KaprekarNumbers;
 my $seq = Math::NumSeq::KaprekarNumbers->new ();
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

I<In progress ...>

This is the Kaprekar numbers, those integers where adding upper and lower
digits of the square gives the integer itself.

    1, 9, 45, 55, 99, 297, 703, 999, 2223, 2728, ...

For example 45 is in the sequence because 45^2=2025 and 20+25=45.  The split
of the square can be at any digit position.  For example 5292^2=28005264 is
split as 28+005264=5292.

In the current code C<next()> is not very efficient, it merely tests
integers with C<pred()>.

=head2 Radix

An optional C<radix> parameter selects a base other than decimal.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::KaprekarNumbers-E<gt>new ()>

=item C<$seq = Math::NumSeq::KaprekarNumbers-E<gt>new (radix =E<gt> $integer)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Kaprekar number.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitSum>

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

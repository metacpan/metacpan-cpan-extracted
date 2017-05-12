# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

package Math::NumSeq::DigitLength;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;


# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Digit Length');
use constant description => Math::NumSeq::__('How many digits the number requires in the given radix.  For example binary 1,1,2,2,3,3,3,3,4, etc.');
use constant values_min => 1;
use constant i_start => 0;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 1;

use Math::NumSeq::Base::Digits
  'parameter_info_array';   # radix parameter

#------------------------------------------------------------------------------
# cf A000523 - floor(log2(n)), is bitlength-1
#    A036786 - roman numeral length <  decimal length
#    A036787 - roman numeral length == decimal length
#    A036788 - roman numeral length <= decimal length
#
my @oeis_anum = (
                 # OEIS-Catalogue array begin
                 undef,     # 0
                 undef,     # 1
                 'A070939', # radix=2
                 'A081604', # radix=3 # ternary
                 'A110591', # radix=4
                 'A110592', # radix=5
                 undef,     # 6
                 undef,     # 7
                 undef,     # 8
                 undef,     # 9
                 'A055642', # radix=10
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
  $self->{'length'} = 1;
  $self->{'limit'} = $self->{'radix'};
}
sub _UNTESTED__seek_to_i {
  my ($self, $i) = @_;
  $self->{'i'} = $i;
  my $length = $self->{'length'} = $self->ith($i);
  $self->{'limit'} = $self->{'radix'} ** ($length+1);
}
sub next {
  my ($self) = @_;
  ### DigitLength next(): $self
  ### count: $self->{'count'}
  ### bits: $self->{'bits'}

  my $i = $self->{'i'}++;
  if ($i >= $self->{'limit'}) {
    $self->{'limit'} *= $self->{'radix'};
    $self->{'length'}++;
    ### step to
    ### length: $self->{'length'}
    ### remaining: $self->{'limit'}
  }
  return ($i, $self->{'length'});
}

sub ith {
  my ($self, $i) = @_;
  if (_is_infinite($i)) {
    return $i;  # don't loop forever if $i is +infinity
  }
  my $length = 1;
  my $radix = $self->{'radix'};
  my $power = $i*0 + $radix;   # inherit possible $i bignum
  while ($i >= $power) {
    $length++;
    $power *= $radix;
  }
  return $length;
}

sub pred {
  my ($self, $value) = @_;
  return ($value >= 1 && $value == int($value));
}

# not actually documented yet ...
sub value_to_i_floor {
  my ($self, $value) = @_;

  # radix**(value-1) is the first of length $value, except 0 is the first
  # length 1
  $value = int($value)-1;
  if ($value <= 0) {
    return 0;
  }
  return $self->{'radix'} ** $value;
}
*value_to_i_estimate = \&value_to_i_floor;

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::DigitLength -- length in digits

=head1 SYNOPSIS

 use Math::NumSeq::DigitLength;
 my $seq = Math::NumSeq::DigitLength->new (radix => 10);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The length in digits of integers 0 upwards,

    1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,...

The default is decimal digits, or the optional C<radix> can give another
base.  For example ternary

    1,1,1,2,2,...,2,3,...

Zero is reckoned as a single digit 0 which is length 1.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::DigitLength-E<gt>new (radix =E<gt> $r)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return length in digits of C<$i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs as a digit length.  This means simply
C<$value E<gt>= 1> since lengths are 1 or more.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::DigitLengthCumulative>,
L<Math::NumSeq::DigitCount>,
L<Math::NumSeq::AllDigits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

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

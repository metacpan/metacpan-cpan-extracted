# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::WoodallNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Fibonacci;
*_blog2_estimate = \&Math::NumSeq::Fibonacci::_blog2_estimate;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Woodall Numbers');
use constant description => Math::NumSeq::__('Woodall numbers i*2^i-1.');
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant values_min => 1;
use constant i_start => 1; # from 1*2^1-1==1

# cf A002234 - n of Woodall primes
#    A050918 - Woodall primes values
#    A056821 - totient(woodall)
#
use constant oeis_anum => 'A003261';

# pow*i+1
my $uv_i_limit = do {
  my $max = ~0;
  my $limit = 1;

  for (my $i = 1; $i < 1000; $i++) {
    if ($i <= (($max>>1)+1) >> ($i-1)) {
      $limit = $i;
    } else {
      last;
    }
  }

  ### max   : $max
  ### woodall: (1<<$limit)*$limit+1
  ### assert: $limit*(1<<$limit)+1 <= $max

  $limit
};
### $uv_i_limit

sub rewind {
  my ($self) = @_;
  my $i = $self->{'i'} = $self->i_start;
  $self->{'power'} = 2 ** $i;
}
sub seek_to_i {
  my ($self, $i) = @_;
  ### seek_to_i(): $i
  $self->{'i'} = $i;
  if ($i >= $uv_i_limit) {
    $i = Math::NumSeq::_to_bigint($i);
  }
  $self->{'power'} = 2 ** $i;
}
sub _UNTESTED__seek_to_value {
  my ($self, $value) = @_;
  $self->seek_to_i($self->value_to_i_ceil($value));
}

# diff = (i+1)*2^(i+1)-1 - (i*2^i-1)
#      = i*2^(i+1) + 2^(i+1) - i*2^i
#      = i*(2^(i+1) - 2^i) + 2^(i+1)
#      = i*2^i + 2^(i+1)
# 2*(i*2^i-1) + 2*2^i + 1
#   = 2*i*2^i-2 + 2*2^i + 1
#   = (2*i+2)*2^i - 1
#   = (i+1)*2^(i+1) - 2
#
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  if ($i == $uv_i_limit) {
    $self->{'power'} = Math::NumSeq::_to_bigint($self->{'power'});
  }
  my $value = $self->{'power'}*$i - 1;
  $self->{'power'} *= 2;
  return ($i, $value);
}

sub ith {
  my ($self, $i) = @_;
  my $power;
  if (! ref $i && $i >= $uv_i_limit) {
    $power = Math::NumSeq::_to_bigint(1) << $i;
  } else {
    $power = 2**$i;
  }
  return $i * $power - 1;
}

sub pred {
  my ($self, $value) = @_;
  ### WoodallNumbers pred(): $value

  {
    my $int = int($value);
    if ($value != $int) { return 0; }
    $value = $int;
  }
  unless ($value >= 1
          && ($value % 2) == 1) {
    return 0;
  }

  $value += 1;  # now seeking $value == $exp * 2**$exp
  if (_is_infinite($value)) {
    return 0;
  }

  my $exp = 0;
  for (;;) {
    if ($value <= $exp || $value % 2) {
      return ($value == $exp);
    }
    $value >>= 1;
    $exp++;
  }
}

# ENHANCE-ME: round_down_pow(value,2) then exp-=log2(exp) is maybe only
# 0,+1,+2 away from being correct
#
sub value_to_i_floor {
  my ($self, $value) = @_;
  ### WoodallNumbers value_to_i_floor(): $value

  $value = int($value) + 1;  # now seeking $value == $exp * 2**$exp
  if ($value < 8) {
    return 1;
  }
  if (_is_infinite($value)) {
    return $value;
  }

  my $i = 1;
  my $power =  ($value*0) + 2;   # 2^1=2,  inherit bignum 2

  for (;;) {
    my $try_value = $i*$power;

    ### $i
    ### try_value: "$try_value"

    if ($try_value >= $value) {
      return $i - 1 + ($try_value == $value);
    }

    if ($i == $uv_i_limit) {
      $power = Math::NumSeq::_to_bigint($power);
    }
    $power *= 2;
    $i++;
  }
}

# shared by Math::NumSeq::CullenNumbers
sub value_to_i_estimate {
  my ($self, $value) = @_;

  if ($value < 1) {
    return 0;
  }

  my $i = _blog2_estimate($value);
  if (! defined $i) {
    $i = log($value) * (1/log(2));
  }
  $i -= log($i) * (1/log(2));
  return int($i);
}

1;
__END__

=for stopwords Ryde Math-NumSeq Woodall ie

=head1 NAME

Math::NumSeq::WoodallNumbers -- Woodall numbers i*2^i-1

=head1 SYNOPSIS

 use Math::NumSeq::WoodallNumbers;
 my $seq = Math::NumSeq::WoodallNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Woodall numbers i*2^i-1 starting from i=1,

    1, 7, 23, 63, 159, 383, 895, 2047, 4607, 10239, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::WoodallNumbers-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Iterating

=over

=item C<$seq-E<gt>seek_to_i($i)>

Move the current sequence position to C<$i>.  The next call to C<next()>
will return C<$i> and corresponding value.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i * 2**$i - 1>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Woodall number, ie. is equal to i*2^i-1 for
some i.

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return the index i of C<$value> or of the next Woodall number below
C<$value>.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 FORMULAS

=head2 Value to i Estimate

An easy over-estimate is l=log2(value), which reverses value=2^l.  It can be
reduced by the bit length of that l as i=l-log2(l) to get closer.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::CullenNumbers>,
L<Math::NumSeq::ProthNumbers>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

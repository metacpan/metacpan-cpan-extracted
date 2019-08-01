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

package Math::NumSeq::CullenNumbers;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Cullen Numbers');
use constant description => Math::NumSeq::__('Cullen numbers n*2^n+1.');
use constant i_start => 0;
use constant values_min => 1;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;
use constant oeis_anum => 'A002064';

# pow*i+1
my $uv_i_limit = do {
  my $max = ~0;
  my $limit = 1;

  for (my $i = 1; $i < 1000; $i++) {
    if ($i <= ($max-1) >> $i) {
      $limit = $i;
    } else {
      last;
    }
  }

  ### max   : $max
  ### cullen: (1<<$limit)*$limit+1
  ### assert: $limit*(1<<$limit)+1 <= $max

  $limit
};
### $uv_i_limit

# or maybe ...
# (i+1)*2^(i+1) + 1
#   = 2*(i+1)*2^i + 1
#   = (2i+2)*2^i + 1
#   = 2i*2^i + 2*2^i + 1
#   = 2(i*2^i + 1) -2 + 2*2^i + 1
#   = 2(i*2^i + 1) + 2*2^i - 1

sub rewind {
  my ($self) = @_;
  my $i = $self->{'i'} = $self->i_start;
  $self->{'power'} = 2 ** $i;
}
sub _UNTESTED__seek_to_i {
  my ($self, $i) = @_;
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
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  if ($i == $uv_i_limit) {
    $self->{'power'} = Math::NumSeq::_to_bigint($self->{'power'});
  }
  my $value = $self->{'power'}*$i + 1;
  $self->{'power'} *= 2;
  return ($i, $value);
}

sub ith {
  my ($self, $i) = @_;
  return $i * 2**$i + 1;
}
sub pred {
  my ($self, $value) = @_;
  ### CullenNumbers pred(): $value

  {
    my $int = int($value);
    if ($value != $int) { return 0; }
    $value = $int;
  }
  unless ($value >= 1
          && ($value % 2) == 1) {
    return 0;
  }

  $value -= 1;  # now seeking $value == $exp * 2**$exp

  if (_is_infinite($value)) {
    return 0;
  }

  my $exp = 0;
  for (;;) {
    if ($value <= $exp || $value % 2) {
      return ($value == $exp);
    }
    $value = int($value/2);
    $exp++;
  }
}

use Math::NumSeq::WoodallNumbers;
*value_to_i_estimate = \&Math::NumSeq::WoodallNumbers::value_to_i_estimate;

1;
__END__

=for stopwords Ryde Cullen Math-NumSeq ie

=head1 NAME

Math::NumSeq::CullenNumbers -- Cullen numbers i*2^i+1

=head1 SYNOPSIS

 use Math::NumSeq::CullenNumbers;
 my $seq = Math::NumSeq::CullenNumbers->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Cullen numbers i*2^i+1 starting from i=0,

    1, 3, 9, 25, 65, 161, 385, 897, 2049, 4609, 10241, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::CullenNumbers-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$i * 2**$i + 1>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a Cullen number, ie. is equal to i*2^i+1 for
some i.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 FORMULAS

=head2 Value to i Estimate

See L<Math::NumSeq::WoodallNumbers/Value to i Estimate>.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::WoodallNumbers>

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

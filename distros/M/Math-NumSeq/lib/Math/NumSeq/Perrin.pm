# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020, 2021 Kevin Ryde

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

package Math::NumSeq::Perrin;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;
use Math::NumSeq::Base::Sparse;
@ISA = ('Math::NumSeq::Base::Sparse');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Perrin Sequence');
use constant description => Math::NumSeq::__('Perrin numbers 3, 0, 2, 3, 2, 5, 5, 7, 10, etc, being P(i) = P(i-2) + P(i-3) starting from 3,0,2.');
use constant i_start => 0;
use constant characteristic_increasing_from_i => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;
use constant oeis_anum => 'A001608'; # perrin

my $uv_limit = do {
  # Float integers too in 32 bits ?
  # my $max = 1;
  # for (1 .. 256) {
  #   my $try = $max*2 + 1;
  #   ### $try
  #   if ($try == 2*$max || $try == 2*$max+2) {
  #     last;
  #   }
  #   $max = $try;
  # }
  my $max = ~0;

  # f1+f0 > max
  # f0 > max-f1
  # check i-f1 as the stopping point, so that if i=UV_MAX then won't
  # overflow a UV trying to get to f1>=i
  #
  my $f0 = 3;
  my $f1 = 0;
  my $f2 = 2;
  my $prev_f0;
  while ($f0 <= $max - $f1) {
    $prev_f0 = $f0;
    ($f0,$f1,$f2) = ($f1, $f2, $f0+$f1);
  }
  ### $prev_f0
  ### $f0
  ### $f1
  ### $f2
  ### ~0 : ~0

  $prev_f0
};

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'f0'} = 3;
  $self->{'f1'} = 0;
  $self->{'f2'} = 2;
}
sub next {
  my ($self) = @_;
  ### Perrin next(): "i=$self->{'i'}  $self->{'f0'} $self->{'f1'} $self->{'f2'}"
  (my $ret,
   $self->{'f0'},
   $self->{'f1'},
   $self->{'f2'})
   = ($self->{'f0'},
      $self->{'f1'},
      $self->{'f2'},
      $self->{'f0'}+$self->{'f1'});

  if ($ret == $uv_limit) {
    ### go to bigint ...
    $self->{'f1'} = Math::NumSeq::_to_bigint($self->{'f1'});
    $self->{'f2'} = Math::NumSeq::_to_bigint($self->{'f2'});
  }

  ### ret: "$ret"
  return ($self->{'i'}++, $ret);
}

sub value_to_i_estimate {
  my ($self, $value) = @_;

  if (_is_infinite($value)) {
    return $value;
  }

  my $f1 = ($value * 0);  # inherit bignum 0
  my $f0 = $f1 + 3;       # inherit bignum 3
  my $f2 = $f1 + 2;       # inherit bignum 2

  my $i = 0;
  for (;;) {
    ### at: "i=$i  $f0, $f1, $f2"
    if ($value <= $f0) {
      return $i;
    }
    ($f0,$f1,$f2) = ($f1,$f2, $f0+$f1);
    $i++;
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq Perrin

=head1 NAME

Math::NumSeq::Perrin -- Perrin sequence

=head1 SYNOPSIS

 use Math::NumSeq::Perrin;
 my $seq = Math::NumSeq::Perrin->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Perrin sequence,

    3, 0, 2, 3, 2, 5, 5, 7, 10, 12, 17, 22, 29, 39, 51, ...  (A001608)

which is the recurrence

    P(i) = P(i-2) + P(i-3)

starting from 3,0,2.  So for example 29 is 12+17.

    12, 17, 22, 29

     |   |       ^
     |   |       |
     +---+---add-+

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Perrin-E<gt>new (length =E<gt> $integer)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence.

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019, 2020, 2021 Kevin Ryde

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

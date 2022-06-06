# x >= y ?



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

package Math::NumSeq::PierpontPrimes;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq::Primes;
@ISA = ('Math::NumSeq::Primes');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant name => Math::NumSeq::__('Pierpont Primes');
use constant description => Math::NumSeq::__('Pierpont primes 2^x*3^y + 1.');
use constant i_start => 1;
use constant characteristic_increasing => 1;
use constant values_min => 2;

use constant parameter_info_array =>
  [
   { name    => 'offset',
     display => Math::NumSeq::__('Offset'),
     type    => 'integer',
     default => '1',
     width   => 3,
     description => Math::NumSeq::__('Offset from 2^x*3^y.'),
   },
  ];

# cf A122258 - num pierpont primes to n
#    A122257 - 0/1 according to n pierpont prime or not
#    A122260 - products of pierpont primes, multiplicative closure
#    A005105 - primes 2^x*3^y - 1
#    A069353 - all    2^i*3^j - 1

use constant oeis_anum => 'A005109';

sub rewind {
  my ($self) = @_;
  $self->SUPER::rewind;
  $self->{'pierpont_i'} = 0;
}

sub next {
  my ($self) = @_;

  if ($self->{'offset'} == 2) {
    return;
  }

  my $aseq = $self->{'pierpont_aseq'};
  my $ahead = 0;
  for (;;) {
    (undef, my $prime) = $self->SUPER::next
      or return;

    if (_is_2x3y($prime - $self->{'offset'})) {
      return (++$self->{'pierpont_i'}, $prime);
    }
  }
}

sub _is_2x3y {
  my ($value) = @_;
  until ($value % 2) {
    $value = int($value/2);
  }
  until ($value % 3) {
    $value = int($value/3);
  }
  return ($value == 1);
}

sub pred {
  my ($self, $value) = @_;

  my $vr = $value - $self->{'offset'};
  return ($vr > 0
          && $vr == int($vr)
          && ! _is_infinite($vr)
          && _is_2x3y($vr)
          && $self->SUPER::pred($value));
}

sub can {
  my ($class, $method) = @_;
  if ($method eq 'value_to_i_estimate') {
    return undef;
  }
  return $class->SUPER::can($method);
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::PierpontPrimes -- Pierpont primes

=head1 SYNOPSIS

 use Math::NumSeq::PierpontPrimes;
 my $seq = Math::NumSeq::PierpontPrimes->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The Pierpont primes, being primes of the form 2^x*3^y+1 for some integer
x,y,

    2, 3, 5, 7, 13, 17, 19, 37, 73, 97, 109, etc

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PierpontPrimes-E<gt>new ()>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is a prime of the form 2^x*3^y+1.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::SophieGermainPrimes>

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

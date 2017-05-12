# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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



# Untouchables, not sum of proper divisors of any other integer
# p*q sum S=1+p+q
# so sums up to hi need factorize to (hi^2)/4
# 


package Math::NumSeq::TotientCumulative;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Totient;
*_totient = \&Math::NumSeq::Totient::_totient;


# uncomment this to run the ### lines
#use Devel::Comments;

# use constant name => Math::NumSeq::__('Totient Cumulative');
use constant description => Math::NumSeq::__('Cumulative totient(1..n).');
use constant i_start => 0;
use constant values_min => 0;
use constant characteristic_increasing => 1;
use constant characteristic_integer => 1;

# cf A015614 totient cumulative + 1
use constant oeis_anum => 'A002088';

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'sum'} = 0;
}
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  return ($i, $self->{'sum'} += _totient($i));
}

sub ith {
  my ($self, $i) = @_;
  ### TotientCumulative ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  my $sum = 0;
  foreach my $n (1 .. $i) {
    $sum += _totient($n);
  }
  return $sum;
}

sub pred {
  my ($self, $value) = @_;
  ### TotientCumulative pred(): $value

  if (_is_infinite($value)) {
    return 0;
  }
  my $sum = 0;
  for (my $n = 0; ; $n++) {
    if ($sum == $value) {
      return 1;
    }
    if ($sum > $value) {
      return 0;
    }
    $sum += _totient($n);
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq totients ie

=head1 NAME

Math::NumSeq::TotientCumulative -- cumulative totients

=head1 SYNOPSIS

 use Math::NumSeq::TotientCumulative;
 my $seq = Math::NumSeq::TotientCumulative->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

The cumulative sum totient(1) to totient(i).

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::TotientCumulative-E<gt>new ()>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return totient(i).

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence, ie. is a sum totient(1) to
totient(i) for some i.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Totient>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

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

package Math::NumSeq::PrimeIndexOrder;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

use Math::NumSeq::Primes;


# uncomment this to run the ### lines
#use Smart::Comments;

use constant name => Math::NumSeq::__('Prime Index Order');
use constant description => Math::NumSeq::__('An order of primeness, being how many steps of prime at prime index until reaching a composite.');
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;

use constant parameter_info_array =>
  [
   { name        => 'on_values',
     share_key   => 'on_values_primes',
     display     => Math::NumSeq::__('On Values'),
     type        => 'enum',
     default     => 'all',
     choices     => ['all','primes'],
     choices_display => [Math::NumSeq::__('All'),
                         Math::NumSeq::__('Primes')],
     description => Math::NumSeq::__('Values to act on, either all integers or just the primes.'),
   },
  ];

my %values_min = (all    => 0,
                  primes => 1);
sub values_min {
  my ($self) = @_;
  return $values_min{$self->{'on_values'}};
}

my %oeis_anum = (primes => 'A049076',
                 # OEIS-Catalogue: A049076 on_values=primes
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'on_values'}};
}

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  my $seq = Math::NumSeq::Primes->new;
  $self->{'seqs'} = [ $seq ];
  $seq->next;
  $self->{'targets'} = [ 2 ];
}

sub next {
  my ($self) = @_;
  ### PrimeIndexOrder next(): $self->{'i'}

  my $i = $self->{'i'}++;
  my $targets = $self->{'targets'};

  my $level = 0;
  my $k;
  if ($self->{'on_values'} ne 'primes') {
    if ($i < $targets->[0]) {
      return ($i, 0);
    }
  }

  for (;;) {
    ($k, $targets->[$level]) = $self->{'seqs'}->[$level]->next;
    $k--;
    if ($level >= $#$targets) {
      my $seq = Math::NumSeq::Primes->new;
      push @{$self->{'seqs'}}, $seq;
      (undef, $targets->[$level+1]) = $seq->next;
    }
    $level++;

    ### $k
    ### $level

    if ($k < $targets->[$level]) {
      return ($i, $level);
    }
  }
}

sub pred {
  my ($self, $value) = @_;
  return ($value == int($value)
          && $value >= 0);
}

1;
__END__

=for stopwords Ryde Math-NumSeq primeness

=head1 NAME

Math::NumSeq::PrimeIndexOrder -- order of primeness by primes at prime indexes

=head1 SYNOPSIS

 use Math::NumSeq::PrimeIndexOrder;
 my $seq = Math::NumSeq::PrimeIndexOrder->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the order of primeness by Neil Fernandez, counting levels of prime
at prime index iterations,

=over

L<http://www.borve.org/primeness/FOP.html>

=back

    i     = 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17

    value = 0, 1, 2, 0, 3, 0, 1, 0, 0, 0, 4, 0, 1, 0, 0, 0, 2, ...

Any composite has order 0.  The order for a prime is based on whether its
index in the list of all primes 2,3,5,7,11,etc is a prime and how many times
that prime index descent can be repeated.

For example i=17 is a prime and is at index 7 in the list of all primes.
That index 7 is a prime too and is at index 4.  Then stop there since 4 is
not a prime.  Two iterations to reach a non-prime means i=17 has value 2 as
its order of primeness.

=head2 Primes Only

Option C<on_values =E<gt> 'primes'> selects the orders of just the primes
2,3,5,7,etc.  The effect is to eliminate the 0s from the sequence.

    1, 2, 3, 1, 4, 1, 2, 1, 1, 1, 5, 1, 2, 1, 1, 1, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PrimeIndexOrder-E<gt>new (level =E<gt> $n)>

Create and return a new sequence object.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Primes>,
L<Math::NumSeq::PrimeIndexPrimes>,
L<Math::NumSeq::ErdosSelfridgeClass>

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

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



# Maybe: using_values => 'primes'
#
# http://mathworld.wolfram.com/SilvermansSequence.html
#
# Y.-F. S. Petermann, J.-L. Remy and I. Vardi, Discrete derivatives of
# sequences, Adv. in Appl. Math. 27 (2001), 562-84.
#   http://www.lix.polytechnique.fr/Labo/Ilan.Vardi/publications.html
#   http://www.lix.polytechnique.fr/Labo/Ilan.Vardi/discrete_derivatives.ps
#
# cf A112377 self seq sub1 drop 0s    1, 2, 1, 1, 3, 1, 2
#    A112378 self seq add1 drop 0s
#    A112379 self seq sub1 drop 0s    1, 2, 1, 3,
#    A112380 self seq sub1 drop 0s    1, 2, 1, 1, 3, 2, 1


package Math::NumSeq::GolombSequence;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 73;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Golomb Sequence');
use constant description => Math::NumSeq::__('Golomb sequence 1,2,2,3,3,4,4,4,etc, its own run lengths.');
use constant i_start => 1;
use constant values_min => 1;
use constant characteristic_smaller => 1;
use constant characteristic_non_decreasing => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [
   { name    => 'using_values',
     display => Math::NumSeq::__('Using Values'),
     type    => 'enum',
     default => 'all',
     choices => ['all','odd','even','3k','squares','primes'],
     choices_display => [Math::NumSeq::__('All'),
                         Math::NumSeq::__('Odd'),
                         Math::NumSeq::__('Even'),
                         # TRANSLATORS: "3k" meaning triples 3,6,9,12,15, probably no need to translate except into another script if Latin letter "k" won't be recognised
                         Math::NumSeq::__('3k'),
                         Math::NumSeq::__('Squares'),
                         Math::NumSeq::__('Primes'),
                        ],
     description => Math::NumSeq::__('Which values to use in the sequence.  Default "all" means all integers.'),
   },
  ];

#------------------------------------------------------------------------------

# cf A001463 golomb seq partial sums
#    A088517 golomb first diffs, is 0/1 characteristic of partial sums
#    A163563 a(n)+1 reps
#    A113722 a(n) reps of 2n+1
#    A113724 a(n) reps of 2n+2 evens
#    A103320 condensed 1,22,33,444,555,6666 etc
#    A104236 n*golomb(n)
#    A143125 n*golomb(n) cumulative
#    A095773 generalizing
#    A116548 divisors occurring fewer than a(n) times
#    A072649 n occurs Fibonacci(n) times
#    A108229 n occurs Lucas(n) times
#    A109167 n appears a(n) times
#
my %oeis_anum = (all   => 'A001462',
                 # OEIS-Catalogue: A001462

                 odd => 'A080605',
                 # OEIS-Catalogue: A080605 using_values=odd

                 even => 'A080606',
                 # OEIS-Catalogue: A080606 using_values=even

                 '3k' => 'A080607',
                 # OEIS-Catalogue: A080607 using_values=3k

                 'squares' => 'A013189',
                 # OEIS-Catalogue: A013189 using_values=squares

                 'primes' => 'A169682',
                 # OEIS-Catalogue: A169682 using_values=primes
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'using_values'}};
}

#------------------------------------------------------------------------------
#
# count[0] is how many of value[0] still to be returned
# when count[0]==0 must increment value[0] and new count from k=1


sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;

  my $using_values = $self->{'using_values'};
  $self->{'upto_func'} = $self->can("_upto_$using_values")
    || croak "Unrecognised using_values \"$using_values\"";

  # ENHANCE-ME: a hash table for these initializations, but would have to
  # clone the arrays
  if ($using_values eq 'all') {
    $self->{'small'} = [ 1, 2, 2 ];
    $self->{'counts'} = [ 2 ];
    $self->{'values'} = [ 3 ];
    $self->{'upto'}   = [ 3 ];
    $self->{'extend_count'} = 2;
    $self->{'extend_value'} = 3;
    $self->{'extend_upto'}  = 3;

  } elsif ($using_values eq 'odd') {
    $self->{'counts'} = [ 1, 3 ];
    $self->{'upto'}   = [ 1, 2 ];
    $self->{'values'} = [ 1, 3 ];
    $self->{'extend_count'} = 2;
    $self->{'extend_value'} = 3;
    $self->{'extend_upto'}  = 2;

  } elsif ($using_values eq 'even') {
    $self->{'counts'} = [ 2 ];
    $self->{'values'} = [ 4 ];
    $self->{'upto'}   = [ 2 ];
    $self->{'small'} = [ 2, 2 ];
    $self->{'extend_count'} = 2;
    $self->{'extend_value'} = 4;
    $self->{'extend_upto'}  = 2;

  } elsif ($using_values eq '3k') {
    $self->{'counts'} = [ 3 ];
    $self->{'values'} = [ 3 ];
    $self->{'upto'}   = [ 1 ];
    $self->{'extend_count'} = 2;
    $self->{'extend_value'} = 3;
    $self->{'extend_upto'}  = 1;

  } elsif ($using_values eq 'squares') {
    $self->{'counts'} = [ 1, 4 ];
    $self->{'values'} = [ 1, 4 ];
    $self->{'upto'}   = [ 1, 2 ];
    $self->{'extend_count'} = 3;
    $self->{'extend_value'} = 4;
    $self->{'extend_upto'}  = 2;

  } elsif ($using_values eq 'primes') {
    $self->{'small'} = [ 2, 2 ];
    $self->{'counts'} = [ 2 ];
    $self->{'values'} = [ 3 ];
    $self->{'upto'}   = [ 2 ];
    $self->{'extend_count'} = 2;
    $self->{'extend_value'} = 3;
    $self->{'extend_upto'}  = 2;
    $self->{'primes'} = [ 2, 3, 5 ];

  } else {
    croak "Unrecognised using_values: ",$using_values;
  }
}

sub _upto_all {
  my ($self, $upto) = @_;
  return $upto;
}
sub _upto_odd {
  my ($self, $upto) = @_;
  return 2*$upto-1;
}
sub _upto_even {
  my ($self, $upto) = @_;
  return 2*$upto;
}
sub _upto_3k {
  my ($self, $upto) = @_;
  return 3*$upto;
}
sub _upto_squares {
  my ($self, $upto) = @_;
  return $upto*$upto;
}
sub _upto_primes {
  my ($self, $upto) = @_;
  $upto--;
  my $primes = $self->{'primes'};
  if ($upto > $#$primes) {
    require Math::NumSeq::Primes;
    @$primes = Math::NumSeq::Primes::_primes_list (2, 2 * $primes->[-1]);
  }
  return $primes->[$upto];
}

sub next {
  my ($self) = @_;
  ### GolombSequence next(): "i=$self->{'i'}"
  ### counts: join(',',@{$self->{'counts'}})
  ### values: join(',',@{$self->{'values'}})

  if (defined (my $value = shift @{$self->{'small'}})) {
    return ($self->{'i'}++, $value);
  }

  my $values = $self->{'values'};
  my $upto = $self->{'upto'};
  my $ret = $values->[0];

  my $counts = $self->{'counts'};
  for (my $pos = 0; --$counts->[$pos] <= 0; $pos++) {
    if ($pos >= $#$counts) {
      ### extend ...
      push @$counts, $self->{'extend_count'};
      push @$upto,   $self->{'extend_upto'};
      push @$values, $self->{'extend_value'};
    }
    $upto->[$pos]++;
    my $upto_func = $self->{'upto_func'};
    $values->[$pos] = $self->$upto_func($upto->[$pos]);
    $counts->[$pos] = $values->[$pos+1];
  }
  return ($self->{'i'}++, $ret);
}

1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::GolombSequence -- sequence is its own run lengths, 1 upwards

=head1 SYNOPSIS

 use Math::NumSeq::GolombSequence;
 my $seq = Math::NumSeq::GolombSequence->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

A sequence of integers with each run length being given by the sequence
itself.

    1, 2,2, 3,3, 4,4,4, 5,5,5, 6,6,6,6,...

Starting from 1,2, at i=2 the value is 2, so there should be a run of two
2s.  Then at i=3 value 2 means two 3s.  Then at i=4 value 3 means a run of
three 4s, and so on.

    Values     Run Length (is the sequence itself)
    1,            1
    2,2,          2
    3,3,          2
    4,4,4,        3
    5,5,5,        3
    6,6,6,6,      4
    ...          ...

=head2 Using Values

The default is to use all integers successively for the values.  The
C<using_values> option can choose a different set of values.  In each case
those values from the sequence are the run lengths.

C<using_values =E<gt> 'odd'> uses only odd numbers,

    1, 3,3,3, 5,5,5, 7,7,7, 9,9,9,9,9, ...

C<using_values =E<gt> 'even'> uses only even numbers,

    2,2, 4,4, 6,6,6,6, 8,8,8,8, ...

C<using_values =E<gt> '3k'> uses only triples,

    3,3,3, 6,6,6, 9,9,9, 12,12,12,12,12,12, ...

C<using_values =E<gt> 'squares'> uses the squares,

    1, 4,4,4,4, 9,9,9,9, 16,16,16,16, 25,25,25,25, ...

C<using_values =E<gt> 'primes'> uses the primes,

    2,2, 3,3, 5,5,5, 7,7,7, 11,11,11,11,11, ...

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::GolombSequence-E<gt>new ()>

=item C<$seq = Math::NumSeq::GolombSequence-E<gt>new (using_values =E<gt> $str)>

Create and return a new sequence object.  The C<using_values> option as
described above can be

    "all"
    "odd"
    "even"
    "3k"
    "squares"
    "primes"

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Kolakoski>

L<Math::NumSeq::Odd>,
L<Math::NumSeq::Even>,
L<Math::NumSeq::Squares>,
L<Math::NumSeq::Primes>

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
